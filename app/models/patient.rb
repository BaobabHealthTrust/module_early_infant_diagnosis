class Patient < ActiveRecord::Base
  set_table_name "patient"
  set_primary_key "patient_id"
  include Openmrs

  has_one :person, :foreign_key => :person_id, :conditions => {:voided => 0}
  has_many :patient_identifiers, :foreign_key => :patient_id, :dependent => :destroy, :conditions => {:voided => 0}
  has_many :patient_programs, :conditions => {:voided => 0}
  has_many :programs, :through => :patient_programs
  has_many :relationships, :foreign_key => :person_a, :dependent => :destroy, :conditions => {:voided => 0}
  has_many :orders, :conditions => {:voided => 0}

  has_many :program_encounters, :class_name => 'ProgramEncounter',
    :foreign_key => :patient_id, :dependent => :destroy
  
  has_many :encounters, :conditions => {:voided => 0} do 
    def find_by_date(encounter_date)
      encounter_date = Date.today unless encounter_date
      find(:all, :conditions => ["encounter_datetime BETWEEN ? AND ?", 
          encounter_date.to_date.strftime('%Y-%m-%d 00:00:00'),
          encounter_date.to_date.strftime('%Y-%m-%d 23:59:59')
        ]) # Use the SQL DATE function to compare just the date part
    end
  end

  def after_void(reason = nil)
    self.person.void(reason) rescue nil
    self.patient_identifiers.each {|row| row.void(reason) }
    self.patient_programs.each {|row| row.void(reason) }
    self.orders.each {|row| row.void(reason) }
    self.encounters.each {|row| row.void(reason) }
  end

  def name
    "#{self.person.names.first.given_name} #{self.person.names.first.family_name}"
  end
  
  def national_id
    self.patient_identifiers.find_by_identifier_type(PatientIdentifierType.find_by_name("National id").id).identifier rescue nil
  end

  def address
    "#{self.person.addresses.first.city_village}" rescue nil
  end

  def age(today = Date.today)
    return nil if self.person.birthdate.nil?

    # This code which better accounts for leap years
    patient_age = (today.year - self.person.birthdate.year) + ((today.month -
          self.person.birthdate.month) + ((today.day - self.person.birthdate.day) < 0 ? -1 : 0) < 0 ? -1 : 0)

    # If the birthdate was estimated this year, we round up the age, that way if
    # it is March and the patient says they are 25, they stay 25 (not become 24)
    birth_date=self.person.birthdate
    estimate=self.person.birthdate_estimated==1
    patient_age += (estimate && birth_date.month == 7 && birth_date.day == 1  &&
        today.month < birth_date.month && self.person.date_created.year == today.year) ? 1 : 0
  end

  def gender
    self.person.gender rescue nil
  end

  def age_in_months(today = Date.today)
    years = (today.year - self.person.birthdate.year)
    months = (today.month - self.person.birthdate.month)
    (years * 12) + months
  end

  def allergic_to_sulphur
    status = self.encounters.collect { |e|
      e.observations.find(:last, :conditions => ["concept_id = ?",
          ConceptName.find_by_name("Allergic to sulphur").concept_id]).answer_string rescue nil
    }.compact.flatten.first

    status = "unknown" if status.blank?
    status
  end

  def dpt1
    status = self.encounters.collect { |e|
      e.observations.find(:last, :conditions => ["concept_id = ?",
          ConceptName.find_by_name("Was DPT-HepB-Hib 1 vaccine given at 6 weeks or later?").concept_id]).answer_string rescue nil
    }.compact.flatten.first

    status = "unknown" if status.blank?
    status
  end

  def dpt2
    status = self.encounters.collect { |e|
      e.observations.find(:last, :conditions => ["concept_id = ?",
          ConceptName.find_by_name("Was DPT-HepB-Hib 2 vaccine given at 1 month after first dose?").concept_id]).answer_string rescue nil
    }.compact.flatten.first

    status = "unknown" if status.blank?
    status
  end

  def dpt3
    status = self.encounters.collect { |e|
      e.observations.find(:last, :conditions => ["concept_id = ?",
          ConceptName.find_by_name("Was DPT-HepB-Hib 3 vaccine given at 1 month after second dose?").concept_id]).answer_string rescue nil
    }.compact.flatten.first

    status = "unknown" if status.blank?
    status
  end

  def pcv1
    status = self.encounters.collect { |e|
      e.observations.find(:last, :conditions => ["concept_id = ?",
          ConceptName.find_by_name("PCV 1 vaccine given at 6 weeks or later?").concept_id]).answer_string rescue nil
    }.compact.flatten.first

    status = "unknown" if status.blank?
    status
  end

  def pcv2
    status = self.encounters.collect { |e|
      e.observations.find(:last, :conditions => ["concept_id = ?",
          ConceptName.find_by_name("PCV 2 vaccine given at 1 month after first dose?").concept_id]).answer_string rescue nil
    }.compact.flatten.first

    status = "unknown" if status.blank?
    status
  end

  def pcv3
    status = self.encounters.collect { |e|
      e.observations.find(:last, :conditions => ["concept_id = ?",
          ConceptName.find_by_name("PCV 3 vaccine given at 1 month after second dose?").concept_id]).answer_string rescue nil
    }.compact.flatten.first

    status = "unknown" if status.blank?
  end

  def polio0
    status = self.encounters.collect { |e|
      e.observations.find(:last, :conditions => ["concept_id = ?",
          ConceptName.find_by_name("First polio vaccine at birth").concept_id]).answer_string rescue nil
    }.compact.flatten.first

    status = "unknown" if status.blank?
    status
  end

  def polio1
    status = self.encounters.collect { |e|
      e.observations.find(:last, :conditions => ["concept_id = ?",
          ConceptName.find_by_name("Second polio vaccine at 1.5 months").concept_id]).answer_string rescue nil
    }.compact.flatten.first

    status = "unknown" if status.blank?
    status
  end

  def polio2
    status = self.encounters.collect { |e|
      e.observations.find(:last, :conditions => ["concept_id = ?",
          ConceptName.find_by_name("Third polio vaccine at 2.5 months").concept_id]).answer_string rescue nil
    }.compact.flatten.first

    status = "unknown" if status.blank?
    status
  end

  def polio3
    status = self.encounters.collect { |e|
      e.observations.find(:last, :conditions => ["concept_id = ?",
          ConceptName.find_by_name("Fourth polio vaccine at 3.5 months").concept_id]).answer_string rescue nil
    }.compact.flatten.first

    status = "unknown" if status.blank?
    status
  end

  def mastercard(encounta)
    result = {}
    @enrolment_encounters = Encounter.find(:all, :select => ["encounter_id"], :conditions => ["encounter_type = ? and patient_id = ?",
        EncounterType.find_by_name(encounta).id, self.patient_id]).collect{|enc| enc.encounter_id rescue nil} rescue []
    return {} if  @enrolment_encounters.blank?
   
    @program_encounter_details =  ProgramEncounterDetail.find(:all, :joins => [:program_encounter],
      :conditions => ["program_encounter.program_id = ? AND program_encounter.patient_id = ? AND encounter_id IN (?)",
        Program.find_by_name("EARLY INFANT DIAGNOSIS PROGRAM").program_id, self.patient_id, @enrolment_encounters])
  
    (@program_encounter_details || []).each do |ped|

      date = ped.encounter.encounter_datetime rescue nil
      next if date.blank?
      
      obs = {}
      ped.encounter.observations.collect{|ob|
        name =  ConceptName.find_by_concept_id(ob.concept_id).name rescue nil
        next if name.blank?
        ans = ob.answer_string.strip rescue nil
        ans = "Negative" rescue nil if ((ob.answer_string.strip.present? && ob.answer_string.strip == "-") rescue false)
        next if ans.blank?
        obs[name.upcase] = ans
      }
      result[date]  = obs

    end

    return rapid_test(result) if encounta.upcase == "RAPID ANTIBODY TEST"
    return dna_test(result) if encounta.upcase == "DNA-PCR TEST"
    return numerize(result) if encounta.upcase == "EID VISIT"
    return result if encounta.upcase == "NOTES"

    #sort hash for best answers
    map_hash = {}
    last_date = ""
    result.keys.each{|date|
      result[date].keys.each{|concept|
        
        if last_date.blank?
          map_hash[concept.upcase] = result[date][concept.upcase]
        else
          #choose best answer for question; add as many checks as possible for this one; defaults to latest captured value i.e in if statmt
          if (date.to_time > last_date.to_time)
            map_hash[concept.upcase] = result[date][concept.upcase]
          end
        end
      }
      last_date = date
    }
    map_hash
  end

  def rapid_test(tests)
    result = {}
   
    #initializing a target maximum of three tests
    (1 .. 3).each{ |num|  result[num] = {} }

    (tests.keys.sort rescue []).each do |date|
      test_date = tests[date]["RAPID ANTIBODY TESTING SAMPLE DATE"].to_date rescue nil
      test_age = self.age_in_months(test_date) rescue nil      
      next if (test_age.blank? || test_age.class.to_s.upcase != "FIXNUM" || test_age < 0) rescue true
      
      field = test_age < 12 ? 1 : ((test_age >= 12 && test_age < 24)? 2 : 3)     
      next if field.blank?

      if result[field].blank? || (test_date > result[field]["RAPID ANTIBODY TESTING SAMPLE DATE"].to_date rescue true)
        tests[date].keys.each{|ky|
          result[field][ky] = tests[date][ky]
          result[field]["RAPID ANTIBODY TESTING SAMPLE AGE"] = self.age_in_months((result[field]["RAPID ANTIBODY TESTING SAMPLE DATE"].to_date rescue Date.today))
        }
      end
      
      field = nil
    end
    
    result
  end

  def dna_test(tests)

    result = {}
    #reorder tests inorder of sample date
    (tests.keys.sort rescue []).each{|d|
      sample_date = tests[d]["DNA-PCR TESTING SAMPLE DATE"].to_time rescue nil
      unless sample_date.blank?
        tests[sample_date] = tests[d]
        tests.delete(d)
      end 
    }
    
    (tests.keys.sort rescue []).each do |date|

      test_date = tests[date]["DNA-PCR TESTING SAMPLE DATE"].to_time rescue nil    
      next if (test_date.blank? || test_date.class.to_s.upcase != "TIME" || (test_date < self.person.birthdate.to_time rescue false)) rescue true
      
      field = result.keys.sort.last.to_i + 1      
      next if field.blank?
      
      result[field] = {} unless (result[field].present? rescue false)      
      
      if result[field].blank? || (test_date > result[field]["DNA-PCR TESTING SAMPLE DATE"].to_time rescue true)
        tests[date].keys.each{|ky|
          result[field][ky] = tests[date][ky]         
        }
        result[field]["DNA-PCR TESTING RESULT GIVEN AGE"] = self.age_in_months((tests[date]["DNA-PCR TESTING RESULT GIVEN DATE"].to_date rescue Date.today))
      end

      field = nil
    end

    result
  end

  def numerize(data)

    result = {}
    (data.keys.sort rescue []).each{|date|

      key = result.keys.sort.last.to_i + 1
      result[key] = {} unless (result[key].present? rescue false)
     
      data[date].keys.each{|ky|
        result[key][ky] = data[date][ky]
      }
      key = nil
    }
    result
  end

  def mastercard_details(encountaz = [])
    result = {}
    encountaz.each do |encounta|
      result[encounta.upcase] = self.mastercard(encounta.upcase)
    end
    result
  end
  
  def birthweight
    Observation.find(:first, :order => ["obs_datetime DESC"],
      :conditions => ["person_id = ? AND concept_id =  ?", self.patient_id, ConceptName.find_by_name("BIRTH WEIGHT").concept_id]).answer_string.strip rescue nil
  end
  
  def guardian
    guardian_type = RelationshipType.find_by_a_is_to_b_and_b_is_to_a("Patient", "Guardian").relationship_type_id rescue nil
    return "" if guardian_type.blank?
    person_id = Relationship.find(:first,:order => "date_created DESC",
      :conditions =>["person_b = ? and relationship = ?", self.patient_id, guardian_type]).person_a rescue nil
    guardian_name = Patient.find(person_id).name rescue ""
    guardian_name
  end

  def transfer_in_date    
    self.program_encounters.find(:first, 
      :select => ["date_time"],
      :order => ["date_time ASC"],
      :conditions => ["patient_id = ? AND program_id = ?",
        self.patient_id, Program.find_by_name("EARLY INFANT DIAGNOSIS PROGRAM").id]
    ).date_time.strftime("%d/%b/%Y") rescue nil
  end

  def mother
    type = RelationshipType.find_by_a_is_to_b_and_b_is_to_a("Parent", "Child").relationship_type_id rescue nil
    return "" if type.blank?
    person_id = Relationship.find(:first,:order => "date_created DESC",
      :conditions =>["person_b = ? and relationship = ?", self.patient_id, type]).person_a rescue nil
    p = Patient.find(person_id) rescue nil
    p
  end

  def agreesFP
    encs= self.encounters.find(:all, :conditions => ["encounter_type = ?",  EncounterType.find_by_name("EID VISIT").id],
      :order => ["encounter_datetime DESC"]).collect{|enc| enc.encounter_id} rescue []
    @agrees = "N"

    ProgramEncounterDetail.find(:all, :joins => [:program_encounter],
      :conditions => ["program_encounter.program_id = ? AND program_encounter.patient_id = ? AND encounter_id IN (?)",
        Program.find_by_name("EARLY INFANT DIAGNOSIS PROGRAM").program_id, 
        self.patient_id, encs]).collect{|enc| enc.encounter}.each{ |encounta|
      
      if encounta.observations.collect{|ob| ob.answer_string.upcase.strip}.include?("CONTINUE FOLLOW-UP")
        @agrees = "Y"
      end
    } 
    @agrees
  end

end
