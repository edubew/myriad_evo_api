class Lead < ApplicationRecord
  belongs_to :user

  STATUSES = %w[new contacted qualified disqualified].freeze
  SOURCES  = %w[
    website referral social_media
    cold_outreach event other
  ].freeze

  validates :company_name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :source, inclusion: { in: SOURCES }

  scope :search, ->(q) {
    where(
      'company_name ILIKE ? OR contact_name ILIKE ?',
      "%#{q}%", "%#{q}%"
    )
  }
end
