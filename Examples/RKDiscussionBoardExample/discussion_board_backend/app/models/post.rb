class Post < ActiveRecord::Base
  has_attached_file :attachment, :default_url => "" # no default attachment.
  belongs_to :user
  belongs_to :topic
  
  def attachment_path
    attachment.url
  end
  
end
