
class PatientsController < ApplicationController
  unloadable  

  before_filter :sync_user, :except => [:index, :user_login, :user_logout, 
    :set_datetime, :update_datetime, :reset_datetime, :mastercard_printable]

  def show
    
    @patient = Patient.find(params[:id] || params[:patient_id]) rescue nil

    if @patient.blank?
      redirect_to "/encounters/no_patient" and return
    end

    if params[:user_id].blank?
      redirect_to "/encounters/no_user" and return
    end

    @user = User.find(params[:user_id] || session[:user_id]) rescue nil
    
    redirect_to "/encounters/no_user" and return if @user.blank?
    
    @guardian = @patient.recent_guardian(session[:datetime] || Date.today) rescue nil
    
    redirect_to "/patients/guardians?patient_id=#{@patient.id}" and return if @guardian.blank?
    
    redirect_to "/patients/birth_weight?user_id=#{params['user_id']}&patient_id=#{@patient.id}" and return if (@patient.birthweight.blank? rescue false)
    
    @task = TaskFlow.new(params[:user_id], @patient.id)

    @links = {}

    if File.exists?("#{Rails.root}/config/protocol_task_flow.yml")
      map = YAML.load_file("#{Rails.root}/config/protocol_task_flow.yml")["#{Rails.env
        }"]["label.encounter.map"].split(",") rescue []
    end

    @label_encounter_map = {}

    map.each{ |tie|
      label = tie.split("|")[0]
      encounter = tie.split("|")[1] rescue nil

      @label_encounter_map[label] = encounter if !label.blank? && !encounter.blank?

    }

    @task_status_map = {}

    @task.tasks.each{|task|

      next if task.downcase == "update baby outcome" and (@patient.current_babies.length == 0 rescue false)
      next if !@task.current_user_activities.include?(task)

      #check if task has already been done depending on scopes
      scope = @task.task_scopes[task][:scope].upcase rescue nil
      scope = "TODAY" if scope.blank?
      encounter_name = @label_encounter_map[task.upcase]rescue nil
      concept = @task.task_scopes[task][:concept].upcase rescue nil

      @task_status_map[task] = done(scope, encounter_name, concept)
       
      ctrller = "protocol_patients"
            
      if File.exists?("#{Rails.root}/config/protocol_task_flow.yml")
        
        ctrller = YAML.load_file("#{Rails.root}/config/protocol_task_flow.yml")["#{task.downcase.gsub(/\s/, "_")}"] rescue ""
          
      end
      
      @links[task.titleize] = "/#{ctrller}/#{task.gsub(/\s/, "_")}?patient_id=#{
      @patient.id}&user_id=#{params[:user_id]}" + (task.downcase == "update baby outcome" ?
          "&baby=1&baby_total=#{(@patient.current_babies.length rescue 0)}" : "")
    }

    @links["Give Drugs"] = "/encounters/give_drugs?patient_id=#{@patient.id}&user_id=#{@user.id}"
 
    @first_level_order = ["Enrollment Status", "Pmtct History", "Rapid Antibody Test", "Dna Pcr Test", "Eid Visit", "Notes", "Give Drugs"]

    @project = get_global_property_value("project.name") rescue "Unknown"

    @demographics_url = get_global_property_value("patient.registration.url") rescue nil

    if !@demographics_url.blank?
      @demographics_url = @demographics_url + "/demographics/#{@patient.id}?user_id=#{@user.id}&ext=true"
    end
    
    @demographics_url = "http://" + @demographics_url if (!@demographics_url.match(/http:/) rescue false)
    @task.next_task

    @babies = @patient.current_babies rescue []
    
  end

  def guardians

    @patient = Patient.find(params[:patient_id])
    relationship = RelationshipType.find_by_b_is_to_a("Guardian").id
      
    if params[:new_guardian].to_s == "true"

      @patient_registration = get_global_property_value("patient.registration.url") rescue ""

      redirect_to "#{@patient_registration}/search?user_id=#{@user_id}&ext=true&location_id=#{session[:location_id]}&patient_id=#{@patient.id}"

    else
    
      unless params[:ext_patient_id]      

        if params[:current_guardian].present?
          
          r = Relationship.find_by_person_a_and_person_b_and_relationship(@patient.id, params[:current_guardian], relationship)
          r.update_attributes(:date_created => DateTime.now)

          redirect_to "/patients/show/#{@patient.id}?patient_id=#{@patient.id}&user_id=#{session[:user_id]}&location_id=#{session[:location_id]}"
          
        end
        
        @guardians_map = @patient.guardians_map.uniq rescue []
             
        @previous_guardian = @guardians_map.first[0] rescue nil
      
        if @guardians_map.blank? and @mother.present?
          
          mother = @patient.mother.name + " (Mother)"        
          @guardian_map << [mother, @patient.mother.id]
          
        end

      else     
        
        Relationship.create(
          :person_a => params[:patient_id],
          :person_b => params[:ext_patient_id],
          :relationship => relationship)

        redirect_to "/patients/show?patient_id=#{@patient.id}&user_id=#{session[:user_id]}&location_id=#{session[:location_id]}"

      end
      
    end
  end
  
  def done(scope = "", encounter_name = "", concept = "")
    return "notdone" if encounter_name.downcase == "notes"
    scope = "" if concept.blank?
    available = []

    case scope
    when "TODAY"
      available = Encounter.find(:all, :joins => [:observations], :conditions =>
          ["patient_id = ? AND encounter_type = ? AND obs.concept_id = ? AND DATE(encounter_datetime) = ?",
          @task.patient.id, EncounterType.find_by_name(encounter_name).id , ConceptName.find_by_name(concept).concept_id, @task.current_date.to_date]) rescue []

    when "RECENT"
      available = Encounter.find(:all, :joins => [:observations], :conditions =>
          ["patient_id = ? AND encounter_type = ? AND obs.concept_id = ? " +
            "AND (DATE(encounter_datetime) >= ? AND DATE(encounter_datetime) <= ?)",
          @task.patient.id, EncounterType.find_by_name(encounter_name).id, ConceptName.find_by_name(concept).concept_id,
          (@task.current_date.to_date - 6.month), (@task.current_date.to_date + 6.month)]) rescue []

    when "EXISTS"
      available = Encounter.find(:all, :joins => [:observations], :conditions =>
          ["patient_id = ? AND encounter_type = ? AND obs.concept_id = ?",
          @task.patient.id, EncounterType.find_by_name(encounter_name).id, ConceptName.find_by_name(concept).concept_id]) rescue []

    when ""
      available = Encounter.find(:all, :conditions =>
          ["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
          @task.patient.id, EncounterType.find_by_name(encounter_name).id , @task.current_date.to_date]) rescue []
    end

    available = available.blank?? "notdone" : "done"
    available

  end

  def current_visit

    @patient = Patient.find(params[:id] || params[:patient_id]) rescue nil
    d = (session[:datetime].to_date rescue Date.today)
    t = Time.now
    session_date = DateTime.new(d.year, d.month, d.day, t.hour, t.min, t.sec)

    ProgramEncounter.current_date = session_date.to_date

    @programs = @patient.program_encounters.find(:all, :order => ["date_time DESC"],
      :conditions => ["DATE(date_time) = ?", session_date.to_date]).collect{|p|
      [
        p.id,
        p.to_s,
        p.program_encounter_types.collect{|e|
          next if e.encounter.blank?

          [
            e.encounter_id, e.encounter.type.name,
            e.encounter.encounter_datetime.strftime("%H:%M"),
            e.encounter.creator
          ]
        }.uniq,
        p.date_time.strftime("%d-%b-%Y")
      ]
    } if !@patient.blank?

    @programs.delete_if{|prg| prg[2].blank? || (prg[2].first.blank? rescue false)}
    render :layout => false
  end

  def visit_history
    @patient = Patient.find(params[:id] || params[:patient_id]) rescue nil

    @task = TaskFlow.new(params[:user_id], @patient.id)

    if File.exists?("#{Rails.root}/config/protocol_task_flow.yml")
      map = YAML.load_file("#{Rails.root}/config/protocol_task_flow.yml")["#{Rails.env
        }"]["label.encounter.map"].split(",") rescue []
    end

    @label_encounter_map = {}

    map.each{ |tie|
      label = tie.split("|")[0]
      encounter = tie.split("|")[1] rescue nil

      concept = @task.task_scopes[label.titleize.downcase.strip][:concept].upcase rescue ""
      key  = encounter + "|" + concept
      @label_encounter_map[key] = label if !label.blank? && !encounter.blank?
    }

    @programs = @patient.program_encounters.find(:all, :order => ["date_time DESC"]).collect{|p|

      [
        p.id,
        p.to_s,
        p.program_encounter_types.collect{|e|
          next if e.encounter.blank?
          labl = label(e.encounter_id, @label_encounter_map) || e.encounter.type.name
          [
            e.encounter_id, labl,
            e.encounter.encounter_datetime.strftime("%H:%M"),
            e.encounter.creator
          ] rescue []
        }.uniq,
        p.date_time.strftime("%d-%b-%Y")
      ]
    } if !@patient.blank?

    @programs.delete_if{|prg| prg[2].blank? || (prg[2].first.blank? rescue false)}
    render :layout => false
  end

  def label(encounter_id, hash)
    concepts = Encounter.find(encounter_id).observations.collect{|ob| ob.concept.name.name.downcase}
    lbl = ""
    hash.each{|val, label|
      lbl = label if (concepts.include?(val.split("|")[1].downcase) rescue false)}
    lbl
  end

  def demographics
    @patient = Patient.find(params[:id] || params[:patient_id]) rescue nil

    if @patient.blank?
      redirect_to "/encounters/no_patient" and return
    end

    if params[:user_id].blank?
      redirect_to "/encounters/no_user" and return
    end

    redirect_to "/encounters/no_user" and return if @user.blank?

  end

  def number_of_booked_patients
    date = params[:date].to_date
    encounter_type = EncounterType.find_by_name('Kangaroo review visit') rescue nil
    concept_id = ConceptName.find_by_name('APPOINTMENT DATE').concept_id

    count = Observation.count(:all,
      :joins => "INNER JOIN encounter e USING(encounter_id)",:group => "value_datetime",
      :conditions =>["concept_id = ? AND encounter_type = ? AND value_datetime >= ? AND value_datetime <= ?",
        concept_id,encounter_type.id,date.strftime('%Y-%m-%d 00:00:00'),date.strftime('%Y-%m-%d 23:59:59')]) rescue nil

    count = count.values unless count.blank?
    count = '0' if count.blank?

    render :text => (count.first.to_i > 0 ? {params[:date] => count}.to_json : 0)
  end

  def mastercard
  
    @quarter = params[:quarter]
    @arv_start_number = params[:arv_start_number]
    @arv_end_number = params[:arv_end_number]

    @patient = Patient.find(params[:patient_id])
    return if @patient.blank?
    
    render :layout => false

  end

  def phone_numbers(patient)
   
    @phone_numbers = ((patient.person.cell_phone_number.blank?? "" : patient.person.cell_phone_number + "</br>") +
        (patient.person.home_phone_number.blank?? "" : patient.person.home_phone_number + "</br>" ) +
        (patient.person.office_phone_number.blank?? "" : patient.person.office_phone_number)) rescue ""
    @phone_numbers = "None" if @phone_numbers.blank?
    @phone_numbers
  end

  def mastercard_printable
    
    @type = "pink"
    @patient = Patient.find(params[:patient_id])
    
    @name = @patient.name rescue ""
    @birthdate = @patient.person.birthdate
    @sex = @patient.gender rescue ""
    
    @arv_number = @patient.arv_number rescue ""
    @transfer_in_date = @patient.transfer_in_date rescue ""
    @agreesFP = @patient.agreesFP rescue ""
    @birthweight = @patient.birthweight rescue nil
    @mother = @patient.mother.name rescue ""
    @enrolment_details = @patient.mastercard("HIV STATUS AT ENROLLMENT") rescue {}
    @pmtct_history = @patient.mastercard("PMTCT HISTORY") rescue {}
    @rad_test = @patient.mastercard("RAPID ANTIBODY TEST") rescue {}
    @dna_test = @patient.mastercard("DNA-PCR TEST") rescue {}
    @notes = @patient.mastercard("NOTES") rescue {}
    @visits = @patient.mastercard("EID VISIT") rescue {}
    
    @guardian = @patient.guardian rescue ""
    
    @guardian_details = @patient.guardian_details rescue []

    @phone_numbers = phone_numbers(@patient.mother) rescue "None" #pass guardian in parameter
    @phone_numbers = "None" if @phone_numbers.blank?
   
    @arv_number = @patient.arv_number rescue ""
    
    #check if child is wasting
    (@visits.keys rescue []).each {|visit|
      
      @visits[visit]["WASTING"] = "None"
      #check BMI
      weight = @visits[visit]["WEIGHT (KG)"].to_f rescue nil
      weightVal = ((weight.to_i > 100) ? (weight/1000) : (weight)) rescue nil
      height = @visits[visit]["HEIGHT (CM)"].to_f rescue nil
      bmi = ((10000*weightVal)/(height * height)).round(1) rescue nil
      next if bmi.blank?
      
      #check weight for age for severe wasting, etc
      w_h_a = WeightHeightForAge.median_weight_height(@patient.age_in_months, @patient.person.gender) rescue nil
      weightPercentile = ((weightVal/w_h_a.first) * 100).round(0).to_i rescue nil
      heightPercentile = ((height/w_h_a.last) * 100).round(0).to_i rescue nil

      next if weightPercentile.blank? || heightPercentile.blank?

      if ((weightPercentile < 75) rescue false) || ((heightPercentile < 75) rescue false)
        @visits[visit]["WASTING"] = "Severe"
      elsif ((75 .. 79).include?(weightPercentile) rescue false) || ((75 .. 79).include?(heightPercentile) rescue false)
        @visits[visit]["WASTING"] = "Moderate"
      end
    }
    
    render :layout => false
  end

  def birth_weight
    
    @patient = Patient.find(params[:patient_id])
    
  end

  def print_mastercard
   
    location = request.remote_ip rescue ""
    zoom = CoreService.get_global_property_value("report.zoom.percentage")/100.0 rescue 1.3
    @patient    = Patient.find(params[:patient_id]) rescue nil
    @user_id = @user["user_id"] rescue nil
  
    if @patient
      current_printer = ""
      wards = GlobalProperty.find_by_property("facility.ward.printers").property_value.split(",") rescue []

      printers = wards.each{|ward|
        current_printer = ward.split(":")[1] if ward.split(":")[0].upcase == location
      } rescue []
        
      ["page_1"].each do |page|
        name = page + "" + @patient.id.to_s
        
        t1 = Thread.new{
          Kernel.system "wkhtmltopdf --zoom #{zoom} -s A4 -R 0mm -L 0mm -T 0mm -B 0mm -O landscape http://" +
            request.env["HTTP_HOST"] + "\"/patients/mastercard_printable?patient_id=#{@patient.id}&user_id=#{@user_id}&page=#{page}" + "\" /var/www/output-#{name}" + ".pdf \n"
        }

        t2 = Thread.new{
          sleep(2)
          print(name, current_printer, Time.now)
        }
        sleep(1)
      end
    end

    redirect_to "/patients/mastercard?patient_id=#{@patient.id}&user_id=#{@user_id}" and return
  end

  def print(name, printer, time)
    if File.exists?("/var/www/output-#{name}.pdf")
      Kernel.system "lp -o sides=two-sided-short-edge -o fitplot -o fit-to-page #{(!printer.blank? ? '-d ' + printer.to_s : "")} /var/www/output-#{name}" + ".pdf\n"
      sleep(2)
      Kernel.system "rm /var/www/output-#{name}" + ".pdf"
    else
      sleep(2)
      if ((Time.now - time).to_i < 45)
        print(name, printer, time)
      end
    end
  end
  
  protected

  def sync_user
    if !session[:user].blank?
      @user = session[:user]
    else
      @user = JSON.parse(RestClient.get("#{@link}/verify/#{(session[:user_id])}")) rescue {}
    end
  end

end
