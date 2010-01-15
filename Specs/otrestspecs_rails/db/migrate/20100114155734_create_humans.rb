class CreateHumans < ActiveRecord::Migration
  def self.up
    create_table :humans do |t|
      t.string :name
      t.string :nick_name
      t.date :birthday
      t.string :sex
      t.integer :age

      t.timestamps
    end
  end

  def self.down
    drop_table :humans
  end
end
