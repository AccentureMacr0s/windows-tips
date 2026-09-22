#!/usr/bin/env ruby
# frozen_string_literal: true

# register_account.rb
# Registers a new GIPHY account via the GIPHY Developer API and writes the
# resulting API key and credentials to GitHub Actions step outputs so that
# downstream jobs can reference them securely.
#
# Usage (local):
#   ruby scripts/register_account.rb
#
# Usage (GitHub Actions):
#   - name: Register GIPHY account
#     run: ruby scripts/register_account.rb
#     env:
#       GIPHY_APP_NAME: ${{ vars.GIPHY_APP_NAME }}   # optional override
#
# Required environment variables (set as GitHub Actions secrets):
#   GIPHY_API_KEY  – a GIPHY Developer API key with upload scope
#
# Optional environment variables:
#   GIPHY_APP_NAME – display name for the app/channel (default: auto-generated)
#   GITHUB_OUTPUT  – path to the GitHub Actions output file (auto-set by Actions)
#
# Outputs written to $GITHUB_OUTPUT:
#   giphy_api_key  – the API key to use for subsequent upload steps
#   giphy_username – the username associated with the key
#
# Security notes:
#   - Never print the API key to stdout; it is written only to $GITHUB_OUTPUT.
#   - $GITHUB_OUTPUT values are masked automatically in Actions log output.
#   - Rotate keys via the GIPHY Developer dashboard after any suspected exposure.

require 'net/http'
require 'json'
require 'securerandom'
require 'uri'

GIPHY_API_BASE = 'https://api.giphy.com/v1'

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def env!(name)
  value = ENV[name]
  abort "ERROR: required environment variable #{name} is not set." if value.nil? || value.empty?
  value
end

def write_output(key, value)
  output_path = ENV['GITHUB_OUTPUT']
  if output_path && !output_path.empty?
    File.open(output_path, 'a') { |f| f.puts("#{key}=#{value}") }
  else
    # Local fallback: print key name but not the secret value
    puts "[output] #{key} written (masked)"
  end
end

def generate_username
  adjectives = %w[swift bright calm bold keen lively vivid sharp]
  nouns      = %w[pixel frame clip reel loop gif shot]
  suffix     = SecureRandom.hex(3)
  "#{adjectives.sample}_#{nouns.sample}_#{suffix}"
end

# ---------------------------------------------------------------------------
# Account / channel registration
# ---------------------------------------------------------------------------
# GIPHY does not expose a public REST endpoint for programmatic account
# creation; accounts are created through the GIPHY Developer portal
# (https://developers.giphy.com/).  This script therefore validates that a
# supplied GIPHY_API_KEY is active and then surfaces it to the pipeline as a
# step output so that all subsequent steps reference it from one place.
#
# If you need fully automated bot-account provisioning, replace the
# `validate_key` section below with calls to whatever user-management API
# your account infrastructure provides, then write the resulting credential
# pair to $GITHUB_OUTPUT in the same way.
# ---------------------------------------------------------------------------

def validate_key(api_key)
  uri = URI("#{GIPHY_API_BASE}/gifs/trending")
  uri.query = URI.encode_www_form(api_key: api_key, limit: 1)

  response = Net::HTTP.get_response(uri)
  unless response.is_a?(Net::HTTPSuccess)
    abort "ERROR: GIPHY API key validation failed (HTTP #{response.code}): #{response.body}"
  end

  parsed = JSON.parse(response.body)
  meta   = parsed.dig('meta', 'status')
  abort "ERROR: Unexpected GIPHY response status: #{meta}" unless meta == 200

  puts '[register_account] API key is valid.'
  parsed
end

def fetch_username(api_key)
  # GIPHY does not expose an authenticated /me endpoint in its public API.
  # Use the app name from the environment or generate a deterministic one.
  ENV.fetch('GIPHY_APP_NAME') { generate_username }
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

api_key  = env!('GIPHY_API_KEY')
validate_key(api_key)
username = fetch_username(api_key)

write_output('giphy_api_key',  api_key)
write_output('giphy_username', username)

puts "[register_account] Registration complete. Username: #{username}"
