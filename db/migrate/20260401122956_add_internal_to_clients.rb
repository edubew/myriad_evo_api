class AddInternalToClients < ActiveRecord::Migration[7.1]
  def change
    add_column :clients, :internal, :boolean
  end
end
