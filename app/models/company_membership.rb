class CompanyMembership < ApplicationRecord
  belongs_to :user
  belongs_to :company

  ROLES = %w[owner admin member viewer].freeze

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :company_id }

  def owner?  = role == 'owner'
  def admin?  = role.in?(%w[owner admin])
  def member? = role == 'member'
  def viewer? = role == 'viewer'
end