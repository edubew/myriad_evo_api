class CreateInvoices < ActiveRecord::Migration[7.1]
  def change
    create_table :invoices do |t|
      t.string   :invoice_number, null: false
      t.string   :title, null: false
      t.decimal  :amount, precision: 12, scale: 2
      t.decimal  :tax_rate, precision: 5,  scale: 2, default: 0
      t.decimal  :tax_amount, precision: 12, scale: 2, default: 0
      t.decimal  :total_amount, precision: 12, scale: 2
      t.string   :status, default: 'draft'
      t.date     :issued_date
      t.date     :due_date
      t.date     :paid_date
      t.text     :notes
      t.references :client, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :invoices, :invoice_number, unique: true
    add_index :invoices, :status
  end
end