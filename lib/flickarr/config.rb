require 'fileutils'
require 'yaml'

module Flickarr
  class Config
    DEFAULT_LIBRARY_PATH = File.join(Dir.home, 'Pictures', 'Flickarr').freeze

    attr_accessor :access_secret, :access_token, :api_key, :last_page_photos, :last_page_posts, :last_page_videos,
                  :latest_version, :latest_version_checked_at, :library_path, :shared_secret,
                  :total_collections, :total_photos, :total_sets, :total_videos,
                  :user_nsid, :username

    def initialize
      @access_secret = nil
      @access_token = nil
      @api_key = ENV.fetch('FLICKARR_API_KEY', nil)
      @last_page_photos = nil
      @last_page_posts = nil
      @last_page_videos = nil
      @latest_version = nil
      @latest_version_checked_at = nil
      @library_path = DEFAULT_LIBRARY_PATH
      @shared_secret = ENV.fetch('FLICKARR_SHARED_SECRET', nil)
      @total_collections = nil
      @total_photos = nil
      @total_sets = nil
      @total_videos = nil
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
        access_secret:             access_secret,
        access_token:              access_token,
        api_key:                   api_key,
        last_page_photos:          last_page_photos,
        last_page_posts:           last_page_posts,
        last_page_videos:          last_page_videos,
        latest_version:            latest_version,
        latest_version_checked_at: latest_version_checked_at,
        library_path:              library_path,
        shared_secret:             shared_secret,
        total_collections:         total_collections,
        total_photos:              total_photos,
        total_sets:                total_sets,
        total_videos:              total_videos,
        user_nsid:                 user_nsid,
        username:                  username
      }
    end

    def self.load path
      config = new
      return config unless File.exist?(path)

      yaml = YAML.load_file(path, symbolize_names: true)
      return config unless yaml.is_a?(Hash)

      config.access_secret              = yaml[:access_secret]              if yaml[:access_secret]
      config.access_token               = yaml[:access_token]               if yaml[:access_token]
      config.api_key                    = yaml[:api_key]                    if yaml[:api_key]
      config.last_page_photos           = yaml[:last_page_photos]           if yaml[:last_page_photos]
      config.last_page_posts            = yaml[:last_page_posts]            if yaml[:last_page_posts]
      config.last_page_videos           = yaml[:last_page_videos]           if yaml[:last_page_videos]
      config.latest_version             = yaml[:latest_version]             if yaml[:latest_version]
      config.latest_version_checked_at  = yaml[:latest_version_checked_at]  if yaml[:latest_version_checked_at]
      config.library_path               = yaml[:library_path]               if yaml[:library_path]
      config.shared_secret              = yaml[:shared_secret]              if yaml[:shared_secret]
      config.total_collections          = yaml[:total_collections]          if yaml[:total_collections]
      config.total_photos               = yaml[:total_photos]               if yaml[:total_photos]
      config.total_sets                 = yaml[:total_sets]                 if yaml[:total_sets]
      config.total_videos               = yaml[:total_videos]               if yaml[:total_videos]
      config.user_nsid                  = yaml[:user_nsid]                  if yaml[:user_nsid]
      config.username                   = yaml[:username]                   if yaml[:username]

      config
    end
  end
end
