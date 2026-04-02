class CreateCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :plan, default: 'starter'

      t.timestamps
    end

    add_index :companies, :slug, unique: true
  end
end
