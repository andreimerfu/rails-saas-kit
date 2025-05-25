# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  has_many :notifications, as: :recipient, dependent: :destroy, class_name: "Noticed::Notification"
  devise :confirmable, :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable,
         omniauth_providers: [ :github, :google_oauth2, :microsoft_entra_id ],
         authentication_keys: [ :email ]

  belongs_to :organization, optional: true

  # Declare role as integer attribute for enum
  attribute :role, :integer, default: 0
  enum :role, { member: 0, admin: 1, owner: 2 }

  validates :name, presence: true, length: { maximum: 50 }
  validates :role, presence: true

  def platform_admin?
    is_admin
  end

  def platform_admin!
    update!(is_admin: true)
  end

  def onboarded?
    # Check if the user has an organization associated
    # and if the organization has been created (not nil)
    organization.present? && organization.persisted?
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if email = conditions.delete(:email)
      where(conditions.to_h).where(email: email.downcase).first
    elsif conditions.key?(:email) # Ensure email key is present for other lookups
      where(conditions.to_h).first
    else # Fallback for other conditions if email is not the primary lookup
      where(conditions.to_h).first
    end
  end

  # Checks if the user is an owner or admin of their organization.
  # Currently implemented by checking the 'admin' role from the enum.
  def is_owner_or_admin?
    owner? || admin?
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name   # assuming the user model has a name
      # If you are using confirmable and the provider(s) you use validate emails,
      # uncomment the line below to skip the confirmation emails.
      # user.skip_confirmation!
    end
  end

  # Custom method to accept invitation with password
  def accept_invitation_with_password(params)
    self.password = params[:password]
    self.password_confirmation = params[:password_confirmation]
    self.accept_invitation!
  end

  # Accept invitation without password (for SSO users)
  def accept_invitation_without_password!
    self.password = Devise.friendly_token[0, 20] if encrypted_password.blank?
    self.skip_confirmation! if respond_to?(:skip_confirmation!)
    self.accept_invitation!
  end
end
