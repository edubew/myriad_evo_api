class CreateAllocationSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :allocation_settings do |t|
      t.decimal :salary_pct, precision: 5, scale: 2, default: 40.0
      t.decimal :ops_pct, precision: 5, scale: 2, default: 25.0
      t.decimal :profit_pct, precision: 5, scale: 2, default: 35.0
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :allocation_settings, :user_id, unique: true
  end
end
