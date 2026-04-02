class TeamMember < ApplicationRecord
  belongs_to :user
  belongs_to :company

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

  require 'digest'

  def avatar
    return avatar_url if avatar_url.present?
    return nil unless email.present?
    hash = Digest::MD5.hexdigest(email.downcase.strip)
    "https://www.gravatar.com/avatar/#{hash}?s=200&d=identicon"
  end
end
