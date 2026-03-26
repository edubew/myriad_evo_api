class CreateDailyTodos < ActiveRecord::Migration[7.1]
  def change
    create_table :daily_todos do |t|
      t.string :text, null: false
      t.boolean :done, default: false
      t.date :date, null: false
      t.integer :position, default: 0
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :daily_todos, [:user_id, :date]
  end
end
