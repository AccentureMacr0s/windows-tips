#!/usr/bin/env ruby
# frozen_string_literal: true

# upload_to_giphy.rb
# Uploads a GIF file to GIPHY using the GIPHY Upload API and writes the
# resulting GIF ID and shareable URL to GitHub Actions step outputs.
#
# Usage (local):
#   ruby scripts/upload_to_giphy.rb
#
# Usage (GitHub Actions):
#   - name: Upload GIF to GIPHY
#     run: ruby scripts/upload_to_giphy.rb
#     env:
#       GIPHY_API_KEY: ${{ steps.register.outputs.giphy_api_key }}
#       GIF_PATH:      output_ios.gif
#       GIF_TAGS:      ${{ steps.tag.outputs.gif_tags }}
#       GIF_SOURCE:    https://github.com/${{ github.repository }}
#
# Required environment variables:
#   GIPHY_API_KEY  – GIPHY Developer API key with upload scope
#   GIF_PATH       – local path to the GIF file to upload
#
# Optional environment variables:
#   GIF_TAGS       – comma-separated tags (max 10, ≤ 30 chars each)
#   GIF_SOURCE     – source URL to attribute with the upload
#   GIF_TITLE      – human-readable title for the GIF
#   GITHUB_OUTPUT  – path to the GitHub Actions output file (auto-set)
#
# Outputs written to $GITHUB_OUTPUT:
#   giphy_gif_id   – the GIPHY GIF identifier
#   giphy_gif_url  – the full GIPHY page URL for the uploaded GIF
#
# Security notes:
#   - The API key is sent only via HTTPS to api.giphy.com.
#   - Keys are never written to stdout; they travel only through env vars.
#   - Use GitHub Actions secrets for GIPHY_API_KEY; never hard-code it.
#   - Rotate keys via https://developers.giphy.com/ if accidentally exposed.

require 'net/http'
require 'net/http/post/multipart'  # gem 'multipart-post'
require 'json'
require 'uri'

GIPHY_UPLOAD_URL = 'https://upload.giphy.com/v1/gifs'
GIPHY_GIF_BASE   = 'https://giphy.com/gifs'

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
    puts "[output] #{key}=#{value}"
  end
end

def validate_tags(raw)
  return '' if raw.nil? || raw.empty?

  tags = raw.split(',').map(&:strip).reject(&:empty?)
  tags = tags.first(10)  # GIPHY max
  tags.each do |tag|
    if tag.length > 30
      abort "ERROR: tag exceeds 30 characters: #{tag.inspect}"
    end
  end
  tags.join(',')
end

# ---------------------------------------------------------------------------
# Upload
# ---------------------------------------------------------------------------

def upload_gif(api_key:, gif_path:, tags:, source:, title:)
  abort "ERROR: GIF file not found: #{gif_path}" unless File.exist?(gif_path)

  size_mb = File.size(gif_path) / (1024.0 * 1024)
  puts "[upload_to_giphy] Uploading #{gif_path} (#{format('%.2f', size_mb)} MB) ..."

  uri = URI(GIPHY_UPLOAD_URL)

  File.open(gif_path, 'rb') do |gif_io|
    form_data = {
      'api_key' => api_key,
      'file'    => UploadIO.new(gif_io, 'image/gif', File.basename(gif_path)),
    }
    form_data['tags']   = tags   unless tags.empty?
    form_data['source'] = source unless source.nil? || source.empty?
    form_data['title']  = title  unless title.nil? || title.empty?

    request  = Net::HTTP::Post::Multipart.new(uri.path, form_data)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      abort "ERROR: GIPHY upload failed (HTTP #{response.code}): #{response.body}"
    end

    parsed = JSON.parse(response.body)
    status = parsed.dig('meta', 'status')
    abort "ERROR: GIPHY returned status #{status}: #{response.body}" unless status == 200

    gif_id  = parsed.dig('data', 'id')
    gif_url = "#{GIPHY_GIF_BASE}/#{gif_id}"
    puts "[upload_to_giphy] Upload successful. GIF ID: #{gif_id}"
    puts "[upload_to_giphy] URL: #{gif_url}"

    [gif_id, gif_url]
  end
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

api_key  = env!('GIPHY_API_KEY')
gif_path = env!('GIF_PATH')
tags     = validate_tags(ENV['GIF_TAGS'])
source   = ENV.fetch('GIF_SOURCE', '')
title    = ENV.fetch('GIF_TITLE',  '')

gif_id, gif_url = upload_gif(
  api_key:  api_key,
  gif_path: gif_path,
  tags:     tags,
  source:   source,
  title:    title,
)

write_output('giphy_gif_id',  gif_id)
write_output('giphy_gif_url', gif_url)

puts '[upload_to_giphy] Done.'
