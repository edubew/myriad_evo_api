class Invoice < ApplicationRecord
  belongs_to :client, optional: true
  belongs_to :user
  belongs_to :company

  STATUSES = %w[draft sent paid overdue cancelled].freeze

  validates :title, presence: true
  validates :invoice_number, presence: true,
            uniqueness: { scope: :company_id, message: 'already exists for this company' }
  validates :amount, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }

  before_validation :generate_invoice_number, on: :create
  before_save :calculate_tax_and_total

  scope :paid, -> { where(status: 'paid') }
  scope :pending, -> { where(status: %w[sent overdue]) }
  scope :overdue, -> {
    where(status: 'sent')
      .where('due_date < ?', Date.today)
  }

  def overdue?
    status == 'sent' && due_date.present? && due_date < Date.today
  end

  def days_until_due
    return nil unless due_date
    (due_date - Date.today).to_i
  end

  private

  def generate_invoice_number
    year = Date.today.year

    ActiveRecord::Base.connection.execute(
      "SELECT pg_advisory_xact_lock(#{company_id.to_i})"
    )

    count = company.invoices
              .where('invoice_number LIKE ?', "INV-#{year}-#{company_id}-%")
              .count + 1

    self.invoice_number = "INV-#{year}-#{company_id}-#{count.to_s.rjust(4, '0')}"
  end

  def calculate_tax_and_total
    self.tax_amount   = ((amount || 0) * (tax_rate || 0) / 100).round(2)
    self.total_amount = ((amount || 0) + tax_amount).round(2)
  end
end