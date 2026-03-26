class CreateRevenueEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :revenue_entries do |t|
      t.string :title, null: false
      t.decimal :amount, precision: 12, scale: 2
      t.string :source, default: 'manual'
      t.integer :source_id
      t.string :status, default: 'pending'
      t.date :date
      t.text :notes
      t.decimal :salary_pct, precision: 5, scale: 2
      t.decimal :ops_pct, precision: 5, scale: 2
      t.decimal :profit_pct, precision: 5, scale: 2
      t.decimal :salary_amount, precision: 12, scale: 2
      t.decimal :ops_amount, precision: 12, scale: 2
      t.decimal :profit_amount, precision: 12, scale: 2
      t.references :user, null: false, foreign_key: true
      t.references :deal, null: false, foreign_key: true

      t.timestamps
    end

    add_index :revenue_entries, [:user_id, :date]
    add_index :revenue_entries, :status
  end
end
