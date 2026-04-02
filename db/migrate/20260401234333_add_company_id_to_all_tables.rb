class AddCompanyIdToAllTables < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :company, foreign_key: true
    add_reference :projects, :company, foreign_key: true
    add_reference :clients, :company, foreign_key: true
    add_reference :events, :company, foreign_key: true
    add_reference :deals,  :company, foreign_key: true
    add_reference :leads,  :company, foreign_key: true
    add_reference :tasks,  :company, foreign_key: true
    add_reference :team_members, :company, foreign_key: true
    add_reference :goals, :company, foreign_key: true
    add_reference :documents, :company, foreign_key: true
    add_reference :revenue_entries, :company, foreign_key: true
    add_reference :invoices, :company, foreign_key: true
    add_reference :daily_todos, :company, foreign_key: true
    add_reference :allocation_settings, :company, foreign_key: true
    add_reference :contacts, :company, foreign_key: true
  end
end
