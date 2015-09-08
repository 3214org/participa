class ImpulsaProject < ActiveRecord::Base
  belongs_to :impulsa_edition_category
  belongs_to :user
  has_one :impulsa_edition, through: :impulsa_edition_category
  has_many :impulsa_project_attachments

  has_many :impulsa_project_topics
  has_many :impulsa_edition_topics, through: :impulsa_project_topics

  has_attached_file :logo, styles: { medium: "300x300>", thumb: "100x100>" }, default_url: "/images/:style/missing.png"
  has_attached_file :scanned_nif
  has_attached_file :endorsement
  has_attached_file :register_entry
  has_attached_file :statutes
  has_attached_file :responsible_nif
  has_attached_file :fiscal_obligations_certificate
  has_attached_file :labor_obligations_certificate
  has_attached_file :home_certificate
  has_attached_file :bank_certificate
  has_attached_file :last_fiscal_year_report_of_activities
  has_attached_file :last_fiscal_year_annual_accounts
  has_attached_file :schedule
  has_attached_file :activities_resources
  has_attached_file :requested_budget
  has_attached_file :monitoring_evaluation

  validates :user, uniqueness: {scope: :impulsa_edition_category}, allow_blank: false, allow_nil: false, unless: Proc.new { |project| project.user.nil? || project.user.impulsa_author? }
  validates :name, :impulsa_edition_category_id, :status, presence: true

  validate :if => :marked_for_review? do |project|
    project.user_editable_fields.each do |field|
      project.validates_presence_of field if !FIELDS[:optional].member?(field)
    end
  end

  validates :authority_email, allow_blank: true, email: true
  validates :organization_web, :video_link, allow_blank: true, url: true
  validates :organization_year, allow_blank: true, numericality: { only_integer: true, greater_than_or_equal_to: 1000, less_than_or_equal_to: Date.today.year }

  validates :terms_of_service, :data_truthfulness, acceptance: true

  validates_each :impulsa_edition_topics do |project, attr, value|
    project.errors.add attr, "Demasiadas temáticas para el proyecto" if project.impulsa_edition_topics.size > 2
  end

  validates_attachment_content_type :logo, content_type: ["image/jpeg", "image/jpg", "image/gif", "image/png"]
  validates_with AttachmentSizeValidator, attributes: :logo, less_than: 1.megabytes
  validates_attachment_content_type :scanned_nif, content_type: ["application/pdf", "application/x-pdf"]
  validates_with AttachmentSizeValidator, attributes: :scanned_nif, less_than: 1.megabytes
  validates_attachment_content_type :endorsement, content_type: ["application/pdf", "application/x-pdf"]
  validates_with AttachmentSizeValidator, attributes: :endorsement, less_than: 1.megabytes
  validates_attachment_content_type :register_entry, content_type: ["application/pdf", "application/x-pdf"]
  validates_with AttachmentSizeValidator, attributes: :register_entry, less_than: 1.megabytes
  validates_attachment_content_type :statutes, content_type: ["application/pdf", "application/x-pdf"]
  validates_with AttachmentSizeValidator, attributes: :statutes, less_than: 1.megabytes
  validates_attachment_content_type :responsible_nif, content_type: ["application/pdf", "application/x-pdf"]
  validates_with AttachmentSizeValidator, attributes: :responsible_nif, less_than: 1.megabytes
  validates_attachment_content_type :fiscal_obligations_certificate, content_type: ["application/pdf", "application/x-pdf"]
  validates_with AttachmentSizeValidator, attributes: :fiscal_obligations_certificate, less_than: 1.megabytes
  validates_attachment_content_type :labor_obligations_certificate, content_type: ["application/pdf", "application/x-pdf"]
  validates_with AttachmentSizeValidator, attributes: :labor_obligations_certificate, less_than: 1.megabytes
  validates_attachment_content_type :home_certificate, content_type: ["application/pdf", "application/x-pdf"]
  validates_with AttachmentSizeValidator, attributes: :home_certificate, less_than: 1.megabytes
  validates_attachment_content_type :bank_certificate, content_type: ["application/pdf", "application/x-pdf"]
  validates_with AttachmentSizeValidator, attributes: :bank_certificate, less_than: 1.megabytes
  validates_attachment_content_type :last_fiscal_year_report_of_activities, content_type: ["application/pdf", "application/x-pdf"]
  validates_with AttachmentSizeValidator, attributes: :last_fiscal_year_report_of_activities, less_than: 1.megabytes
  validates_attachment_content_type :last_fiscal_year_annual_accounts, content_type: ["application/pdf", "application/x-pdf"]
  validates_with AttachmentSizeValidator, attributes: :last_fiscal_year_annual_accounts, less_than: 1.megabytes
  validates_attachment_content_type :schedule, content_type: [ "application/vnd.ms-excel", "application/msexcel", "application/x-msexcel", "application/x-ms-excel", "application/x-excel", "application/x-dos_ms_excel", "application/xls", "application/x-xls", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "application/vnd.oasis.opendocument.spreadsheet" ]
  validates_with AttachmentSizeValidator, attributes: :schedule, less_than: 1.megabytes
  validates_attachment_content_type :activities_resources, content_type: [ "application/vnd.ms-word", "application/msword", "application/x-msword", "application/x-ms-word", "application/x-word", "application/x-dos_ms_word", "application/doc", "application/x-doc", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/vnd.oasis.opendocument.text" ]
  validates_with AttachmentSizeValidator, attributes: :activities_resources, less_than: 1.megabytes
  validates_attachment_content_type :requested_budget, content_type: [ "application/vnd.ms-excel", "application/msexcel", "application/x-msexcel", "application/x-ms-excel", "application/x-excel", "application/x-dos_ms_excel", "application/xls", "application/x-xls", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "application/vnd.oasis.opendocument.spreadsheet" ]
  validates_with AttachmentSizeValidator, attributes: :requested_budget, less_than: 1.megabytes
  validates_attachment_content_type :monitoring_evaluation, content_type: [ "application/vnd.ms-excel", "application/msexcel", "application/x-msexcel", "application/x-ms-excel", "application/x-excel", "application/x-dos_ms_excel", "application/xls", "application/x-xls", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "application/vnd.oasis.opendocument.spreadsheet" ]
  validates_with AttachmentSizeValidator, attributes: :monitoring_evaluation, less_than: 1.megabytes

  scope :by_status, ->(status) { where( status: status ) }

  PROJECT_STATUS = {
    new: 0,
    review: 1,
    fixes: 2,
    review_fixes: 3,
    validate: 4,
    invalidated: 5,
    validated: 6,
    discarded: 7,
    resigned: 8,
    winner: 9
  }

  FIELDS = {
    admin: [ :user_id, :status, :review_fields, :counterpart_information, :additional_contact ],
    always: [ :impulsa_edition_category_id ],
    with_category: [ :name, :short_description, :logo, :video_link ],
    authority: [ :authority, :authority_name, :authority_phone, :authority_email ],
    organization_types: [ :organization_type ],
    full_organization: [ :organization_name, :organization_address, :organization_web, :organization_nif, :scanned_nif, :organization_year, :organization_legal_name, :organization_legal_nif, :organization_mission, :register_entry, :statutes ],
    non_organization: [ :career ],
    not_in_spain: [ :home_certificate, :bank_certificate ],
    non_project_details: [ :additional_contact ],
    project_details: [ :impulsa_edition_topics, :territorial_context, :long_description, :aim, :metodology, :population_segment, :schedule, :activities_resources, :requested_budget, :counterpart, :impulsa_edition_topic_ids, :endorsement, :responsible_nif, :fiscal_obligations_certificate, :labor_obligations_certificate],
    additional_details: [ :last_fiscal_year_report_of_activities, :last_fiscal_year_annual_accounts, :monitoring_evaluation ], 
    translation: [ :coofficial_translation, :coofficial_name, :coofficial_short_description, :coofficial_video_link ],
    new: [ :terms_of_service, :data_truthfulness ],
    update: [ :data_truthfulness ],

    optional: [ :counterpart_information, :last_fiscal_year_report_of_activities, :last_fiscal_year_annual_accounts, :video_link ]
  }

  ADMIN_REVIEWABLE_FIELDS = FIELDS[:always] + FIELDS[:with_category] + FIELDS[:authority] + FIELDS[:organization_types] + FIELDS[:full_organization] + FIELDS[:non_organization] + FIELDS[:not_in_spain] + FIELDS[:non_project_details] + FIELDS[:project_details] + FIELDS[:additional_details] + FIELDS[:translation]

  ALL_FIELDS = FIELDS.map {|k,v| v} .flatten.uniq

  ORGANIZATION_TYPES = {
    organization: 0,
    people: 1,
    foreign_people: 2
  }

  def new?
    self.status==PROJECT_STATUS[:new]
  end

  def fixes?
    self.status==PROJECT_STATUS[:fixes]
  end

  def allow_save_draft?
    self.new? || (self.status==PROJECT_STATUS[:review] && self.errors.any?)
  end

  def marked_for_review?
    self.status==PROJECT_STATUS[:review] || self.status==PROJECT_STATUS[:review_fixes]
  end

  def mark_for_review
    if self.new?
      self.status=PROJECT_STATUS[:review]
    elsif self.fixes?
      self.status=PROJECT_STATUS[:review_fixes]
    end
  end

  def editable?
    self.status < PROJECT_STATUS[:validate] && self.impulsa_edition.current_phase < ImpulsaEdition::EDITION_PHASES[:validation_projects]
  end

  def reviewable?
    persisted? and editable?
  end

  def preload params
    if params
      self.impulsa_edition_category_id = params[:impulsa_edition_category_id] if params[:impulsa_edition_category_id]
      if self.allows_organization_types?
        self.organization_type = params[:organization_type] if params[:organization_type]
        self.organization_type = 0 if self.organization_type.nil?
      end
    end
  end

  def user_view_field? field
    user_viewable_fields.member? field
  end

  def user_viewable_fields
    fields = FIELDS[:always]

    if self.impulsa_edition_category
      fields += FIELDS[:with_category]
      fields += FIELDS[:translation] if self.translatable? 

      fields += FIELDS[:authority] if self.needs_authority?

      if self.needs_organization?
        fields += FIELDS[:full_organization]
      else
        fields += FIELDS[:non_organization]
      end
      
      if self.needs_project_details?
        fields += FIELDS[:project_details] 
        fields += FIELDS[:organization_types] if self.allows_organization_types?
        fields += FIELDS[:not_in_spain] if self.not_in_spain?
        fields += FIELDS[:additional_details] if self.needs_additional_details?
      else
        fields += FIELDS[:non_project_details] 
      end

      fields += FIELDS[:new] if !self.persisted?
      fields += FIELDS[:update] if self.editable?
    end
    fields.uniq
  end

  def user_edit_field? field
    user_editable_fields.member? field
  end
  
  def user_editable_fields
    case self.status
      when 0..1
        self.user_viewable_fields
      when 2
        review_fields.symbolize_keys.keys
      else
        []
      end
  end

  def status_name
    ImpulsaProject::STATUS_NAMES.invert[self.status]
  end

  def organization_type_name
    ImpulsaProject::ORGANIZATION_TYPES.invert[self.organization_type]
  end

  def needs_authority?
    self.impulsa_edition_category.needs_authority? if self.impulsa_edition_category
  end

  def needs_project_details?
    self.impulsa_edition_category.needs_project_details? if self.impulsa_edition_category
  end

  def needs_additional_details?
    self.impulsa_edition_category.needs_additional_details? if self.impulsa_edition_category
  end

  def allows_organization_types?
    self.impulsa_edition_category.allows_organization_types? if self.impulsa_edition_category
  end

  def needs_organization?
    (self.impulsa_edition_category.needs_additional_details? if self.impulsa_edition_category) || self.organization_type == 0
  end

  def not_in_spain?
    self.organization_type == 2
  end

  def translatable?
    self.impulsa_edition_category.translatable? if self.impulsa_edition_category
  end

  def organization_type
    self[:organization_type] if self.allows_organization_types?
  end

  def review_fields
    @review_fields ||= (YAML.load(self[:review_fields]) if self[:review_fields]) || {}
  end

  def method_missing(method_sym, *arguments, &block)
    method = method_sym.to_s
    if method =~ /^(.*)_review=?$/
      if method.last=="="
        if arguments.first.blank?
          review_fields.delete method[0..-9].to_sym
        else
          review_fields[method[0..-9].to_sym] = arguments.first
        end
        self[:review_fields] = review_fields.to_yaml
      else
        review_fields[method[0..-8].to_sym]
      end
    else
      super
    end
  end

  def respond_to?(name)
    name =~ /^(.*)_review=?$/ || super
  end
end
