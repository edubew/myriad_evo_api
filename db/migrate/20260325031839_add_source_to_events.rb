class AddSourceToEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :source, :string, default: 'manual'
    add_column :events, :source_id, :integer

    add_index :events, [:source, :source_id]
  end
end
