class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :jwt_authenticatable, jwt_revocation_strategy: self

        #  Roles
        ROLES = %w[admin member].freeze
        has_many :clients
        has_many :events, dependent: :destroy
        has_many :projects
        has_many :daily_todos, dependent: :destroy
        has_many :deals, dependent: :destroy
        has_one  :allocation_setting
        has_many :revenue_entries
        has_many :invoices
        has_many :team_members
        has_many :goals
        has_many :documents
        has_many :leads

        validates :first_name, presence: true
        validates :last_name, presence: true
        validates :role, inclusion: { in: ROLES }

        def admin?
          role == 'admin'
        end

        def full_name
          "#{first_name} #{last_name}"
        end

        require 'digest'

        def avatar
          return avatar_url if avatar_url.present?
          hash = Digest::MD5.hexdigest(email.downcase.strip)
          "https://www.gravatar.com/avatar/#{hash}?s=200&d=identicon"
        end

end
