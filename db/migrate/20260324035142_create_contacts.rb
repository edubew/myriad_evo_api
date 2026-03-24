class CreateContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :contacts do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email
      t.string :phone
      t.string :role
      t.boolean :is_primary, default: false
      t.references :client, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :contacts, :client_id, if_not_exists: true
  end
end
