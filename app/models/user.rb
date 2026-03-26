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

        validates :first_name, presence: true
        validates :last_name, presence: true
        validates :role, inclusion: { in: ROLES }

        def admin?
          role == 'admin'
        end

        def full_name
          "#{first_name} #{last_name}"
        end

end
