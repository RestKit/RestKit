class CreateResidents < ActiveRecord::Migration
  def self.up
    create_table :residents do |t|
      t.integer :house_id
      t.string :resideable_type
      t.integer :resideable_id

      t.timestamps
    end
  end

  def self.down
    drop_table :residents
  end
end
