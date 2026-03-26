class CreateLeads < ActiveRecord::Migration[7.1]
  def change
    create_table :leads do |t|
      t.string :company_name, null: false
      t.string :contact_name
      t.string :email
      t.string :phone
      t.string :source, default: 'other'
      t.string :status, default: 'new'
      t.text :notes
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :leads, :status
    add_index :leads, :source
  end
end
