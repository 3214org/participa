class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :omniauthable
  devise :database_authenticatable, :registerable, :confirmable, :timeoutable,
         :recoverable, :rememberable, :trackable, :validatable, :lockable

  acts_as_paranoid

  validates :first_name, :last_name, :document_type, :document_vatid, presence: true
  validates :address, :postal_code, :town, :province, :country, presence: true
  validates :email, confirmation: true, on: :create
  validates :email_confirmation, presence: true, on: :create
  validates :terms_of_service, acceptance: true
  validates :over_18, acceptance: true
  #validates :country, length: {minimum: 1, maximum: 2}
  validates :document_type, inclusion: { in: [1, 2, 3], message: "tipo de documento no válido" }
  validates :document_vatid, valid_nif: true, if: :is_document_dni?
  validates :document_vatid, valid_nie: true, if: :is_document_nie?
  validates :born_at, date: true, allow_blank: true # gem date_validator
  validates :born_at, inclusion: { in: Date.civil(1900, 1, 1)..Date.today-18.years,
    message: "debes ser mayor de 18 años" }, allow_blank: true
  validates :phone, numericality: true, allow_blank: true
  validates :unconfirmed_phone, numericality: true, allow_blank: true

  # TODO: validacion if country == ES then postal_code /(\d5)/

  validates :email, uniqueness: {case_sensitive: false, scope: :deleted_at }
  validates :document_vatid, uniqueness: {case_sensitive: false, scope: :deleted_at }
  validates :phone, uniqueness: {scope: :deleted_at}, allow_blank: true, allow_nil: true
  validates :unconfirmed_phone, uniqueness: {scope: :deleted_at}, allow_blank: true, allow_nil: true
  
  validate :validates_phone_format
  validate :validates_unconfirmed_phone_format
  validate :validates_unconfirmed_phone_uniqueness

  def validates_unconfirmed_phone_uniqueness
    if self.unconfirmed_phone.present? 
      if User.confirmed_phone.where(phone: self.unconfirmed_phone).exists? 
        self.update_attribute(:unconfirmed_phone, nil)
        self.errors.add(:phone, "Ya hay alguien con ese número de teléfono")
      end
    end
  end

  def validates_phone_format
    if self.phone.present? 
      self.errors.add(:phone, "Revisa el formato de tu teléfono") unless Phoner::Phone.valid?(self.phone) 
    end
  end

  def validates_unconfirmed_phone_format
    if self.unconfirmed_phone.present? 
      self.errors.add(:unconfirmed_phone, "Revisa el formato de tu teléfono") unless Phoner::Phone.valid?(self.unconfirmed_phone) 
      if self.country.downcase == "es" and not self.unconfirmed_phone.starts_with?('00346')
        self.errors.add(:unconfirmed_phone, "Debes poner un teléfono móvil válido de España empezando por 6.") 
      end
    end
  end

  attr_accessor :sms_user_token_given
  attr_accessor :login

  has_many :votes 
  has_one :collaboration

  scope :all_with_deleted, -> { where "deleted_at IS null AND deleted_at IS NOT null"  }
  scope :users_with_deleted, -> { where "deleted_at IS NOT null"  }
  scope :wants_newsletter, -> {where(wants_newsletter: true)}
  scope :created, -> { where(deleted_at: nil)  }
  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :unconfirmed_mail, -> { where(confirmed_at: nil)  }
  scope :unconfirmed_phone, -> { where(sms_confirmed_at: nil) }
  scope :confirmed_mail, -> { where.not(confirmed_at: nil) }
  scope :confirmed_phone, -> { where.not(sms_confirmed_at: nil) }
  scope :legacy_password, -> { where(has_legacy_password: true) }
  scope :confirmed, -> { where.not(confirmed_at: nil).where.not(sms_confirmed_at: nil) }
  scope :signed_in, -> { where.not(sign_in_count: nil) }

  DOCUMENTS_TYPE = [["DNI", 1], ["NIE", 2], ["Pasaporte", 3]]

  # https://github.com/plataformatec/devise/wiki/How-To:-Allow-users-to-sign-in-using-their-username-or-email-address
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions).where(["lower(document_vatid) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions).first
    end
  end

  def get_or_create_vote election_id
    # FIXME bug with NoMethodError: undefined method `paranoia_column' for #<Class:0x00000005a466b8>
    #Vote.where(user_id: self.id, election_id: election_id).first_or_create
    user_id = self.id

    if Vote.exists?({election_id: election_id, user_id: user_id})
      Vote.where({election_id: election_id, user_id: user_id}).first
    else
      v = Vote.new({election_id: election_id, user_id: user_id})
      v.voter_id = v.generate_voter_id
      v.save(validate: false)
      v
    end
  end

  def document_vatid=(val)
    self[:document_vatid] = val.upcase.strip
  end

  def is_document_dni?
    self.document_type == 1
  end

  def is_document_nie?
    self.document_type == 2
  end

  def is_passport?
    self.document_type == 3
  end

  def full_name
    "#{self.first_name} #{self.last_name}"
  end

  def is_admin?
    self.admin
  end

  def is_valid_user?
    self.phone? and self.sms_confirmed_at?
  end

  def is_valid_phone?
    self.sms_confirmed_at? && self.sms_confirmed_at > self.confirmation_sms_sent_at || false
  end

  def can_change_phone?
    self.sms_confirmed_at? ? self.sms_confirmed_at < DateTime.now-3.months : true
  end

  def generate_sms_token
    SecureRandom.hex(4).upcase
  end

  def set_sms_token!
    self.update_attribute(:sms_confirmation_token, generate_sms_token)
  end

  def send_sms_token!
    require 'sms'
    self.update_attribute(:confirmation_sms_sent_at, DateTime.now)
    SMS::Sender.send_message(self.phone, self.sms_confirmation_token)
  end

  def check_sms_token(token)
    if token == self.sms_confirmation_token
      self.update_attribute(:sms_confirmed_at, DateTime.now)
      if self.unconfirmed_phone? 
        self.update_attribute(:phone, self.unconfirmed_phone)
        self.update_attribute(:unconfirmed_phone, nil)
      end
      true
    else 
      false
    end
  end

  def phone_normalize(phone_number, country_iso=nil)
    Phoner::Country.load
    cc = country_iso.nil? ? self.country : country_iso
    country = Phoner::Country.find_by_country_isocode(cc.downcase)
    phoner = Phoner::Phone.parse(phone_number, :country_code => country.country_code)
    phoner.nil? ? nil : "00" + phoner.country_code + phoner.area_code + phoner.number
  end

  def unconfirmed_phone_number
    Phoner::Country.load
    country = Phoner::Country.find_by_country_isocode(self.country.downcase)
    if Phoner::Phone.valid?(self.unconfirmed_phone)
      phoner = Phoner::Phone.parse(self.unconfirmed_phone, :country_code => country.country_code)
      phoner.area_code + phoner.number
    else
      nil
    end
  end

  def phone_prefix 
    if self.country.length < 3 
      Phoner::Country.load
      Phoner::Country.find_by_country_isocode(self.country.downcase).country_code
    else
      "34"
    end
  end

  def phone_country_name
    if Phoner::Phone.valid?(self.phone)
      Phoner::Country.load
      country_code = Phoner::Phone.parse(self.phone).country_code
      Carmen::Country.coded(Phoner::Country.find_by_country_code(country_code).char_3_code).name
    else
      Carmen::Country.coded(self.country).name
    end
  end

  def phone_no_prefix
    phone = Phoner::Phone.parse(self.phone)
    phone.area_code + phone.number
  end

  def document_type_name
    User::DOCUMENTS_TYPE.select{|v| v[1] == self.document_type }[0][0]
  end

  def country_name
    if self.country.length > 3 
      self.country
    else
      begin
        Carmen::Country.coded(self.country).name
      rescue
        ""
      end
    end
  end

  def province_name
    if self.province.length > 3 
      self.province
    else
      begin
        Carmen::Country.coded(self.country).subregions.coded(self.province).name
      rescue
        ""
      end
    end
  end

  def town_name
    if self.town.include? "_"
      begin
        Carmen::Country.coded(self.country).subregions.coded(self.province).subregions.coded(self.town).name
      rescue
        ""
      end
    else
      self.town
    end
  end

  def users_with_deleted
    User.with_deleted
  end

end
