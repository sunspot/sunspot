# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_mock_app_session',
  :secret      => 'a2ddf56c7d642f2075a5d466eff55556c20d13415aff5156740ac82848c3c586711fde0e52f4834727816d08b2d13f3da7b6c7587d789cebe6081ee1a7fec943'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
