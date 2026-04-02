class Company < ApplicationRecord
  has_many :users
  has_many :projects
  has_many :clients
  has_many :events
  has_many :deals
  has_many :leads
  has_many :tasks, through: :projects
  has_many :team_members
  has_many :goals
  has_many :documents
  has_many :revenue_entries
  has_many :invoices
  has_many :daily_todos
  has_many :contacts, through: :clients
  has_one  :allocation_setting

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    self.slug ||= name.to_s.downcase.gsub(/[^a-z0-9]+/, '-').strip
  end
end
