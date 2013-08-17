
class EncountersController < ApplicationController
  unloadable  

  def create

    d = (session[:datetime].to_date rescue Date.today)
    t = Time.now
    session_date = DateTime.new(d.year, d.month, d.day, t.hour, t.min, t.sec)
    
    User.current = User.find(session[:user]["user_id"])
    redirect_to "/patients/show/#{params[:patient_id]}?user_id=#{User.current.user_id}" if params[:prescription].blank?

    Location.current = Location.find(params[:location_id] || session[:location_id]) rescue nil

    patient = Patient.find(params[:patient_id]) rescue nil

    if !patient.nil?

      type = EncounterType.find_by_name(params[:encounter_type]).id rescue nil

      if !type.nil?
        @encounter = Encounter.create(
          :patient_id => patient.id,
          :provider_id => (params[:user_id]),
          :encounter_type => type,
          :encounter_datetime => session_date,
          :location_id => (session[:location_id] || params[:location_id])
        )

        @current = nil

        # raise @encounter.to_yaml

        if !params[:program].blank?

          @program = Program.find_by_concept_id(ConceptName.find_by_name(params[:program]).concept_id) rescue nil

          if !@program.nil?

            @program_encounter = ProgramEncounter.find_by_program_id(@program.id,
              :conditions => ["patient_id = ? AND DATE(date_time) = ?",
                patient.id, session_date.strftime("%Y-%m-%d")])

            if @program_encounter.blank?

              @program_encounter = ProgramEncounter.create(
                :patient_id => patient.id,
                :date_time => session_date,
                :program_id => @program.id
              )

            end

            ProgramEncounterDetail.create(
              :encounter_id => @encounter.id.to_i,
              :program_encounter_id => @program_encounter.id,
              :program_id => @program.id
            )

            @current = PatientProgram.find_by_program_id(@program.id,
              :conditions => ["patient_id = ? AND COALESCE(date_completed, '') = ''", patient.id])

            if @current.blank?

              @current = PatientProgram.create(
                :patient_id => patient.id,
                :program_id => @program.id,
                :date_enrolled => session_date
              )

            end

          else

            redirect_to "/encounters/missing_program?program=#{params[:program]}" and return

          end

        end

        params[:concept].each do |key, value|

          if value.blank?
            next
          end

          if value.class.to_s.downcase != "array"

            concept = ConceptName.find_by_name(key.strip).concept_id rescue nil

            if !concept.nil? and !value.blank?

              if !@program.nil? and !@current.nil?

                selected_state = @program.program_workflows.map(&:program_workflow_states).flatten.select{|pws|
                  pws.concept.fullname.upcase() == value.upcase()
                }.first rescue nil

                @current.transition({
                    :state => "#{value}",
                    :start_date => session_date,
                    :end_date => session_date
                  }) if !selected_state.nil?
              end

              concept_type = nil
              if value.strip.match(/^\d+$/)

                concept_type = "number"

              elsif value.strip.match(/^\d{4}-\d{2}-\d{2}$/)

                concept_type = "date"

              elsif value.strip.match(/^\d{2}\:\d{2}\:\d{2}$/)

                concept_type = "time"

              else

                value_coded = ConceptName.find_by_name(value.strip) rescue nil

                if !value_coded.nil?

                  concept_type = "value_coded"

                else

                  concept_type = "text"

                end

              end

              obs = Observation.create(
                :person_id => @encounter.patient_id,
                :concept_id => concept,
                :location_id => @encounter.location_id,
                :obs_datetime => @encounter.encounter_datetime,
                :encounter_id => @encounter.id
              )

              case concept_type
              when "date"

                obs.update_attribute("value_datetime", value)

              when "time"

                obs.update_attribute("value_datetime", "#{session_date.strftime("%Y-%m-%d")} " + value)

              when "number"

                obs.update_attribute("value_numeric", value)

              when "value_coded"

                obs.update_attribute("value_coded", value_coded.concept_id)
                obs.update_attribute("value_coded_name_id", value_coded.concept_name_id)

              else

                obs.update_attribute("value_text", value)

              end

            else

              redirect_to "/encounters/missing_concept?concept=#{key}" and return if !value.blank?

            end

          else

            value.each do |item|

              concept = ConceptName.find_by_name(key.strip).concept_id rescue nil

              if !concept.nil? and !item.blank?

                if !@program.nil? and !@current.nil?
                  selected_state = @program.program_workflows.map(&:program_workflow_states).flatten.select{|pws|
                    pws.concept.fullname.upcase() == item.upcase()
                  }.first rescue nil

                  @current.transition({
                      :state => "#{item}",
                      :start_date => session_date,
                      :end_date => session_date
                    }) if !selected_state.nil?
                end

                concept_type = nil
                if item.strip.match(/^\d+$/)

                  concept_type = "number"

                elsif item.strip.match(/^\d{4}-\d{2}-\d{2}$/)

                  concept_type = "date"

                elsif item.strip.match(/^\d{2}\:\d{2}\:\d{2}$/)

                  concept_type = "time"

                else

                  value_coded = ConceptName.find_by_name(item.strip) rescue nil

                  if !value_coded.nil?

                    concept_type = "value_coded"

                  else

                    concept_type = "text"

                  end

                end

                obs = Observation.create(
                  :person_id => @encounter.patient_id,
                  :concept_id => concept,
                  :location_id => @encounter.location_id,
                  :obs_datetime => @encounter.encounter_datetime,
                  :encounter_id => @encounter.id
                )

                case concept_type
                when "date"

                  obs.update_attribute("value_datetime", item)

                when "time"

                  obs.update_attribute("value_datetime", "#{session_date.strftime("%Y-%m-%d")} " + item)

                when "number"

                  obs.update_attribute("value_numeric", item)

                when "value_coded"

                  obs.update_attribute("value_coded", value_coded.concept_id)
                  obs.update_attribute("value_coded_name_id", value_coded.concept_name_id)

                else

                  obs.update_attribute("value_text", item)

                end

              else

                redirect_to "/encounters/missing_concept?concept=#{item}" and return if !item.blank?

              end

            end

          end

        end if !params[:concept].blank?


        if !params[:prescription].blank?

          params[:prescription].each do |prescription|

            @suggestions = prescription[:suggestion] || ['New Prescription']
            @patient = Patient.find(params[:patient_id] || session[:patient_id]) rescue nil

            unless params[:location]
              session_date = session[:datetime] || params[:encounter_datetime] || Time.now()
            else
              session_date = params[:encounter_datetime] #Use encounter_datetime passed during import
            end
            # set current location via params if given
            Location.current_location = Location.find(params[:location]) if params[:location]

            @diagnosis = Observation.find(prescription[:diagnosis]) rescue nil
            @suggestions.each do |suggestion|
              unless (suggestion.blank? || suggestion == '0' || suggestion == 'New Prescription')
                @order = DrugOrder.find(suggestion)
                DrugOrder.clone_order(@encounter, @patient, @diagnosis, @order)
              else

                @formulation = (prescription[:formulation] || '').upcase
                @drug = Drug.find_by_name(@formulation) rescue nil
                unless @drug
                  flash[:notice] = "No matching drugs found for formulation #{prescription[:formulation]}"
                  # render :give_drugs, :patient_id => params[:patient_id]
                  # return
                end
                start_date = session_date
                auto_expire_date = session_date.to_date + prescription[:duration].to_i.days
                prn = prescription[:prn].to_i

                DrugOrder.write_order(@encounter, @patient, @diagnosis, @drug,
                  start_date, auto_expire_date, [prescription[:morning_dose],
                    prescription[:afternoon_dose], prescription[:evening_dose],
                    prescription[:night_dose]], prescription[:type_of_prescription], prn)

              end
            end

          end

        end

      else

        redirect_to "/encounters/missing_encounter_type?encounter_type=#{params[:encounter_type]}" and return

      end

      if params[:encounter_type].downcase.strip == "baby delivery" and !params["concept"]["Time of delivery"].nil?

        baby = Baby.new(params[:user_id], params[:patient_id], session[:location_id], (session[:datetime] || Date.today))

        mother = Person.find(params[:patient_id]) rescue nil

        link = get_global_property_value("patient.registration.url").to_s rescue nil

        baby_id = baby.associate_with_mother("#{link}", "Baby #{((params[:baby].to_i - 1) rescue 1)}",
          "#{(!mother.nil? ? (mother.names.first.family_name rescue "Unknown") :
          "Unknown")}", params["concept"]["Gender]"], params["concept"]["Date of delivery]"]) # rescue nil

        # Baby identifier
        concept = ConceptName.find_by_name("Baby outcome").concept_id rescue nil

        obs = Observation.create(
          :person_id => @encounter.patient_id,
          :concept_id => concept,
          :location_id => @encounter.location_id,
          :obs_datetime => @encounter.encounter_datetime,
          :encounter_id => @encounter.id,
          :value_text => baby_id
        ) if !baby_id.blank?

      end

      @task = TaskFlow.new(params[:user_id] || User.first.id, patient.id, session_date)
      if !params[:next_url].nil?
        redirect_to params[:next_url] and return
      else
        redirect_to @task.next_task.url and return rescue nil
      end
    end

  end

  def list_observations
    obs = []
    encounter = Encounter.find(params[:encounter_id])

    if encounter.type.name.upcase == "TREATMENT"
      obs = encounter.orders.collect{|o|
        ["drg", o.to_s]
      }
    else
      obs = encounter.observations.collect{|o|
        [o.id, o.to_piped_s] rescue nil
      }.compact
    end

    render :text => obs.to_json
  end

  def void
    prog = ProgramEncounterDetail.find_by_encounter_id(params[:encounter_id]) rescue nil

    unless prog.nil?
      prog.void

      encounter = Encounter.find(params[:encounter_id]) rescue nil

      unless encounter.nil?
        encounter.void
      end

    end


    render :text => [].to_json
  end


  def list_encounters
    result = []
    
    d = (session[:datetime].to_date rescue Date.today)
    t = Time.now
    session_date = DateTime.new(d.year, d.month, d.day, t.hour, t.min, t.sec)

    program = ProgramEncounter.find(params[:program_id]) rescue nil

    @task = TaskFlow.new(params[:user_id], program.patient_id, session_date)

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

    unless program.nil?
      result = program.program_encounter_types.find(:all, :joins => [:encounter],
        :order => ["encounter_datetime DESC"]).collect{|e|
        next if e.encounter.blank?
        labl = labell(e.encounter_id, @label_encounter_map).titleize rescue nil
        labl = e.encounter.type.name.titleize if labl.blank?
        [
          e.encounter_id, labl,
          e.encounter.encounter_datetime.strftime("%H:%M"),
          e.encounter.creator,
          e.encounter.encounter_datetime.strftime("%d-%b-%Y")
        ]
      }.uniq
    end

    render :text => result.to_json
  end

  def labell(encounter_id, hash)
    encounter = Encounter.find(encounter_id)
    concepts = encounter.observations.collect{|ob| ob.concept.name.name.downcase}
    lbl = ""
    hash.each{|val, label|
      lbl = label if (concepts.include?(val.split("|")[1].downcase) rescue false)
    }
    lbl.gsub(/examination/i , "exam")
  end
  
  def static_locations
    search_string = (params[:search_string] || "").upcase
    extras = ["Health Facility", "Home", "TBA", "Other"]

    locations = []

    File.open(RAILS_ROOT + "/public/data/locations.txt", "r").each{ |loc|
      locations << loc if loc.upcase.strip.match(search_string)
    }

    if params[:extras]
      extras.each{|loc| locations << loc if loc.upcase.strip.match(search_string)}
    end

    render :text => "<li></li><li " + locations.map{|location| "value=\"#{location.strip}\">#{location.strip}" }.join("</li><li ") + "</li>"

  end

  def diagnoses

    search_string         = (params[:search] || '').upcase

    diagnosis_concepts    = Concept.find_by_name("Qech outpatient diagnosis list").concept_members.collect{|c| c.concept.fullname}.sort.uniq rescue ["Unknown"]

    @results = diagnosis_concepts.collect{|e| e}.delete_if{|x| !x.upcase.match(/^#{search_string}/)}

    render :text => "<li>" + @results.join("</li><li>") + "</li>"

  end

  def generics
    search_string = (params[:search_string] || '').upcase
    filter_list = params[:filter_list].split(/, */) rescue []
    @drug_concepts = ConceptName.find(:all,
      :select => "concept_name.name",
      :joins => "INNER JOIN drug ON drug.concept_id = concept_name.concept_id AND drug.retired = 0",
      :conditions => ["concept_name.name LIKE ?", '%' + search_string + '%'],:group => 'drug.concept_id')
    render :text => "<li>" + @drug_concepts.map{|drug_concept| drug_concept.name }.uniq.join("</li><li>") + "</li>"
  end

  def generic
    generics = []
    # preferred = ConceptName.find_by_name("Maternity Prescriptions").concept.concept_members.collect{|c| c.id} rescue []

    Drug.all.each{|drug|
      #Concept.find(drug.concept_id, :conditions => ["retired = 0 AND concept_id IN (?)", preferred]).concept_names.each{|conceptname|
      Concept.find(drug.concept_id, :conditions => ["retired = 0"]).concept_names.each{|conceptname|
        generics << [(conceptname.name.titleize == "Tetanus Toxoid Vaccine" ? "TTV" : conceptname.name), drug.concept_id] rescue nil
      }.compact.uniq rescue []
    }

    generics.uniq
  end

  def give_drugs


    @return_url = request.referrer
    @patient = Patient.find(params[:patient_id]) rescue nil

    @generics = generic

    values = []
    @generics.each { | gen |
      if gen[0].downcase == "nvp" or gen[0].downcase == "nevirapine" or gen[0].match(/albendazole/i) or
          gen[0].match(/fefol/i) or gen[0].downcase == "fansidar"  or gen[0].downcase == "sp"
        @generics.delete(gen)
        values << gen
      end
    }
    values.each { |val|
      @generics.insert(0, val)
    }

    @frequencies = drug_frequency
    @diagnosis = @patient.current_diagnoses["DIAGNOSIS"] rescue []
  end

  def load_frequencies_and_dosages
    # @drugs = Drug.drugs(params[:concept_id]).to_json
    @drugs = drugs(params[:concept_id]).to_json
    render :text => @drugs
  end

  def dosages(generic_drug_concept_id)

    Drug.find(:all, :conditions => ["concept_id = ?", generic_drug_concept_id]).collect {|d|
      ["#{d.dose_strength.to_i rescue 1}#{d.units.upcase rescue ""}", "#{d.dose_strength.to_i rescue 1}", "#{d.units.upcase rescue ""}"]
    }.uniq.compact rescue []

  end

  def drug_frequency
    # ConceptName.drug_frequency

    # This method gets the collection of all short forms of frequencies as used in
    # the Diabetes Module and returns only no-empty values or an empty array if none
    # exist
    ConceptName.find_by_sql("SELECT name FROM concept_name WHERE concept_id IN \
                        (SELECT answer_concept FROM concept_answer c WHERE \
                        concept_id = (SELECT concept_id FROM concept_name \
                        WHERE name = 'DRUG FREQUENCY CODED')) AND concept_name_id \
                        IN (SELECT concept_name_id FROM concept_name_tag_map \
                        WHERE concept_name_tag_id = (SELECT concept_name_tag_id \
                        FROM concept_name_tag WHERE tag = 'preferred_dmht'))").collect {|freq|
      freq.name rescue nil
    }.compact rescue []

  end

  def drugs(generic_drug_concept_id)
    frequencies = drug_frequency
    collection = []

    Drug.find(:all, :conditions => ["concept_id = ? AND retired = 0", generic_drug_concept_id]).each {|d|
      frequencies.each {|freq|
        dr = d.dose_strength.to_s.match(/(\d+)\.(\d+)/)
        collection << ["#{(dr ? (dr[2].to_i > 0 ? d.dose_strength : dr[1]) : d.dose_strength.to_i) rescue 1}#{d.units.upcase rescue ""}", "#{freq}"]
      }
    }.uniq.compact rescue []

    collection.uniq
  end

  def create_prescription

    d = (session[:datetime].to_date rescue Date.today)
    t = Time.now
    session_date = DateTime.new(d.year, d.month, d.day, t.hour, t.min, t.sec)
    User.current = User.find(session[:user]["user_id"])
    redirect_to "/patients/show/#{params[:patient_id]}?user_id=#{User.current.user_id}" and return if params[:prescription].blank?

    if params[:prescription]

      params[:prescription].each do |prescription|

        @suggestions = prescription[:suggestion] || ['New Prescription']
        @patient = Patient.find(params[:patient_id]) rescue nil

        type = EncounterType.find_by_name(params[:encounter][:encounter_type_name]).id rescue nil
        encounter = @patient.encounters.find(:first, :order => ["encounter_datetime DESC"],
          :conditions => ["voided = 0 AND encounter_type = ? AND DATE(encounter_datetime) = ?", type, session_date.to_date]) rescue nil

        if !type.blank? && encounter.blank?
          encounter = Encounter.create(
            :patient_id => @patient.id,
            :provider_id => (User.current.user_id),
            :encounter_type => type,
            :encounter_datetime => session_date,
            :location_id => (session[:location_id] || params[:location_id])
          )
        end

        if !encounter.blank?
          @current = nil

          if !params[:program].blank?

            @program = Program.find_by_concept_id(ConceptName.find_by_name(params[:program]).concept_id) rescue nil

            if !@program.blank?

              @program_encounter = ProgramEncounter.find_by_program_id(@program.id,
                :conditions => ["patient_id = ? AND DATE(date_time) = ?",
                  @patient.id, session_date.to_date.strftime("%Y-%m-%d")])

              if @program_encounter.blank?

                @program_encounter = ProgramEncounter.create(
                  :patient_id => @patient.id,
                  :date_time => session_date,
                  :program_id => @program.id
                )

              end

              @encounter_detail = ProgramEncounterDetail.create(
                :encounter_id => encounter.id.to_i,
                :program_encounter_id => @program_encounter.id,
                :program_id => @program.id
              )

              @current = PatientProgram.find_by_program_id(@program.id,
                :conditions => ["patient_id = ? AND COALESCE(date_completed, '') = ''", @patient.id])

              if @current.blank?

                @current = PatientProgram.create(
                  :patient_id => @patient.id,
                  :program_id => @program.id,
                  :date_enrolled => session_date
                )

              end

            end

          end

        end

        if !prescription[:formulation]
          # redirect_to "/patients/print_exam_label/?patient_id=#{@patient.id}" and return if (encounter.type.name.upcase rescue "") ==
          #  "TREATMENT"
          next
          #redirect_to next_task(@patient) and return
        end

        unless params[:location]
          session_date = session[:datetime] || params[:encounter_datetime] || Time.now()
        else
          session_date = params[:encounter_datetime] #Use encounter_datetime passed during import
        end

        Location.current_location = Location.find(params[:location]) if params[:location]

        @encounter = encounter
        @diagnosis = Observation.find(prescription[:diagnosis]) rescue nil
        @suggestions.each do |suggestion|
          unless (suggestion.blank? || suggestion == '0' || suggestion == 'New Prescription')
            @order = DrugOrder.find(suggestion)
            DrugOrder.clone_order(@encounter, @patient, @diagnosis, @order)
          else

            @formulation = (prescription[:formulation] || '').upcase
            @drug = Drug.find_by_name(@formulation) rescue nil
            unless @drug
              flash[:notice] = "No matching drugs found for formulation #{prescription[:formulation]}"
              render :give_drugs, :patient_id => params[:patient_id], :user_id => User.current.user_id
              return
            end
            start_date = session_date
            auto_expire_date = session_date.to_date + prescription[:duration].to_i.days
            prn = prescription[:prn].to_i
            if prescription[:type_of_prescription] == "variable"

              DrugOrder.write_order(@encounter, @patient, @diagnosis, @drug,
                start_date, auto_expire_date, [prescription[:morning_dose],
                  prescription[:afternoon_dose], prescription[:evening_dose],
                  prescription[:night_dose]], prescription[:type_of_prescription], prn)

            else
              DrugOrder.write_order(@encounter, @patient, @diagnosis, @drug,
                start_date, auto_expire_date, prescription[:dose_strength], prescription[:frequency], prn)
            end
          end
        end

      end

    else

      @suggestions = params[:suggestion] || ['New Prescription']
      @patient = Patient.find(params[:patient_id]) rescue nil

      encounter = Encounter.new(params[:encounter])
      encounter.encounter_datetime ||= session[:datetime]
      encounter.save

      unless params[:location]
        session_date = session[:datetime] || params[:encounter_datetime] || Time.now()
      else
        session_date = params[:encounter_datetime] #Use encounter_datetime passed during import
      end
      # set current location via params if given
      Location.current_location = Location.find(params[:location]) if params[:location]

      @encounter = encounter
      @diagnosis = Observation.find(params[:diagnosis]) rescue nil
      @suggestions.each do |suggestion|
        unless (suggestion.blank? || suggestion == '0' || suggestion == 'New Prescription')
          @order = DrugOrder.find(suggestion)
          DrugOrder.clone_order(@encounter, @patient, @diagnosis, @order)
        else

          @formulation = (params[:formulation] || '').upcase
          @drug = Drug.find_by_name(@formulation) rescue nil
          unless @drug
            flash[:notice] = "No matching drugs found for formulation #{params[:formulation]}"
            render :give_drugs, :patient_id => params[:patient_id]
            return
          end
          start_date = session_date
          auto_expire_date = session_date.to_date + params[:duration].to_i.days
          prn = params[:prn].to_i
          if params[:type_of_prescription] == "variable"
            DrugOrder.write_order(@encounter, @patient, @diagnosis, @drug,
              start_date, auto_expire_date, [params[:morning_dose],
                params[:afternoon_dose], params[:evening_dose], params[:night_dose]], 'VARIABLE', prn)
          else
            DrugOrder.write_order(@encounter, @patient, @diagnosis, @drug,
              start_date, auto_expire_date, params[:dose_strength], params[:frequency], prn)
          end
        end
      end

    end

    #  redirect_to "/patients/print_exam_label/?patient_id=#{@patient.id}" and return if (@encounter.type.name.upcase rescue "") ==
    #   "TREATMENT"

    redirect_to "/patients/show/#{params[:patient_id]}?user_id=#{User.current.user_id}"

  end
  
end
