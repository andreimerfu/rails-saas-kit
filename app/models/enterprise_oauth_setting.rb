class EnterpriseOauthSetting < ApplicationRecord
  belongs_to :organization, foreign_key: :domain, primary_key: :domain, optional: true

  validates :name, presence: true
  validates :domain, presence: true, uniqueness: true
  validates :provider, presence: true
  validates :client_id, presence: true
  validates :client_secret, presence: true
end
