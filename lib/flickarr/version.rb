require 'json'
require 'net/http'
require 'uri'

module Flickarr
  VERSION = '0.1.7'.freeze

  class Version
    RUBYGEMS_URL = 'https://rubygems.org/api/v1/gems/flickarr.json'.freeze
    CACHE_TTL_SECONDS = 86_400 # 1 day

    def initialize config
      @config = config
    end

    def check
      fetch_latest if stale?
      @config.latest_version
    end

    def stale?
      return true if @config.latest_version_checked_at.nil?

      last_check = Time.parse(@config.latest_version_checked_at.to_s)
      Time.now - last_check > CACHE_TTL_SECONDS
    rescue ArgumentError
      true
    end

    def update_available?
      latest = check
      return false unless latest

      Gem::Version.new(latest) > Gem::Version.new(Flickarr::VERSION)
    rescue ArgumentError
      false
    end

    def update_message
      latest = check
      return nil unless latest

      if Gem::Version.new(latest) > Gem::Version.new(Flickarr::VERSION)
        "Update available: #{latest} (current: #{Flickarr::VERSION}) — run `gem update flickarr`"
      end
    rescue ArgumentError
      nil
    end

    private

    def fetch_latest
      uri      = URI(RUBYGEMS_URL)
      response = Net::HTTP.get_response(uri)
      return unless response.is_a?(Net::HTTPSuccess)

      data    = JSON.parse(response.body)
      version = data['version']

      @config.latest_version            = version
      @config.latest_version_checked_at = Time.now.iso8601
      version
    rescue StandardError
      nil
    end
  end
end
