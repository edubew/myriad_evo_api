class Contact < ApplicationRecord
  belongs_to :client

  validates :first_name, presence: true
  validates :last_name,  presence: true
  validates :email, format: {
    with: URI::MailTo::EMAIL_REGEXP
  }, allow_blank: true

  def full_name
    "#{first_name} #{last_name}"
  end
end
