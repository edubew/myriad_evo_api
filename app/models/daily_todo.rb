class DailyTodo < ApplicationRecord
  belongs_to :user

  validates :text, presence: true
  validates :date, presence: true

  scope :for_today, -> { where(date: Date.today) }
  scope :ordered,   -> { order(:position, :created_at) }
end
