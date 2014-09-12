class RegistrationsController < Devise::RegistrationsController

  def subregion_options
    render partial: 'subregion_select'
  end

  # http://www.jacopretorius.net/2014/03/adding-custom-fields-to-your-devise-user-model-in-rails-4.html
  private
 
  def sign_up_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation, :born_at, :wants_newsletter, :document_type, :document_vatid, :terms_of_service, :address, :town, :province, :postal_code, :country)

  end
 
  def account_update_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation, :current_password, :born_at, :wants_newsletter, :document_type, :document_vatid, :address, :town, :province, :postal_code, :country)

  end
end
