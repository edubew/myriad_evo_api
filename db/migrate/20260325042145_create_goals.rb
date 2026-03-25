class CreateGoals < ActiveRecord::Migration[7.1]
  def change
    create_table :goals do |t|
      t.string :title, null: false
      t.text :description
      t.date :target_date
      t.integer :progress, default: 0
      t.string :status, default: 'active'
      t.string :quarter
      t.integer :year
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :goals, [:year, :quarter]
  end
end
