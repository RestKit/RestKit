# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_otrest_specs_session',
  :secret      => '0833a183b179f801e6d12a0988df4f4513d45163fb08445b8d40e9bee01d1bf05583bb6e08610123ec0ada41519ad36451ed0ebd75c2390ce389a9bd5410641a'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
