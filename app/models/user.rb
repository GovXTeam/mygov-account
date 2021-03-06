class User < ActiveRecord::Base
  include OAuth2::Model::ResourceOwner  
  validate :email_is_whitelisted_or_user_had_existing_account, if: :valid_email?
  has_one :profile, :dependent => :destroy
  has_many :notifications, :dependent => :destroy
  has_many :tasks, :dependent => :destroy
  has_many :apps, :dependent => :destroy
  has_many :authentications, :dependent => :destroy
  has_many :app_activity_logs, :dependent => :destroy
  validates_acceptance_of :terms_of_service
  validates_presence_of :uid
  validates_uniqueness_of :uid
  validate :validate_password_strength
  validates_email_format_of :email, {:allow_blank => true}

  before_validation :generate_uid
  after_create :create_profile
  after_create :create_default_notification
  after_destroy :send_account_deleted_notification
  
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :lockable, :timeoutable, :confirmable, :async

  attr_accessible :email, :password, :password_confirmation, :remember_me, :terms_of_service, :unconfirmed_email, :as => [:default, :admin]

  WHITELISTED_DOMAINS = %w{ .gov .mil usps.com }
  attr_accessible :first_name, :last_name, :as => [:default]
  attr_accessor :just_created, :auto_approve
  
  PROFILE_ATTRIBUTES = [:title, :first_name, :middle_name, :last_name, :suffix, :address, :address2, :city, :state, :zip, :phone, :mobile, :gender, :marital_status, :is_parent, :is_retired, :is_student, :is_veteran]

  def sandbox_apps
    self.apps.sandbox
  end
  
  class << self
    
    def find_for_open_id(access_token, signed_in_resource = nil)
      data = access_token.info
      authentications_scope = (signed_in_resource && signed_in_resource.authentications) || Authentication
      authentication = authentications_scope.find_by_uid_and_provider(access_token.uid, access_token.provider)
      if authentication
        authentication.user
      elsif signed_in_resource
        signed_in_resource.authentications.new(:uid => access_token.uid, :provider => access_token.provider, :data => access_token)
        signed_in_resource.save
        signed_in_resource
      else
        user = User.new(:email => data['email'], :password => "13#{Devise.friendly_token[0,20]}")
        user.profile = Profile.new(:first_name => data["first_name"], :last_name => data["last_name"])
        user.skip_confirmation!
        user.authentications.new(:uid => access_token.uid, :provider => access_token.provider, :data => access_token)
        user.save
        user
      end
    end

    def email_is_whitelisted?(email)
      return WHITELISTED_DOMAINS.any? {|d| email.end_with?(d)}
    end

  end
  
  def first_name
    self.profile ? self.profile.first_name : @first_name
  end

  def first_name=(first_name)
    @first_name = first_name
  end

  def last_name
    self.profile ? self.profile.last_name : @last_name
  end

  def last_name=(last_name)
    @last_name = last_name
  end
  
  def confirm!
    if is_reconfirmation = is_reconfirmation?
      sync_beta_signup_with_changes
    end
    super_response = super
    is_reconfirmation ? create_email_changed_notification : create_default_notification
    super_response
  end

  def create_default_notification
    notification = self.notifications.create(
      :subject     => 'Welcome to MyUSA',
      :body        => File.read(Rails.root.to_s + "/lib/assets/text/welcome_email_body.html").html_safe,
      :received_at => Time.now,
    ) if self.confirmation_token.nil?
  end

  def create_email_changed_notification
    notification = self.notifications.create(
      :subject     => 'You changed your email address',
      :body        => File.read(Rails.root.to_s + "/lib/assets/text/email_changed_body.html").html_safe,
      :received_at => Time.now,
    ) if self.confirmation_token.nil?
  end

  def installed_apps
    self.oauth2_authorizations.map(&:client).map(&:oauth2_client_owner)
  end
  
  def grouped_activity_logs
    logs = self.app_activity_logs
    
    # create container for grouped logs that will be returned
    grouped_logs = {}
    
    # iterate over current logs
    logs.each do |log|
      key = log.created_at.strftime('%B %e')
      if grouped_logs[key]
        grouped_logs[key] << log
      else
        grouped_logs[key] = [log]
      end
    end
    
    grouped_logs
  end

  def send_reset_password_confirmation
    UserMailer.reset_password_confirmation(self.email).deliver
  end
  
  private
  
  def create_profile
    self.profile = Profile.new(:first_name => @first_name, :last_name => @last_name) unless self.profile
  end
  
  def valid_email?
    self.email? && ValidatesEmailFormatOf::validate_email_format(self.email).nil?
  end

  def email_is_whitelisted_or_user_had_existing_account
    if self.id.nil?
      unless User.email_is_whitelisted?(self.email) or BetaSignup.find_by_email_and_is_approved(self.email, true) or self.auto_approve == true
        errors.add(:base, "I'm sorry, your account hasn't been approved yet.")
      end
    end
  end

  def sync_beta_signup_with_changes
    if beta_signup = BetaSignup.find_by_email_and_is_approved(self.email, true)
      beta_signup.email = self.unconfirmed_email
      beta_signup.save!
    end

    return false
  end

  def is_reconfirmation?
    self.unconfirmed_email.present?
  end

  def validate_password_strength
    errors.add(:password, "must include at least one lower case letter, one upper case letter and one digit.") if password.present? and not password.match(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+/)
  end
  
  def generate_uid
    self.uid = SecureRandom.uuid if self.uid.blank?
  end
    
  def send_account_deleted_notification
    UserMailer.account_deleted(self.email).deliver
  end

end
