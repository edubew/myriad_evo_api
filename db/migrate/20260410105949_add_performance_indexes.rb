class AddPerformanceIndexes < ActiveRecord::Migration[7.1]
  def change
    add_index :projects,        :company_id unless index_exists?(:projects, :company_id)
    add_index :clients,         :company_id unless index_exists?(:clients, :company_id)
    add_index :events,          :company_id unless index_exists?(:events, :company_id)
    add_index :deals,           :company_id unless index_exists?(:deals, :company_id)
    add_index :leads,           :company_id unless index_exists?(:leads, :company_id)
    add_index :tasks,           :company_id unless index_exists?(:tasks, :company_id)
    add_index :team_members,    :company_id unless index_exists?(:team_members, :company_id)
    add_index :goals,           :company_id unless index_exists?(:goals, :company_id)
    add_index :documents,       :company_id unless index_exists?(:documents, :company_id)
    add_index :revenue_entries, :company_id unless index_exists?(:revenue_entries, :company_id)
    add_index :invoices,        :company_id unless index_exists?(:invoices, :company_id)
    add_index :daily_todos,     [:user_id, :date]  unless index_exists?(:daily_todos, [:user_id, :date])
    add_index :tasks,           [:project_id, :status] unless index_exists?(:tasks, [:project_id, :status])
    add_index :events,          :start_time unless index_exists?(:events, :start_time)
    add_index :deals,           [:company_id, :status] unless index_exists?(:deals, [:company_id, :status])
    add_index :projects,        [:company_id, :status] unless index_exists?(:projects, [:company_id, :status])
  end
end