class Post < ActiveRecord::Base
  @paperclip_options = Rails.env.production? ? {:storage => :s3,
     :path => ":attachment/:id/:style/:basename.:extension",
     :url => ":attachment/:id/:style/:basename.:extension",
     :s3_credentials => "#{ Rails.root }/config/s3.yml",
     :bucket => 'DiscussionBoard'} : {}
  
  has_attached_file :attachment, { :default_url => "" }.merge(@paperclip_options)
  
  belongs_to :user
  belongs_to :topic
  
  delegate :username, :to => :user
  
  def attachment_path
    attachment.url
  end  
end
