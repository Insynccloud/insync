class CreateSourcedatabases < ActiveRecord::Migration
  def change
    create_table :sourcedatabases do |t|
          t.string :DBName, default: "VIS"
    t.string :Engine, default: "oracle"
    t.string :MasterUser, default: "gl"
    t.string :MasterUserPassword, default: "gl"
    t.string :Server, default: "ip-172-31-23-251.ap-southeast-2.compute.internal"
    t.string :Port, default: "1521"
    end
  end
end
