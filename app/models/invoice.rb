class Invoice < ApplicationRecord
  belongs_to :client, optional: true
  belongs_to :user

  STATUSES = %w[draft sent paid overdue cancelled].freeze

  validates :title, presence: true
  validates :invoice_number, presence: true, uniqueness: true
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

  def overdue?
    status == 'sent' && due_date.present? && due_date < Date.today
  end

  private

  def generate_invoice_number
    year  = Date.today.year
    count = Invoice.where(
      'invoice_number LIKE ?', "INV-#{year}-%"
    ).count + 1
    self.invoice_number = "INV-#{year}-#{count.to_s.rjust(3, '0')}"
  end

  def calculate_tax_and_total
    self.tax_amount   = ((amount || 0) * (tax_rate || 0) / 100).round(2)
    self.total_amount = ((amount || 0) + tax_amount).round(2)
  end
end
