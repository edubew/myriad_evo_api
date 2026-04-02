class Goal < ApplicationRecord
  belongs_to :user
  belongs_to :company

  STATUSES  = %w[active completed cancelled].freeze
  QUARTERS  = %w[Q1 Q2 Q3 Q4].freeze

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :progress, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
  }

  scope :for_quarter, ->(q, y) {
    where(quarter: q, year: y)
  }

  before_validation :set_quarter_and_year, on: :create

  private

  def set_quarter_and_year
    self.year    ||= Date.today.year
    self.quarter ||= "Q#{((Date.today.month - 1) / 3) + 1}"
  end
end
