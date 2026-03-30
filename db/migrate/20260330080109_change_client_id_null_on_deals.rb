class ChangeClientIdNullOnDeals < ActiveRecord::Migration[7.1]
  def change
    change_column_null :deals, :client_id, true
  end
end
