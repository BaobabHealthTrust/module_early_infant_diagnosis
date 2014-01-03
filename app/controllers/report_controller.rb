class ReportController < ApplicationController

  unloadable

  def select_cohort

    @minYear = 2008
    first_enc= Encounter.find(:first, :select => ["encounter_datetime"], :order => ["encounter_datetime ASC"])
    @minYear = first_enc.encounter_datetime.year if first_enc.present?
    
  end

  def cohort

    unless params[:from_print]

      if params[:selMonth].present? && params[:selYear].present?
     
        @start_date = Date.new(params[:selYear].to_i, params[:selMonth].to_i).beginning_of_month
        @end_date = Date.new(params[:selYear].to_i, params[:selMonth].to_i).end_of_month
       
      else

        day = params[:selQtr].to_s.match(/^min=(.+)&max=(.+)$/)
        @start_date = (day ? day[1] : Date.today.strftime("%Y-%m-%d"))
        @end_date = (day ? day[2] : Date.today.strftime("%Y-%m-%d"))

      end
      
    else

      @start_date = params[:start_date]
      @end_date = params[:end_date]
      
    end  
     
  end

  def cohort_printable
   
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    
    @year = @end_date.to_date.year rescue Date.today.year
    @month = @end_date.to_date.strftime("%B")
    @facility = get_global_property_value("facility.name")
    
    #building cohort limits for three cohorts
    #month, 12 month, and 24 month cohorts
    @start_2_months = (@end_date.to_date - 3.months).beginning_of_month
    @end_2_months = (@end_date.to_date - 3.months).end_of_month

    @start_12_months = (@end_date.to_date - 13.months).beginning_of_month
    @end_12_months = (@end_date.to_date - 13.months).end_of_month

    @start_24_months = (@end_date.to_date - 25.months).beginning_of_month
    @end_24_months = (@end_date.to_date - 25.months).end_of_month

    @enc_limit_date = @end_date.to_date.beginning_of_month - 1.day
       
    @total_registered_2_months = Encounter.encounter_patients_by_birthdate(["REGISTRATION"], @start_2_months, @end_2_months)
    @total_registered_12_months = Encounter.encounter_patients_by_birthdate(["REGISTRATION"], @start_12_months, @end_12_months)
    @total_registered_24_months = Encounter.encounter_patients_by_birthdate(["REGISTRATION"], @start_24_months, @end_24_months)

    @data_2_months = Encounter.cohort_data(@total_registered_2_months, @start_2_months, @enc_limit_date)
    @data_12_months = Encounter.cohort_data(@total_registered_12_months, @start_12_months, @enc_limit_date)
    @data_24_months = Encounter.cohort_data(@total_registered_24_months, @start_24_months, @enc_limit_date)
   
    render :layout => false

  end

  def decompose
    
    @facility = get_global_property_value("facility.name")
    
    @patients = []
    
    if params[:patients]
      ids = params[:patients].split(",")
      @patients = Patient.find(:all, :conditions => ["patient_id IN (?)", ids])
    end

    render :layout => false

  end

  def print_cohort

    @startdate = params["start_date"]
    @enddate = params["end_date"]
    
    location = request.remote_ip #rescue ""
    current_printer = ""

    wards = GlobalProperty.find_by_property("facility.ward.printers").property_value.split(",") rescue []
    
    printers = wards.each{|ward|
      current_printer = ward.split(":")[1] if ward.split(":")[0].upcase == location
    } rescue []

    link = "/report/cohort_printable?start_date=#{@startdate}&end_date=#{@enddate}&from_print=true"

    t1 = Thread.new{
      Kernel.system "wkhtmltopdf --ignore-load-errors -s A4 \"http://" +
        request.env["HTTP_HOST"] + "#{link}\" \"/tmp/cohort-" + session[:user_id] + ".pdf\" \n"
    }

    file = "/tmp/cohort-" + session[:user_id] + ".pdf"
    
    t2 = Thread.new{
      print(file, current_printer, Time.now)
    }

    redirect_to "/report/cohort?start_date=#{@startdate}&end_date=#{@enddate}&from_print=true"
  end

  def print(file_name, current_printer, start_time = Time.now)
    sleep(3)
    if (File.exists?(file_name))

      Kernel.system "lp -o sides=two-sided-long-edge -o fitplot #{(!current_printer.blank? ? '-d ' + current_printer.to_s : "")} #{file_name}"

      t3 = Thread.new{
        sleep(10)
        Kernel.system "rm #{file_name}"
      }

    else
      print(file_name, current_printer, start_time) unless start_time < 5.minutes.ago
    end
  end

end
