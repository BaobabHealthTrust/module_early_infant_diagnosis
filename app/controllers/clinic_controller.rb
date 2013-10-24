
class ClinicController < ApplicationController
  unloadable  

  before_filter :sync_user, :except => [:index, :user_login, :user_logout, 
    :set_datetime, :update_datetime, :reset_datetime]

  def index
    if session[:user_id].blank? || params[:user_id].blank?
      reset_session

      user_login and return
    end

    if params[:ext_patient_id]

      patient = Patient.find(params[:ext_patient_id])
      create_registration(patient) rescue nil

    end

    @location = Location.find(params[:location_id] || session[:location_id]) rescue nil

    session[:location_id] = @location.id if !@location.blank? 
    
    redirect_to "/patients/show/#{params[:ext_patient_id]}?user_id=#{params[:user_id]}&location_id=#{
    params[:location_id]}" if !params[:ext_patient_id].nil?

    @project = get_global_property_value("project.name") rescue "Unknown"

    @facility = get_global_property_value("facility.name") rescue "Unknown"

    @patient_registration = get_global_property_value("patient.registration.url") rescue ""

    @link = get_global_property_value("user.management.url").to_s rescue nil

    @user = JSON.parse(RestClient.get("#{@link}/verify/#{(session[:user_id])}")) rescue {}
    
    session[:user] = @user rescue nil
    
    if @link.nil?
      flash[:error] = "Missing configuration for <br/>user management connection!"

      redirect_to "/no_user" and return
    end

    @selected = YAML.load_file("#{Rails.root}/config/application.yml")["#{Rails.env
        }"]["demographic.fields"].split(",") rescue []

  end


  def create_registration(patient)

    if (!patient.encounters.collect{|enc| enc.name.upcase.strip rescue nil}.include?("REGISTRATION") rescue false)

      @encounter = Encounter.create(:patient_id => patient.patient_id,
        :encounter_type => EncounterType.find_by_name("REGISTRATION").id,
        :encounter_datetime => (session[:datetime].to_time rescue Time.now),
        :provider_id => (session[:user_id] || params[:user_id]),
        :location_id => session[:location_id],
        :creator => (session[:user_id] || params[:user_id])
      )

      Observation.create(:person_id => patient.patient_id,
        :concept_id => ConceptName.find_by_name("Workstation location").concept_id,
        :value_text => Location.find(session[:location_id]).name,
        :location_id => session[:location_id],
        :encounter_id => @encounter.id,
        :creator => (session[:user_id] || params[:user_id]),
        :obs_datetime => (session[:datetime] || Time.now)
      )

      @program = Program.find_by_concept_id(ConceptName.find_by_name("EARLY INFANT DIAGNOSIS PROGRAM").concept_id) rescue nil

      @program_encounter = ProgramEncounter.find_by_program_id(@program.id,
        :conditions => ["patient_id = ? AND DATE(date_time) = ?",
          patient.id,  (session[:datetime].to_time rescue Time.now).to_date.strftime("%Y-%m-%d")])

      if @program_encounter.blank?

        @program_encounter = ProgramEncounter.create(
          :patient_id => patient.id,
          :date_time =>  (session[:datetime].to_time rescue Time.now),
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
          :date_enrolled =>(session[:datetime].to_time rescue Time.now)
        )

      end

    end

  end

  def user_login

    link = get_global_property_value("user.management.url").to_s rescue nil

    if link.nil?
      flash[:error] = "Missing configuration for <br/>user management connection!"

      redirect_to "/no_user" and return
    end

    host = request.host_with_port rescue ""

    redirect_to "#{link}/login?ext=true&src=#{host}" and return if params[:ext_user_id].nil?

  end

  def user_logout

    link = get_global_property_value("user.management.url").to_s rescue nil
    
    reset_session

    if link.nil?
      flash[:error] = "Missing configuration for <br/>user management connection!"

      redirect_to "/no_user" and return
    end

    session[:datetime] = nil
    session[:location_id] = nil

    host = request.host_with_port rescue ""

    redirect_to "#{link}/logout/#{params[:id]}?ext=true&src=#{host}" and return if params[:ext_user_id].nil?

  end

  def set_datetime
  end

  def update_datetime

    unless params[:retrospective_date].blank?
      # set for 1 second after midnight to designate it as a retrospective date
      date_of_encounter = (params[:retrospective_date] + " " + Time.now.strftime("%H:%M")).to_time

      session[:datetime] = date_of_encounter if date_of_encounter.to_date != Date.today
    end

    redirect_to "/clinic?user_id=#{params[:user_id]}&location_id=#{params[:location_id]}" and return

  end

  def reset_datetime
    session[:datetime] = nil
    redirect_to "/clinic?user_id=#{params[:user_id]}&location_id=#{params[:location_id]}" and return
  end

  def administration

    @link = get_global_property_value("user.management.url").to_s rescue nil

    if @link.nil?
      flash[:error] = "Missing configuration for <br/>user management connection!"

      redirect_to "/no_user" and return
    end

    @host = request.host_with_port rescue ""

    render :layout => false
  end

  def my_account

    @link = get_global_property_value("user.management.url").to_s rescue nil

    if @link.nil?
      flash[:error] = "Missing configuration for <br/>user management connection!"

      redirect_to "/no_user" and return
    end
    
    @host = request.host_with_port rescue ""

    render :layout => false
  end

  def overview
   
    @program_encounter_details =  ProgramEncounterDetail.find(:all, :select => ["encounter_id"], :joins => [:program_encounter],
      :conditions => ["program_encounter.program_id = ?",
        Program.find_by_name("EARLY INFANT DIAGNOSIS PROGRAM").program_id]).collect{|ped| ped.encounter_id} rescue []
    
    @types = ["REGISTRATION"]
    User.current = User.find(session[:user_id] || params[:user_id])

    @me = Encounter.statistics(@types, :conditions =>
        ['DATE(encounter_datetime) = DATE(NOW()) AND encounter.creator = ? AND encounter.location_id = ? AND encounter.encounter_id IN (?)',
        User.current.user_id, session[:location_id], @program_encounter_details])
   
    @today = Encounter.statistics(@types, :conditions => ['DATE(encounter_datetime) = DATE(NOW()) AND encounter.location_id = ? AND encounter.encounter_id IN (?)',
        session[:location_id], @program_encounter_details])

    @year = Encounter.statistics(@types, :conditions => ['YEAR(encounter_datetime) = YEAR(NOW()) AND encounter.location_id = ? AND encounter.encounter_id IN (?)',
        session[:location_id], @program_encounter_details])

    @ever = Encounter.statistics(@types, :conditions => ['encounter.location_id = ? AND encounter.encounter_id IN (?)', session[:location_id], @program_encounter_details])
 
    render :layout => false
    
  end

  def reports
    render :layout => false
  end

  def project_users
    if !session[:user].nil?
      @user = session[:user]
    else
      @user = JSON.parse(RestClient.get("#{@link}/verify/#{(session[:user_id])}")) rescue {}
    end
    render :layout => false
  end

  def project_users_list
    users = User.find(:all, :conditions => ["username LIKE ? AND user_id IN (?)", "#{params[:username]}%",
        UserProperty.find(:all, :conditions => ["property = 'Status' AND property_value = 'ACTIVE'"]
        ).map{|user| user.user_id}], :limit => 50)

    @project = get_global_property_value("project.name").downcase.gsub(/\s/, ".") rescue nil

    result = users.collect { |user|
      [
        user.id,
        (user.user_properties.find_by_property("#{@project}.activities").property_value.split(",") rescue nil),
        (user.user_properties.find_by_property("Last Name").property_value rescue nil),
        (user.user_properties.find_by_property("First Name").property_value rescue nil),
        user.username
      ]
    }

    render :text => result.to_json
  end

  def add_to_project

    @project = get_global_property_value("project.name").downcase.gsub(/\s/, ".") rescue nil

    unless params[:target].nil? || @project.nil?
      user = User.find(params[:target]) rescue nil

      unless user.nil?
        UserProperty.create(
          :user_id => user.id,
          :property => "#{@project}.activities",
          :property_value => ""
        )
      end
    end
    
    redirect_to "/project_users_list" and return
  end

  def remove_from_project

    @project = get_global_property_value("project.name").downcase.gsub(/\s/, ".") rescue nil

    unless params[:target].nil? || @project.nil?
      user = User.find(params[:target]) rescue nil

      unless user.nil?
        user.user_properties.find_by_property("#{@project}.activities").delete
      end
    end
    
    redirect_to "/project_users_list" and return
  end

  def manage_activities

    @project = get_global_property_value("project.name").downcase.gsub(/\s/, ".") rescue nil

    unless @project.nil?
      @users = UserProperty.find_all_by_property("#{@project}.activities").collect { |user| user.user_id }
    
      @roles = UserRole.find(:all, :conditions => ["user_id IN (?)", @users]).collect { |role| role.role }.sort.uniq

    end

  end

  def check_role_activities
    activities = {}

    if File.exists?("#{Rails.root}/config/protocol_task_flow.yml")
      YAML.load_file("#{Rails.root}/config/protocol_task_flow.yml")["#{Rails.env
        }"]["clinical.encounters.sequential.list"].split(",").each{|activity|
        
        activities[activity.titleize] = 0

      } rescue nil
    end
      
    role = params[:role].downcase.gsub(/\s/,".") rescue nil

    unless File.exists?("#{Rails.root}/config/roles")
      Dir.mkdir("#{Rails.root}/config/roles")
    end

    unless role.nil?
      if File.exists?("#{Rails.root}/config/roles/#{role}.yml")
        YAML.load_file("#{Rails.root}/config/roles/#{role}.yml")["#{Rails.env
        }"]["activities.list"].split(",").compact.each{|activity|

          activities[activity.titleize] = 1

        } rescue nil
      end
    end

    render :text => activities.to_json
  end

  def create_role_activities
    activities = []
    
    role = params[:role].downcase.gsub(/\s/,".") rescue nil
    activity = params[:activity] rescue nil

    unless File.exists?("#{Rails.root}/config/roles")
      Dir.mkdir("#{Rails.root}/config/roles")
    end

    unless role.nil? || activity.nil?

      file = "#{Rails.root}/config/roles/#{role}.yml"

      activities = YAML.load_file(file)["#{Rails.env
        }"]["activities.list"].split(",") rescue []

      activities << activity

      activities = activities.map{|a| a.upcase}.uniq

      f = File.open(file, "w")

      f.write("#{Rails.env}:\n    activities.list: #{activities.uniq.join(",")}")

      f.close

    end
    
    activities = {}

    if File.exists?("#{Rails.root}/config/protocol_task_flow.yml")
      YAML.load_file("#{Rails.root}/config/protocol_task_flow.yml")["#{Rails.env
        }"]["clinical.encounters.sequential.list"].split(",").each{|activity|

        activities[activity.titleize] = 0

      } rescue nil
    end

    YAML.load_file("#{Rails.root}/config/roles/#{role}.yml")["#{Rails.env
        }"]["activities.list"].split(",").each{|activity|

      activities[activity.titleize] = 1

    } rescue nil

    render :text => activities.to_json
  end

  def remove_role_activities
    activities = []

    role = params[:role].downcase.gsub(/\s/,".") rescue nil
    activity = params[:activity] rescue nil

    unless File.exists?("#{Rails.root}/config/roles")
      Dir.mkdir("#{Rails.root}/config/roles")
    end

    unless role.nil? || activity.nil?

      file = "#{Rails.root}/config/roles/#{role}.yml"

      activities = YAML.load_file(file)["#{Rails.env
        }"]["activities.list"].split(",").map{|a| a.upcase} rescue []

      activities = activities - [activity.upcase]

      activities = activities.map{|a| a.titleize}.uniq

      f = File.open(file, "w")

      f.write("#{Rails.env}:\n    activities.list: #{activities.uniq.join(",")}")

      f.close

    end

    activities = {}

    if File.exists?("#{Rails.root}/config/protocol_task_flow.yml")
      YAML.load_file("#{Rails.root}/config/protocol_task_flow.yml")["#{Rails.env
        }"]["clinical.encounters.sequential.list"].split(",").each{|activity|

        activities[activity.titleize] = 0

      } rescue nil
    end

    YAML.load_file("#{Rails.root}/config/roles/#{role}.yml")["#{Rails.env
        }"]["activities.list"].split(",").each{|activity|

      activities[activity.titleize] = 1

    } rescue nil

    render :text => activities.to_json
  end

  def project_members
  end

  def my_activities
  end

  def check_user_activities
    activities = {}

    @user["roles"].each do |role|

      role = role.downcase.gsub(/\s/,".") rescue nil

      if File.exists?("#{Rails.root}/config/roles/#{role}.yml")

        YAML.load_file("#{Rails.root}/config/roles/#{role}.yml")["#{Rails.env
        }"]["activities.list"].split(",").each{|activity|

          activities[activity.titleize] = 0 if activity.downcase.match("^" +
              (!params[:search].nil? ? params[:search].downcase : ""))

        } rescue nil

      end
    
    end

    @project = get_global_property_value("project.name").downcase.gsub(/\s/, ".") rescue nil

    unless @project.nil?
      
      UserProperty.find_by_user_id_and_property(session[:user_id],
        "#{@project}.activities").property_value.split(",").each{|activity|
        
        activities[activity.titleize] = 1 if activity.downcase.match("^" +
            (!params[:search].nil? ? params[:search].downcase : "")) and !activities[activity.titleize].nil?

      }

    end
    
    render :text => activities.to_json
  end

  def create_user_activity

    @project = get_global_property_value("project.name").downcase.gsub(/\s/, ".") rescue nil

    unless @project.nil? || params[:activity].nil?

      user = UserProperty.find_by_user_id_and_property(session[:user_id],
        "#{@project}.activities")

      unless user.nil?
        properties = user.property_value.split(",")

        properties << params[:activity]

        properties = properties.map{|p| p.upcase}.uniq

        user.update_attribute("property_value", properties.join(","))

      else

        UserProperty.create(
          :user_id => session[:user_id],
          :property => "#{@project}.activities",
          :property_value => params[:activity]
        )

      end

    end
    
    activities = {}

    @user["roles"].each do |role|

      role = role.downcase.gsub(/\s/,".") rescue nil

      if File.exists?("#{Rails.root}/config/roles/#{role}.yml")

        YAML.load_file("#{Rails.root}/config/roles/#{role}.yml")["#{Rails.env
        }"]["activities.list"].split(",").each{|activity|

          activities[activity.titleize] = 0 if activity.downcase.match("^" +
              (!params[:search].nil? ? params[:search].downcase : ""))

        } rescue nil

      end

    end

    @project = get_global_property_value("project.name").downcase.gsub(/\s/, ".") rescue nil

    unless @project.nil?

      UserProperty.find_by_user_id_and_property(session[:user_id],
        "#{@project}.activities").property_value.split(",").each{|activity|

        activities[activity.titleize] = 1

      }

    end

    render :text => activities.to_json
  end

  def remove_user_activity

    @project = get_global_property_value("project.name").downcase.gsub(/\s/, ".") rescue nil

    unless @project.nil? || params[:activity].nil?

      user = UserProperty.find_by_user_id_and_property(session[:user_id],
        "#{@project}.activities")

      unless user.nil?
        properties = user.property_value.split(",").map{|p| p.upcase}.uniq

        properties = properties - [params[:activity].upcase]

        user.update_attribute("property_value", properties.join(","))
      end

    end

    activities = {}

    @user["roles"].each do |role|

      role = role.downcase.gsub(/\s/,".") rescue nil

      if File.exists?("#{Rails.root}/config/roles/#{role}.yml")

        YAML.load_file("#{Rails.root}/config/roles/#{role}.yml")["#{Rails.env
        }"]["activities.list"].split(",").each{|activity|

          activities[activity.titleize] = 0 if activity.downcase.match("^" +
              (!params[:search].nil? ? params[:search].downcase : ""))

        } rescue nil

      end

    end

    unless @project.nil?

      UserProperty.find_by_user_id_and_property(session[:user_id],
        "#{@project}.activities").property_value.split(",").each{|activity|

        activities[activity.titleize] = 1

      }

    end

    render :text => activities.to_json
  end

  def demographics_fields
  end

  def show_selected_fields
    fields = ["Middle Name", "Maiden Name", "Home of Origin", "Current District",
      "Current T/A", "Current Village", "Landmark or Plot", "Cell Phone Number",
      "Office Phone Number", "Home Phone Number", "Occupation", "Nationality"]

    selected = YAML.load_file("#{Rails.root}/config/application.yml")["#{Rails.env
        }"]["demographic.fields"].split(",") rescue []

    @fields = {}

    fields.each{|field|
      if selected.include?(field)
        @fields[field] = 1
      else
        @fields[field] = 0
      end
    }
    
    render :text => @fields.to_json
  end

  def remove_field
    initial = YAML.load_file("#{Rails.root}/config/application.yml").to_hash rescue {}

    demographics = initial["#{Rails.env}"]["demographic.fields"].split(",") rescue []

    demographics = demographics - [params[:target]]

    initial["#{Rails.env}"]["demographic.fields"] = demographics.join(",")

    File.open("#{Rails.root}/config/application.yml", "w+") { |f| f.write(initial.to_yaml) }

    fields = ["Middle Name", "Maiden Name", "Home of Origin", "Current District",
      "Current T/A", "Current Village", "Landmark or Plot", "Cell Phone Number",
      "Office Phone Number", "Home Phone Number", "Occupation", "Nationality"]

    selected = YAML.load_file("#{Rails.root}/config/application.yml")["#{Rails.env
        }"]["demographic.fields"].split(",") rescue []

    @fields = {}

    fields.each{|field|
      if selected.include?(field)
        @fields[field] = 1
      else
        @fields[field] = 0
      end
    }

    render :text => @fields.to_json
  end

  def add_field
    initial = YAML.load_file("#{Rails.root}/config/application.yml").to_hash rescue {}

    demographics = initial["#{Rails.env}"]["demographic.fields"].split(",") rescue []

    demographics = demographics + [params[:target]]

    initial["#{Rails.env}"]["demographic.fields"] = demographics.join(",")

    File.open("#{Rails.root}/config/application.yml", "w+") { |f| f.write(initial.to_yaml) }

    fields = ["Middle Name", "Maiden Name", "Home of Origin", "Current District",
      "Current T/A", "Current Village", "Landmark or Plot", "Cell Phone Number",
      "Office Phone Number", "Home Phone Number", "Occupation", "Nationality"]

    selected = YAML.load_file("#{Rails.root}/config/application.yml")["#{Rails.env
        }"]["demographic.fields"].split(",") rescue []

    @fields = {}

    fields.each{|field|
      if selected.include?(field)
        @fields[field] = 1
      else
        @fields[field] = 0
      end
    }

    render :text => @fields.to_json
  end

  protected

  def sync_user
    if !session[:user].nil?
      @user = session[:user]
    else
      @user = JSON.parse(RestClient.get("#{@link}/verify/#{(session[:user_id])}")) rescue {}
    end
  end

end
