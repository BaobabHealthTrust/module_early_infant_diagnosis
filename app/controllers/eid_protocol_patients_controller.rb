
class EidProtocolPatientsController < ApplicationController
	unloadable

	before_filter :check_user

	def give_drugs

	@patient = Patient.find(params[:patient_id]) rescue nil

	@session_date = session[:datetime] rescue nil 

	redirect_to '/encounters/no_patient' and return if @patient.nil?

	if params[:user_id].nil?
	redirect_to '/encounters/no_user' and return
	end

	@user = User.find(params[:user_id]) rescue nil?

	redirect_to '/encounters/no_patient' and return if @user.nil?
	

	end

	def notes

	@patient = Patient.find(params[:patient_id]) rescue nil

	@session_date = session[:datetime] rescue nil 

	redirect_to '/encounters/no_patient' and return if @patient.nil?

	if params[:user_id].nil?
	redirect_to '/encounters/no_user' and return
	end

	@user = User.find(params[:user_id]) rescue nil?

	redirect_to '/encounters/no_patient' and return if @user.nil?
	

	end

	def enrollment_status

	@patient = Patient.find(params[:patient_id]) rescue nil

	@session_date = session[:datetime] rescue nil 

	redirect_to '/encounters/no_patient' and return if @patient.nil?

	if params[:user_id].nil?
	redirect_to '/encounters/no_user' and return
	end

	@user = User.find(params[:user_id]) rescue nil?

	redirect_to '/encounters/no_patient' and return if @user.nil?
	

	end

	def pmtct_history

	@patient = Patient.find(params[:patient_id]) rescue nil

	@session_date = session[:datetime] rescue nil 

	redirect_to '/encounters/no_patient' and return if @patient.nil?

	if params[:user_id].nil?
	redirect_to '/encounters/no_user' and return
	end

	@user = User.find(params[:user_id]) rescue nil?

	redirect_to '/encounters/no_patient' and return if @user.nil?
	

	end

	def eid_visit

	@patient = Patient.find(params[:patient_id]) rescue nil

	@session_date = session[:datetime] rescue nil 

	redirect_to '/encounters/no_patient' and return if @patient.nil?

	if params[:user_id].nil?
	redirect_to '/encounters/no_user' and return
	end

	@user = User.find(params[:user_id]) rescue nil?

	redirect_to '/encounters/no_patient' and return if @user.nil?
	

	end

end
