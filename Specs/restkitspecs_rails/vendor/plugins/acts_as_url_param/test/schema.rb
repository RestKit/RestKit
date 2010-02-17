ActiveRecord::Schema.define() do
  create_table :authors do |t|
    t.column :label, :string
    t.column :bio, :string
    t.column :url_name, :string
  end
  
  create_table :blog_posts do |t|
    t.column :title, :string
    t.column :url_name, :string
  end
  
  create_table :items do |t|
    t.column :name, :string
    t.column :content, :string
    t.column :type, :string, :default => 'Item', :null => false
    t.column :scope_by_id, :integer
    t.column :url_name, :string
  end
  
  create_table :redirects do |t|
    t.column :redirectable_type, :string
    t.column :redirectable_id, :integer
    t.column :redirectable_class, :string
    t.column :url_name, :string
    t.column :created_at, :timestamp
  end
  
  create_table :stories do |t|
    t.column :title, :string
    t.column :story_url, :string
  end
  
  create_table :users do |t|
    t.column :name, :string
    t.column :login, :string
    t.column :url_name, :string
  end
end
