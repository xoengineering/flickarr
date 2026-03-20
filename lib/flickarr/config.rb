require 'fileutils'
require 'yaml'

module Flickarr
  class Config
    attr_accessor :access_secret, :access_token, :api_key, :shared_secret, :user_nsid, :username

    def initialize
      @access_secret = nil
      @access_token = nil
      @api_key = ENV.fetch('FLICKARR_API_KEY', nil)
      @shared_secret = ENV.fetch('FLICKARR_SHARED_SECRET', nil)
      @user_nsid = nil
      @username = nil
    end

    def save path
      hash = to_h.transform_keys(&:to_s)
      yaml = YAML.dump hash
      dir  = File.dirname path

      FileUtils.mkdir_p dir
      File.write path, yaml
    end

    def to_h
      {
        access_secret: access_secret,
        access_token:  access_token,
        api_key:       api_key,
        shared_secret: shared_secret,
        user_nsid:     user_nsid,
        username:      username
      }
    end

    def self.load path
      config = new
      return config unless File.exist?(path)

      yaml = YAML.load_file(path, symbolize_names: true)
      return config unless yaml.is_a?(Hash)

      config.access_secret = yaml[:access_secret] if yaml[:access_secret]
      config.access_token  = yaml[:access_token]  if yaml[:access_token]
      config.api_key       = yaml[:api_key]       if yaml[:api_key]
      config.shared_secret = yaml[:shared_secret] if yaml[:shared_secret]
      config.user_nsid     = yaml[:user_nsid]     if yaml[:user_nsid]
      config.username      = yaml[:username]      if yaml[:username]

      config
    end
  end
end
