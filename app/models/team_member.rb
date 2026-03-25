class TeamMember < ApplicationRecord
  belongs_to :user

  DEPARTMENTS = %w[
    Engineering Design Product Sales
    Marketing Finance Operations Other
  ].freeze

  validates :first_name, presence: true
  validates :last_name,  presence: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def initials
    "#{first_name[0]}#{last_name[0]}".upcase
  end
end
