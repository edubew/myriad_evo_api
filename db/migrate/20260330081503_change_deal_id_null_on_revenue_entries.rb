class ChangeDealIdNullOnRevenueEntries < ActiveRecord::Migration[7.1]
  def change
    change_column_null :revenue_entries, :deal_id, true
  end
end
