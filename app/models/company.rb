class Company < ApplicationRecord
  PLANS = %w[starter growth enterprise].freeze

  has_many :users,              dependent: :destroy
  has_many :company_memberships,dependent: :destroy
  has_many :clients,            dependent: :destroy
  has_many :contacts,           through: :clients
  has_many :projects,           dependent: :destroy
  has_many :tasks,              through: :projects
  has_many :events,             dependent: :destroy
  has_many :deals,              dependent: :destroy
  has_many :leads,              dependent: :destroy
  has_many :invoices,           dependent: :destroy
  has_many :revenue_entries,    dependent: :destroy
  has_many :documents,          dependent: :destroy
  has_many :goals,              dependent: :destroy
  has_many :team_members,       dependent: :destroy
  has_many :daily_todos,        dependent: :destroy
  has_one  :allocation_setting, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :plan, inclusion: { in: PLANS }

  before_validation :generate_slug, on: :create

  def scoped_clients    = clients.includes(:contacts)
  def scoped_projects   = projects.includes(:tasks, :client)
  def scoped_deals      = deals.includes(:client)
  def scoped_invoices   = invoices.includes(:client)

  private

  def generate_slug
    base = name.to_s.downcase.gsub(/[^a-z0-9]+/, '-').strip
    self.slug ||= base
    counter = 1
    while Company.where(slug: self.slug).where.not(id: id).exists?
      self.slug = "#{base}-#{counter}"
      counter += 1
    end
  end
end