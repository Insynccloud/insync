class AddTimestampToSourcedatabases < ActiveRecord::Migration
  def change
    add_column :sourcedatabases, :created_at, :datetime 
    add_column :sourcedatabases, :updated_at, :datetime
  end
end
