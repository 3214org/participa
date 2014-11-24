class RegistrationsController < Devise::RegistrationsController
  require "ffi-icu"

  prepend_before_filter :load_user_location

  def load_user_location
    @user_location = User.get_location(current_user, params)
  end

  def regions_provinces
    render partial: 'subregion_select'
  end

  def regions_municipies
    render partial: 'municipies_select'
  end

  def create
    if verify_recaptcha
      super
    else
      build_resource(sign_up_params)
      clean_up_passwords(resource)

      render :new
    end
  end

  # http://www.jacopretorius.net/2014/03/adding-custom-fields-to-your-devise-user-model-in-rails-4.html
  private

  def sign_up_params
    params.require(:user).permit(:first_name, :last_name, :email, :email_confirmation, :password, :password_confirmation, :born_at, :wants_newsletter, :document_type, :document_vatid, :terms_of_service, :over_18, :address, :town, :province, :postal_code, :country)
  end

  def account_update_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation, :current_password, :born_at, :wants_newsletter, :address, :town, :province, :postal_code, :country)
  end

end
