Rails.application.routes.draw do

  get '', to: redirect("/#{I18n.locale}")
  
  scope "/(:locale)", locale: /es|ca|eu/ do 
    get :notices, to: 'notice#index', as: 'notices'
    scope :validator do
      scope :sms do 
        get :step1, to: 'sms_validator#step1', as: 'sms_validator_step1'
        post :phone, to: 'sms_validator#step1', as: 'sms_validator_phone'
        get :step2, to: 'sms_validator#step2', as: 'sms_validator_step2'
        post :captcha, to: 'sms_validator#captcha', as: 'sms_validator_captcha'
        get :step3, to: 'sms_validator#step3', as: 'sms_validator_step3'
        post :valid, to: 'sms_validator#valid', as: 'sms_validator_valid'
      end
    end
    get '/vote/create/:election_id', to: 'vote#create', as: :create_vote
    devise_for :users, controllers: { 
      registrations: 'registrations', 
      confirmations: 'confirmations'
    } 
    # http://stackoverflow.com/a/8884605/319241 
    devise_scope :user do
      get '/registrations/subregion_options', to: 'registrations#subregion_options'
      authenticated :user do
        root 'tools#index', as: :authenticated_root
      end
      unauthenticated do
        root 'devise/sessions#new', as: :root
      end
    end
  end
  # /admin
  ActiveAdmin.routes(self)

  constraints CanAccessResque.new do
    mount Resque::Server.new, at: '/admin/resque', as: :resque
  end

end

