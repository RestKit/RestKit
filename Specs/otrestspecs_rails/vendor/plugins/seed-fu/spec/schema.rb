ActiveRecord::Schema.define :version => 0 do
  create_table :seeded_models, :force => true do |t|
    t.column :login, :string
    t.column :first_name, :string
    t.column :last_name, :string
    t.column :title, :string
  end
end
