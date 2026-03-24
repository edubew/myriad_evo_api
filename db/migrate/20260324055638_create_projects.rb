class CreateProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :projects do |t|
      t.string :title, null: false
      t.text :description
      t.string :status, default: 'active'
      t.string :color, default: '#6C63FF'
      t.date :start_date
      t.date :end_date
      t.references :user, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true

      t.timestamps
    end

    add_index :projects, :status
  end
end
