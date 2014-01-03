class Encounter < ActiveRecord::Base
  set_table_name :encounter
  set_primary_key :encounter_id
  include Openmrs
  
  has_one :program_encounter, :foreign_key => :encounter_id, :conditions => {:voided => 0}
  has_many :observations, :dependent => :destroy, :conditions => {:voided => 0}
  has_many :drug_orders,  :through   => :orders,  :foreign_key => 'order_id'
  has_many :orders, :dependent => :destroy, :conditions => {:voided => 0}
  belongs_to :type, :class_name => "EncounterType", :foreign_key => :encounter_type, :conditions => {:retired => 0}
  # belongs_to :provider, :class_name => "User", :foreign_key => :provider_id, :conditions => {:voided => 0}
  belongs_to :patient, :conditions => {:voided => 0}

  # TODO, this needs to account for current visit, which needs to account for possible retrospective entry
  named_scope :current, :conditions => 'DATE(encounter.encounter_datetime) = CURRENT_DATE()'

  def before_save
    # self.provider = User.current if self.provider.blank?
    # TODO, this needs to account for current visit, which needs to account for possible retrospective entry
    self.encounter_datetime = Time.now if self.encounter_datetime.blank?
  end

  def after_save
    # self.add_location_obs
  end

  def after_void(reason = nil)
    self.observations.each do |row| 
      if not row.order_id.blank?
        ActiveRecord::Base.connection.execute <<EOF
