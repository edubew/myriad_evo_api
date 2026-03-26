class AllocationSetting < ApplicationRecord
  belongs_to :user

  validates :salary_pct, :ops_pct, :profit_pct,
    numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100
    }

  validate :percentages_sum_to_100

  private

  def percentages_sum_to_100
    total = (salary_pct || 0) + (ops_pct || 0) + (profit_pct || 0)
    unless total.round(2) == 100.0
      errors.add(:base, "Percentages must add up to 100 (currently #{total.round(1)}%)")
    end
  end
end
