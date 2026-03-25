class CreateTeamMembers < ActiveRecord::Migration[7.1]
  def change
    create_table :team_members do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email
      t.string :phone
      t.string :role
      t.string :department
      t.text :bio
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
