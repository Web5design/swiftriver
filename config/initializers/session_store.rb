# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_swift_session',
  :secret      => '7dd3ec47f92b01bfb953fcb9b4071424af3da2c52f2ac57dfd83fab3488d8f2c5596a4533892b1aeea871b813746608c9d24d2503321cb7a67c018a297458225'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