UPDATE drug_order SET quantity = NULL WHERE order_id = #{row.order_id};
EOF
      end rescue nil
      row.void(reason) 
    end rescue []

    self.orders.each do |order|
      order.void(reason) 
    end
  end

  def name
    self.type.name rescue "N/A"
  end

  def encounter_type_name=(encounter_type_name)
    self.type = EncounterType.find_by_name(encounter_type_name)
    raise "#{encounter_type_name} not a valid encounter_type" if self.type.nil?
  end

  def to_s
    if name == 'REGISTRATION'
      "Patient was seen at the registration desk at #{encounter_datetime.strftime('%I:%M')}" 
    elsif name == 'TREATMENT'
      o = orders.collect{|order| order.drug_order}.join(", ")
      # o = "TREATMENT NOT DONE" if self.patient.treatment_not_done
      o = "No prescriptions have been made" if o.blank?
      o
    elsif name == 'DISPENSING'
      o = orders.collect{|order| order.drug_order}.join(", ")
      # o = "TREATMENT NOT DONE" if self.patient.treatment_not_done
      o = "No TTV vaccine given" if o.blank?
      o
    elsif name == 'VITALS'
      temp = observations.select {|obs| obs.concept.concept_names.map(&:name).collect{|n| n.upcase}.include?("TEMPERATURE (C)") && "#{obs.answer_string}".upcase != 'UNKNOWN' }
      weight = observations.select {|obs| obs.concept.concept_names.map(&:name).collect{|n| n.upcase}.include?("WEIGHT (KG)") && "#{obs.answer_string}".upcase != '0.0' }
      height = observations.select {|obs| obs.concept.concept_names.map(&:name).collect{|n| n.upcase}.include?("HEIGHT (CM)") && "#{obs.answer_string}".upcase != '0.0' }
      systo = observations.select {|obs| obs.concept.concept_names.map(&:name).collect{|n| n.upcase}.include?("SYSTOLIC BLOOD PRESSURE") && "#{obs.answer_string}".upcase != '0.0' }
      diasto = observations.select {|obs| obs.concept.concept_names.map(&:name).collect{|n| n.upcase}.include?("DIASTOLIC BLOOD PRESSURE") && "#{obs.answer_string}".upcase != '0.0' }
      vitals = [weight_str = weight.first.answer_string + 'KG' rescue 'UNKNOWN WEIGHT',
        height_str = height.first.answer_string + 'CM' rescue 'UNKNOWN HEIGHT', bp_str = "BP: " + 
          (systo.first.answer_string.to_i.to_s rescue "?") + "/" + (diasto.first.answer_string.to_i.to_s rescue "?")]
      temp_str = temp.first.answer_string + '°C' rescue nil
      vitals << temp_str if temp_str                          
      vitals.join(', ')
    elsif name == 'DIAGNOSIS'
      diagnosis_array = []
      observations.each{|observation|
        next if observation.obs_group_id != nil
        observation_string =  observation.answer_string
        child_ob = observation.child_observation
        while child_ob != nil
          observation_string += " #{child_ob.answer_string}"
          child_ob = child_ob.child_observation
        end
        diagnosis_array << observation_string
        diagnosis_array << " : "
      }
      diagnosis_array.compact.to_s.gsub(/ : $/, "")    
    elsif name == 'OBSERVATIONS' || name == 'CURRENT PREGNANCY'
      observations.collect{|observation| observation.to_s.titleize.gsub("Breech Delivery", "Breech")}.join(", ")   
    elsif name == 'SURGICAL HISTORY'
      observations.collect{|observation| observation.to_s.titleize.gsub("Tuberculosis Test Date Received", "Date")}.join(", ")
    elsif name == "ANC VISIT TYPE"
      observations.collect{|o| "Visit No.: " + o.value_numeric.to_i.to_s}.join(", ")
    else  
      observations.collect{|observation| observation.to_s.titleize}.join(", ")
    end  
  end

  def self.statistics(encounter_types, opts={})

    encounter_types = EncounterType.all(:conditions => ['name IN (?)', encounter_types])
    encounter_types_hash = encounter_types.inject({}) {|result, row| result[row.encounter_type_id] = row.name; result }
    with_scope(:find => opts) do
      rows = self.all(
        :select => 'count(*) as number, encounter_type',
        :group => 'encounter.encounter_type',
        :conditions => ['encounter_type IN (?)', encounter_types.map(&:encounter_type_id)])
      return rows.inject({}) {|result, row| result[encounter_types_hash[row['encounter_type']]] = row['number']; result }
    end
  end

  def self.encounter_patients(types, start_date = Date.today, end_date = Date.today)

    encounter_types = EncounterType.all(:conditions => ['name IN (?)', types]).map(&:encounter_type_id)
    return [] if encounter_types.blank?
    
    Encounter.all(:conditions => ["encounter_type IN (?) AND DATE(encounter_datetime) BETWEEN (?) AND (?)",
        encounter_types, start_date.to_date, end_date.to_date]).map(&:patient_id)

  end

  def self.encounter_patients_by_birthdate(types, start_date = Date.today, end_date = Date.today)

    encounter_types = EncounterType.all(:conditions => ['name IN (?)', types]).map(&:encounter_type_id)
    return [] if encounter_types.blank?

    Encounter.all(:joins => ["INNER JOIN person ON person.birthdate IS NOT NULL AND person.voided = 0 AND encounter.patient_id = person.person_id"],
      :conditions => ["encounter_type IN (?) AND DATE(birthdate) BETWEEN (?) AND (?)",
        encounter_types, start_date.to_date, end_date.to_date]).map(&:patient_id)

  end

  def self.cohort_data(patients = [], start_date = Date.today, end_date = Date.today)
    
    data = {}

    #1. get outcomes for all patients in range
    types = ["EID VISIT"]
    
    encounter_types = EncounterType.all(:conditions => ['name IN (?)', types]).map(&:encounter_type_id)
    
    outcomes = {"presumed severe hiv disease" => [],
      "hiv infected" => [],
      "not hiv infected" => [],
      "not art eligible" => [],
      "unknown" => []
    }

    primary_outcome = {"defaulted" => [],
      "continue follow-up" => [],
      "art started" => [],
      "transferred out" => [],
      "discharged uninfected" => [],
      "died" => []
    }

    cpt = {"yes" => [],
      "no" => []
    }

    #probe for HIV outcomes of infants

    concept_names = ConceptName.all(:conditions => ['name IN (?)', ["CONFIRMED", "NOT CONFIRMED"]]).map(&:concept_id)
    outcome_Q = "(SELECT c.name FROM concept_name c WHERE c.concept_name_id = o.value_coded_name_id)"

    Encounter.find_by_sql(["SELECT #{outcome_Q} AS outcome, enc.patient_id FROM encounter enc
                INNER JOIN obs o ON o.encounter_id = enc.encounter_id AND o.concept_id IN (?)
                WHERE enc.encounter_type IN (?) AND DATE(encounter_datetime) BETWEEN (?) AND (?)
                AND enc.patient_id IN (?) ORDER BY encounter_datetime DESC",
        concept_names, encounter_types, start_date.to_date, end_date.to_date, patients]).each do |obj|

      category = obj.outcome.downcase.strip
      pid = obj.patient_id
      
      next if outcomes.values.flatten.include?(pid)
      
      unless outcomes.has_key?(category)
        outcomes[category] = [pid]
      else         
        outcomes[category] << [pid]
      end
          
    end

    outcomes["unknown"] = patients - outcomes.values.flatten.uniq

    #probe for primary outcomes
    concept_names = ConceptName.all(:conditions => ['name IN (?)', ["OUTCOME"]]).map(&:concept_id)

    Encounter.find_by_sql(["SELECT #{outcome_Q} AS outcome, enc.patient_id FROM encounter enc
                INNER JOIN obs o ON o.encounter_id = enc.encounter_id AND o.concept_id IN (?)
                WHERE enc.encounter_type IN (?) AND DATE(encounter_datetime) BETWEEN (?) AND (?)
                AND enc.patient_id IN (?) ORDER BY encounter_datetime DESC",
        concept_names, encounter_types, start_date.to_date, end_date.to_date, patients]).each do |obj|

      category = obj.outcome.downcase.strip
      pid = obj.patient_id

      next if primary_outcome.values.flatten.include?(pid)

      unless primary_outcome.has_key?(category)
        primary_outcome[category] = [pid]
      else
        primary_outcome[category] << [pid]
      end

    end
    primary_outcome["unknown"] = patients - primary_outcome.values.flatten.uniq
     
    cpt["yes"] = Encounter.cpt_patients_filter(patients, start_date, end_date)
    cpt["no"] = patients - cpt["yes"]

    data["hiv_outcome"] = outcomes
    data["primary_outcome"] = primary_outcome
    data["cpt_outcome"] = cpt


    data
    
  end

  def self.cpt_patients_filter(patients = [], start_date = Date.today, end_date = Date.today)
    
    result = Order.find(:all, :joins => [[:drug_order => :drug], :encounter],
      :select => ["encounter.patient_id"],
      :group => [:patient_id],
      :conditions => ["drug.name REGEXP 'COTRIMOXAZOLE' AND DATE(encounter_datetime) BETWEEN (?) AND (?)" +
          " AND encounter.patient_id IN (?) AND orders.voided = 0 AND encounter.voided = 0",
        start_date.to_date, end_date.to_date, patients]).map(&:patient_id)
    
    result    
  end
  
  
end
