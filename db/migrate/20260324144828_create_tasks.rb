class CreateTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.string :status, default: 'backlog'
      t.string :priority, default: 'medium'
      t.integer :position, default: 0
      t.date :due_date
      t.references :user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.references :assignee,  foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :tasks, [:project_id, :status]
    add_index :tasks, [:project_id, :position]
  end
end
