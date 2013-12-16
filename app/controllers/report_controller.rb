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
      day = params[:selQtr].to_s.match(/^min=(.+)&max=(.+)$/)
      @start_date = (day ? day[1] : Date.today.strftime("%Y-%m-%d"))
      @end_date = (day ? day[2] : Date.today.strftime("%Y-%m-%d"))
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
