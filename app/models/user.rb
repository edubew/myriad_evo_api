class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  ROLES = %w[owner admin member viewer].freeze

  belongs_to :company
  has_one    :company_membership, dependent: :destroy

  # Owned records (creator)
  has_many :owned_clients,  class_name: 'Client',  foreign_key: :user_id, dependent: :nullify
  has_many :owned_projects, class_name: 'Project', foreign_key: :user_id, dependent: :nullify
  has_many :owned_deals,    class_name: 'Deal',    foreign_key: :user_id, dependent: :nullify
  has_many :owned_leads,    class_name: 'Lead',    foreign_key: :user_id, dependent: :nullify
  has_many :owned_invoices, class_name: 'Invoice', foreign_key: :user_id, dependent: :nullify
  has_many :assigned_tasks, class_name: 'Task',    foreign_key: :assignee_id

  # Personal records
  has_many :daily_todos,      dependent: :destroy
  has_many :revenue_entries,  dependent: :nullify
  has_many :goals,            dependent: :nullify
  has_many :documents,        dependent: :nullify
  has_many :team_members,     dependent: :nullify
  has_many :owned_events,     class_name: 'Event', foreign_key: :user_id, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name,  presence: true
  validates :role,       inclusion: { in: ROLES }

  delegate :can?,    to: :company_membership, allow_nil: true
  delegate :cannot?, to: :company_membership, allow_nil: true

  def owner?  = role == 'owner'
  def admin?  = role.in?(%w[owner admin])
  def member? = role == 'member'
  def viewer? = role == 'viewer'

  def full_name  = "#{first_name} #{last_name}"

  def avatar
    return avatar_url if avatar_url.present?
    hash = Digest::MD5.hexdigest(email.downcase.strip)
    "https://www.gravatar.com/avatar/#{hash}?s=200&d=identicon"
  end
end