class CreatePosts < ActiveRecord::Migration
  def self.up
    create_table :posts do |t|
      t.text :body
      t.integer :user_id
      t.integer :topic_id
      t.string :attachment_file_name
      t.string :attachment_content_type
      t.integer :attachment_file_size
      t.datetime :attachment_updated_at

      t.timestamps
    end
  end

  def self.down
    drop_table :posts
  end
end
