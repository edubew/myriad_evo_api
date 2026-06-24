module Invoices
  class CreateInvoiceService < ApplicationService
    def initialize(company:, user:, params:)
      @company = company
      @user    = user
      @params  = params
    end

    def call
      invoice = @company.invoices.build(@params.merge(user: @user))
      invoice.invoice_number = generate_invoice_number!

      if invoice.save
        success(invoice)
      else
        failure(invoice.errors.full_messages)
      end
    end

    private

    def generate_invoice_number!
      year = Date.today.year
      # Atomic increment using PostgreSQL advisory lock
      # Ensures no two invoices in the same company get the same number
      result = ActiveRecord::Base.connection.execute(
        "SELECT pg_advisory_xact_lock(#{@company.id})"
      )
      count = @company.invoices
        .where("invoice_number LIKE ?", "INV-#{year}-%")
        .count + 1
      "INV-#{year}-#{@company.id}-#{count.to_s.rjust(4, '0')}"
    end
  end
end