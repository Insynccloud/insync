  class CreateTargetdatabases < ActiveRecord::Migration
  def change
    create_table :targetdatabases do |t|
    t.string :ec2id, default: "i-0bc0310d62b458b8e"
    t.string :DBName, default: "test30"
      t.string :DBInstanceIdentifier, default: "test30"
    t.string :MasterUsername, default: "adam"
    t.string :MasterUserPassword, default: "Glad5t0ne"
    t.integer :AllocatedStorage, default: 10
    t.string :Engine, default: "postgres"
    t.integer :BackupRetentionPeriod, default: 0
    t.boolean :PubliclyAccessible, default: true
    t.string :LicenseModel, default: "postgresql-license"
    t.string :StorageType, default: "standard"
    t.string :SecurityGroupID, default: "sg-33046c57"
    t.string :DBInstanceClass, default: "db.t2.micro"
    t.string :VpcId, default: "vpc-cb674aae"
    t.string :SubnetAvailabilityZone, default: "ap-southeast-2a"
    t.datetime :created_at
    t.datetime :updated_at
    end
  end
end
