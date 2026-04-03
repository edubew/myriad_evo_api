namespace :setup do
  desc "Create internal clients for all users"
  task internal_clients: :environment do
    User.find_each do |user|
      Client.find_or_create_by!(
        company_name: "Myriad Evo (Internal)",
        user: user,
        company: user.company
      ) do |client|
        client.status = "active"
        client.internal = true
      end
    end
  end
end