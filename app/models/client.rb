class Client < ApplicationRecord
  belongs_to :user
  has_many :contacts, dependent: :destroy

  STATUSES = %w[active inactive prospect].freeze
  INDUSTRIES = %w[
    Technology Finance Healthcare Education
    Retail Manufacturing Consulting Media Other
  ].freeze

  validates :company_name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :email, format: {
    with: URI::MailTo::EMAIL_REGEXP
  }, allow_blank: true

  scope :active,    -> { where(status: 'active') }
  scope :search,    ->(q) {
    where('company_name ILIKE ?', "%#{q}%")
  }

  def primary_contact
    contacts.find_by(is_primary: true) || contacts.first
  end

  def initials
    company_name.split.first(2).map(&:first).join.upcase
  end
end
