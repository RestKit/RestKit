# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100114163330) do

  create_table "cats", :force => true do |t|
    t.string   "name"
    t.string   "nick_name"
    t.integer  "birth_year"
    t.integer  "age"
    t.string   "sex"
    t.string   "color"
    t.integer  "human_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "houses", :force => true do |t|
    t.string   "street"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.integer  "owner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "humans", :force => true do |t|
    t.string   "name"
    t.string   "nick_name"
    t.date     "birthday"
    t.string   "sex"
    t.integer  "age"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "residents", :force => true do |t|
    t.integer  "house_id"
    t.string   "resideable_type"
    t.integer  "resideable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
