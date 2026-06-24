class CreateCompanyMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :company_memberships do |t|
      t.references :user,    null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.string     :role,    null: false, default: 'member'
      t.datetime   :invited_at
      t.datetime   :accepted_at
      t.string     :invited_by_id
      t.timestamps
    end
    add_index :company_memberships, [:user_id, :company_id], unique: true
  end
end