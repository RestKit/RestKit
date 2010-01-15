class CreateCats < ActiveRecord::Migration
  def self.up
    create_table :cats do |t|
      t.string :name
      t.string :nick_name
      t.integer :birth_year
      t.integer :age
      t.string :sex
      t.string :color
      t.integer :human_id

      t.timestamps
    end
  end

  def self.down
    drop_table :cats
  end
end
