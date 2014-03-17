# Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rake secret` to generate a secure secret key.

# Make sure your secret_key_base is kept private
# if you're sharing your code publicly.
Ledger::Application.config.secret_key_base = 'e2550d5d9ff2956d26e004d070392cd6b533286537e2758a5f9b1cbb65a9e5d4ce831384ea3600faea917741284553c7f815a334178f34b6d886e9b45dcf0c6c'
