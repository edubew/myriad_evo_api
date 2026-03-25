class CreateDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :documents do |t|
      t.string :title, null: false
      t.text :description
      t.string :file_url
      t.string :file_name
      t.integer :file_size
      t.string :file_type
      t.string :category, default: 'general'
      t.references :user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true

      t.timestamps
    end

    add_index :documents, :category
  end
end
