class CreateHouses < ActiveRecord::Migration
  def self.up
    create_table :houses do |t|
      t.string :street
      t.string :city
      t.string :state
      t.string :zip
      t.integer :owner_id

      t.timestamps
    end
  end

  def self.down
    drop_table :houses
  end
end
