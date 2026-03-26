class CreateDeals < ActiveRecord::Migration[7.1]
  def change
    create_table :deals do |t|
      t.string :title, null: false
      t.decimal :value, precision: 12, scale: 2, default: 0
      t.integer :probability, default: 0
      t.date :expected_close
      t.string :status, default: 'lead'
      t.text :notes
      t.integer    :position, default: 0
      t.references :user, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true

      t.timestamps
    end

    add_index :deals, :status
    add_index :deals, [:status, :position]
  end
end
