class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.text :description
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.boolean :all_day, default: false
      t.string :location
      t.string :event_type, default: 'meeting'
      t.string :color
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :events, :start_time
    add_index :events, :event_type
  end
end
