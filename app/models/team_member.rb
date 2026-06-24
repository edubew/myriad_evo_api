class TeamMember < ApplicationRecord
  belongs_to :company
  belongs_to :created_by, class_name: 'User', foreign_key: :user_id

  # Optional link to a real User account
  belongs_to :user_account, class_name: 'User',
             foreign_key: :linked_user_id, optional: true

  validates :first_name, :last_name, presence: true
end