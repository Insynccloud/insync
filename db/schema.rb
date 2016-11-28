# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161127212128) do

  create_table "sourcedatabases", force: :cascade do |t|
    t.string   "DBName",             default: "VIS"
    t.string   "Engine",             default: "oracle"
    t.string   "MasterUser",         default: "gl"
    t.string   "MasterUserPassword", default: "gl"
    t.string   "Server",             default: "ip-172-31-23-251.ap-southeast-2.compute.internal"
    t.string   "Port",               default: "1521"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "targetdatabases", force: :cascade do |t|
    t.string   "ec2id",                  default: "i-0bc0310d62b458b8e"
    t.string   "DBName",                 default: "test30"
    t.string   "DBInstanceIdentifier",   default: "test30"
    t.string   "MasterUsername",         default: "adam"
    t.string   "MasterUserPassword",     default: "Glad5t0ne"
    t.integer  "AllocatedStorage",       default: 10
    t.string   "Engine",                 default: "postgres"
    t.integer  "BackupRetentionPeriod",  default: 0
    t.boolean  "PubliclyAccessible",     default: true
    t.string   "LicenseModel",           default: "postgresql-license"
    t.string   "StorageType",            default: "standard"
    t.string   "SecurityGroupID",        default: "sg-33046c57"
    t.string   "DBInstanceClass",        default: "db.t2.micro"
    t.string   "VpcId",                  default: "vpc-cb674aae"
    t.string   "SubnetAvailabilityZone", default: "ap-southeast-2a"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
