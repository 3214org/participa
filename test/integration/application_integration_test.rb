require 'test_helper'

class ApplicationIntegrationTest < ActionDispatch::IntegrationTest

  setup do
    @user = FactoryGirl.create(:user)
  end

  def login user
    post_via_redirect user_session_path, 'user[login]' => user.email, 'user[password]' => user.password 
  end

  test "should default_url_options locale" do
    get '/'
    assert_response :redirect
    assert_redirected_to '/es'
  end

  test "should set_locale" do
    get '/ca'
    assert_equal(:ca, I18n.locale)
    get '/eu'
    assert_equal(:eu, I18n.locale)
  end

  test "should success when login with a foreign user" do
    @user.update_attribute(:country, "DE")
    @user.update_attribute(:province, "BE")
    @user.update_attribute(:town, "Berlin")
    login @user
    get '/es'
    assert_response :success
  end

  test "should success when login with a rare foreign user (no provinces)" do
    @user.update_attribute(:country, "PS")
    @user.update_attribute(:province, "Cisjordania")
    @user.update_attribute(:town, "Belén")
    login @user
    
    get '/es'
    assert_response :success
  end

  test "should set_phone if non sms confirmed user" do
    @user.update_attribute(:sms_confirmed_at, nil)
    login @user
    assert_equal("Por seguridad, debes confirmar tu teléfono para continuar utilizando este sistema.", flash[:alert])
    get '/es'
    assert_response :redirect
    assert_redirected_to sms_validator_step1_path
  end

  test "should set_new_password, set_phone and check_born_at" do 
    @user.update_attribute(:has_legacy_password, true)
    @user.update_attribute(:sms_confirmed_at, nil)
    @user.update_attribute(:born_at, Date.civil(1900,1,1))
    login @user
    assert_equal("Por seguridad, debes confirmar tu teléfono para continuar utilizando este sistema.", flash[:alert])
    get '/es'
    assert_response :redirect
    assert_redirected_to sms_validator_step1_path
  end

  test "should set_new_password if legacy password" do
    @user.update_attribute(:has_legacy_password, true)
    login @user
    assert_equal("Por seguridad, debes cambiar tu contraseña para continuar utilizando este sistema.", flash[:alert])
    get "/es"
    assert_response :redirect
    assert_redirected_to new_legacy_password_path
  end

  test "should check_born_at if born_at is null" do
    @user.update_attribute(:born_at, nil)
    login @user
    assert_equal("Debes indicar tu fecha de nacimiento para continuar utilizando este sistema.", flash[:alert])
    get '/es'
    assert_response :redirect
    assert_redirected_to edit_user_registration_url
  end

  test "should check_born_at if born_at 1900,1,1" do
    @user.update_attribute(:born_at, Date.civil(1900,1,1))
    login @user
    assert_equal("Debes indicar tu fecha de nacimiento para continuar utilizando este sistema.", flash[:alert])
    get '/es'
    assert_response :redirect
    assert_redirected_to edit_user_registration_url
  end

  test "should redirect to profile with invalid country data" do
    @user.update_attribute(:country, "España")
    login @user
    assert_equal("Debes indicar el país donde resides para continuar utilizando este sistema.", flash[:alert])
    get '/es'
    assert_response :redirect
    assert_redirected_to edit_user_registration_url
  end

  test "should redirect to profile with invalid province data" do
    @user.update_attribute(:province, "Madrid")
    login @user
    assert_equal("Debes indicar la provincia donde resides para continuar utilizando este sistema.", flash[:alert])
    get '/es'
    assert_response :redirect
    assert_redirected_to edit_user_registration_url
  end

  test "should redirect to profile with invalid town data" do
    @user.update_attribute(:town, "Madrid")
    login @user
    assert_equal("Debes indicar el municipio donde resides para continuar utilizando este sistema.", flash[:alert])
    get '/es'
    assert_response :redirect
    assert_redirected_to edit_user_registration_url
  end

end