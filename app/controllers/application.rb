# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  include AuthenticatedSystem

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'd5feb8525b287ec306f7d88ee9a9af83'
  
  def filter_from_params
    @per_page = params[:count] ||= params[:per_page] || 10
    @page = params[:page] ||= 1
    
    @filters = {:page => @page, :per_page => @per_page}
    @state = params[:state] unless params[:state].blank?
    [:q, :type, :name, :dtstart, :dtend, :score, :filter, :zip, :postal, :city, :state, :reporter, :country].each do |p|
      @filters[p] = params[p] if params[p]
    end
  end
  
  def admin_required
    (authorized? && current_user.is_admin?) || access_denied
  end
  
  def generate_captcha
    # generate simple captcha
    session[:captcha_num_1] = @captcha_num_1 = rand(8).to_i
    session[:captcha_num_2] = @captcha_num_2 = rand(8).to_i
  end
  
  def validate_captcha
    if session[:captcha_num_1].blank? || session[:captcha_num_2].blank?
      return false
    elsif params[:fakeasscaptcha].blank?
      return false
    else
      params[:fakeasscaptcha].to_i == session[:captcha_num_1] + session[:captcha_num_2]
    end
  end
  
      
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
end
