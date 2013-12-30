class ReportController < ApplicationController

  unloadable

  def select_cohort    
        
  end
 
  def report

    @startdate = params["start_date"]
    @enddate = params["end_date"]

    @facility = get_global_property_value("facility.name")
    @year = @enddate.to_date.year rescue Date.today.year
    @month = @enddate.to_date.strftime("%B")

    report = Report.new(@startdate, @enddate)
      
    render :layout => false
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

    
    
    @total_registered_2_months = Encounter.encounter_patients(["REGISTRATION"], @start_2_months, @end_2_months)
    @total_registered_12_months = Encounter.encounter_patients(["REGISTRATION"], @start_12_months, @end_12_months)
    @total_registered_24_months = Encounter.encounter_patients(["REGISTRATION"], @start_24_months, @end_24_months)

    @data_2_months = Encounter.cohort_data(@total_registered_2_months, @start_2_months, @end_2_months)
    @data_12_months = Encounter.cohort_data(@total_registered_12_months, @start_12_months, @end_12_months)
    @data_24_months = Encounter.cohort_data(@total_registered_24_months, @start_24_months, @end_24_months)

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
 
end
