class RevenueEntry < ApplicationRecord
  belongs_to :user
  belongs_to :company
  belongs_to :deal, optional: true

  SOURCES  = %w[manual deal].freeze
  STATUSES = %w[pending paid].freeze

  validates :title, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :source, inclusion: { in: SOURCES }
  validates :status, inclusion: { in: STATUSES }

  validate :percentages_sum_to_100

  before_save :calculate_allocations

  scope :paid, -> { where(status: 'paid') }
  scope :for_month, ->(date) {
    where(date: date.beginning_of_month..date.end_of_month)
  }
  scope :for_year, ->(year) {
    where(date: Date.new(year).beginning_of_year..Date.new(year).end_of_year)
  }

  def total_allocated
    (salary_amount || 0) + (ops_amount || 0) + (profit_amount || 0)
  end

  private

  def percentages_sum_to_100
    total = (salary_pct || 0) + (ops_pct || 0) + (profit_pct || 0)
    unless total.round(2) == 100.0
      errors.add(:base, "Percentages must add up to 100")
    end
  end

  def calculate_allocations
    return unless amount.present?
    self.salary_amount = (amount * salary_pct / 100).round(2)
    self.ops_amount = (amount * ops_pct    / 100).round(2)
    self.profit_amount = (amount * profit_pct / 100).round(2)
  end
end
