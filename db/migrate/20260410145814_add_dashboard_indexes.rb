class AddDashboardIndexes < ActiveRecord::Migration[7.1]
  def change
    add_index :projects, :status unless index_exists?(:projects, :status)
    add_index :projects, :end_date unless index_exists?(:projects, :end_date)

    add_index :tasks, :status unless index_exists?(:tasks, :status)
    add_index :tasks, :due_date unless index_exists?(:tasks, :due_date)

    add_index :clients, :company_id unless index_exists?(:clients, :company_id)
    add_index :deals, :company_id unless index_exists?(:deals, :company_id)
    add_index :events, :company_id unless index_exists?(:events, :company_id)
  end
end