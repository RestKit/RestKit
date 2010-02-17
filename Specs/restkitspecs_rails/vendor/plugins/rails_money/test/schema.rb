ActiveRecord::Schema.define(:version => 1) do
  
  # Create tables for testing your plugin

   create_table :things do |t|
     t.column :name,   :string
     t.column :price_in_cents, :integer
   end
    
end
