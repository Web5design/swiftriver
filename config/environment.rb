# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.2.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

PLATFORM_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/platform.yml")[RAILS_ENV]
SERVER_URL = PLATFORM_CONFIG["url"]
APP_TAG = PLATFORM_CONFIG["tag"]
APP_NAME = PLATFORM_CONFIG["name"]

# Block users who, like our inaug09, are doing aggregation
BLOCKED_TWITTER_USERS = %w(inaug_rss inaug inaug09 pissonobama LGBTtweets)

require 'digest/sha1' #for the md5 session key below

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3"

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )
  config.load_paths += Dir["#{RAILS_ROOT}/app/models/**"]
  config.load_paths += Dir["#{RAILS_ROOT}/vendor/gems/**"].map do |dir|
        File.directory?(lib = "#{dir}/lib") ? lib : dir
  end
  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Comment line to use default local time.
  config.time_zone = 'UTC'
  ENV['TZ'] = 'GMT'

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => "_#{APP_TAG}_session",
    :secret      => Digest::SHA1.hexdigest(SERVER_URL + APP_TAG)[0..34]
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
  
  # config.gem 'mislav-will_paginate', :version => '~> 2.3.2', :lib => 'will_paginate', :source => 'http://gems.github.com'
  # config.gem 'json', :version => '= 1.1.3'
  # config.gem 'GeoRuby', :lib => 'geo_ruby', :version => '>= 1.3.3'
  # config.gem 'haml', :version => ">= 2.0.4"
end
require "will_paginate"
require "json"
require "geo_ruby"
require "haml"
# require "calais"
CALAIS_LICENSE = "w7m26kvqdg37bdweph42n9vx"
ENV['TZ'] = 'UTC'

