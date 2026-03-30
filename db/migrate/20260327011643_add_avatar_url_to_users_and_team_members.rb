class AddAvatarUrlToUsersAndTeamMembers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :avatar_url, :string
    add_column :team_members, :avatar_url, :string
  end
end
