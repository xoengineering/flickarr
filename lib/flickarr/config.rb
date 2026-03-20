require 'fileutils'
require 'yaml'

module Flickarr
  class Config
    DEFAULT_LIBRARY_PATH = File.join(Dir.home, 'Pictures', 'Flickarr').freeze

    attr_accessor :access_secret, :access_token, :api_key, :last_export_page, :library_path, :shared_secret, :user_nsid,
                  :username

    def initialize
      @access_secret = nil
      @access_token = nil
      @api_key = ENV.fetch('FLICKARR_API_KEY', nil)
      @last_export_page = nil
      @library_path = DEFAULT_LIBRARY_PATH
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

    def archive_path
      return nil if username.nil? || username.empty?

      File.join library_path, username
    end

    def to_h
      {
        access_secret:    access_secret,
        access_token:     access_token,
        api_key:          api_key,
        last_export_page: last_export_page,
        library_path:     library_path,
        shared_secret:    shared_secret,
        user_nsid:        user_nsid,
        username:         username
      }
    end

    def self.load path
      config = new
      return config unless File.exist?(path)

      yaml = YAML.load_file(path, symbolize_names: true)
      return config unless yaml.is_a?(Hash)

      config.access_secret    = yaml[:access_secret]    if yaml[:access_secret]
      config.access_token     = yaml[:access_token]     if yaml[:access_token]
      config.api_key          = yaml[:api_key]          if yaml[:api_key]
      config.last_export_page = yaml[:last_export_page] if yaml[:last_export_page]
      config.library_path     = yaml[:library_path]     if yaml[:library_path]
      config.shared_secret    = yaml[:shared_secret]    if yaml[:shared_secret]
      config.user_nsid        = yaml[:user_nsid]        if yaml[:user_nsid]
      config.username         = yaml[:username]         if yaml[:username]

      config
    end
  end
end
