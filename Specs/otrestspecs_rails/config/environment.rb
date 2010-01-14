# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.gem 'bullet', :source => 'http://gemcutter.org', :version => '1.7.3'
  config.gem 'paperclip', :lib => 'paperclip', :source => 'http://gemcutter.org', :version => '2.3.1.1'
  config.gem 'nokogiri', :version => '1.4.1'
  config.gem 'alexdunae-validates_email_format_of', :lib => 'validates_email_format_of', :version => '1.4'
  config.gem 'will_paginate', :lib => 'will_paginate', :source => 'http://gemcutter.org', :version => '2.3.11'
  config.gem 'configatron', :version => '2.5.1'
  config.gem 'bcrypt-ruby', :lib => 'bcrypt', :version => '2.1.2'
  config.gem 'aasm', :lib => 'aasm', :source => 'http://gemcutter.org', :version => '2.1.3'
  config.gem 'authlogic', :version => '2.1.2'
  config.gem 'Objective3-resource_controller_extensions', :lib => false, :version => '0.0.2'
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
  
  # Pull in JSON and XML support for ResourceController
  config.after_initialize do
    require 'resource_controller_extensions/xml'
    require 'resource_controller_extensions/json'
  end
end
