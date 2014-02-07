
class User < ActiveRecord::Base

	set_table_name :users
	set_primary_key :user_id
	include Openmrs

	has_many :user_properties, :foreign_key => :user_id # no default scope
  has_many :user_roles, :foreign_key => :user_id # no default scope

  cattr_accessor :current

  def admin?
    admin = self.user_roles.map{|user_role| user_role.role }.include? 'Informatics Manager'
    admin = self.user_roles.map{|user_role| user_role.role }.include? 'System Developer' unless admin
    admin = self.user_roles.map{|user_role| user_role.role }.include? 'Program Manager' unless admin
    admin = self.user_roles.map{|user_role| user_role.role }.include? 'Superuser' unless admin
    admin
  end

  def name
    #self.first_name + " " + self.last_name
    user = (UserProperty.find_by_user_id_and_property(self.id, "First Name").property_value.titleize rescue nil) + " " + (UserProperty.find_by_user_id_and_property(self.id, "Last Name").property_value.titleize rescue nil)
  end

end
