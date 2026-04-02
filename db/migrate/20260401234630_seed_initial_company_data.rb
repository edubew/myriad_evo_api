class SeedInitialCompanyData < ActiveRecord::Migration[7.1]
  def up
    company = Company.create!(
      name: 'Myriad Evo',
      slug: 'myriad-evo',
      plan: 'starter'
    )

    # Assign all existing users to this company
    User.update_all(company_id: company.id)

    # Migrate all existing data
    [
      Project, Client, Event, Deal, Lead, Task,
      TeamMember, Goal, Document, RevenueEntry, 
      Invoice, DailyTodo, AllocationSetting, Contact
    ].each do |model|
      model.update_all(company_id: company.id)
    end
  end

  def down
    Company.find_by(slug: 'myriad-evo')&.destroy
  end
end
