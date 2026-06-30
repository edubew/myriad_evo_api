class FixInvoiceNumberIndex < ActiveRecord::Migration[7.1]
  def up
    remove_index :invoices,
                 name:   'index_invoices_on_invoice_number',
                 column: :invoice_number


    add_index :invoices,
              [:company_id, :invoice_number],
              unique: true,
              name:   'index_invoices_on_company_and_number'
  end

  def down
    remove_index :invoices,
                 name: 'index_invoices_on_company_and_number'

    add_index :invoices,
              :invoice_number,
              unique: true,
              name:   'index_invoices_on_invoice_number'
  end
end
