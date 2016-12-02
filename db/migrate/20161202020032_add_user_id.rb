class AddUserId < ActiveRecord::Migration
  def change
   add_column :sourcedatabases, :user_id, :integer
  end
end
