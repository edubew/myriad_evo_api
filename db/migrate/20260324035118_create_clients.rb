class CreateClients < ActiveRecord::Migration[7.1]
  def change
    create_table :clients do |t|
      t.string :company_name, null: false
      t.string :industry
      t.string :website
      t.string :email
      t.string :phone
      t.string :status, default: 'active'
      t.text :notes
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :clients, :company_name
    add_index :clients, :status
  end
end
