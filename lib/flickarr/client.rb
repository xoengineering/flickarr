require 'flickr'
require_relative 'client/photo_query'
require_relative 'client/profile_query'

module Flickarr
  class Client
    attr_reader :flickr

    def initialize config
      raise ConfigError, 'api_key is required' if config.api_key.nil? || config.api_key.empty?
      raise ConfigError, 'shared_secret is required' if config.shared_secret.nil? || config.shared_secret.empty?

      @flickr       = Flickr.new config.api_key, config.shared_secret
      @rate_limiter = RateLimiter.new

      return unless config.access_token && config.access_secret

      @flickr.access_token  = config.access_token
      @flickr.access_secret = config.access_secret
    end

    def collections user_id:
      @rate_limiter.track do
        flickr.collections.getTree(user_id: user_id)
      end
    end

    def photo id:
      PhotoQuery.new(flickr: flickr, id: id, rate_limiter: @rate_limiter)
    end

    PHOTO_EXTRAS = %w[
      date_taken
      date_upload
      description
      geo
      icon_server
      last_update
      license
      machine_tags
      media
      o_dims
      original_format
      owner_name
      path_alias
      tags
      url_c
      url_l
      url_m
      url_n
      url_o
      url_q
      url_s
      url_sq
      url_t
      url_z
      views
    ].join(',').freeze

    def photos user_id:, page: 1, per_page: 100
      @rate_limiter.track do
        flickr.people.getPhotos(user_id: user_id, page: page, per_page: per_page, extras: PHOTO_EXTRAS)
      end
    end

    SET_PHOTO_EXTRAS = %w[
      date_taken
      date_upload
      description
      media
      original_format
      tags
      url_o
    ].join(',').freeze

    def set_photos photoset_id:, user_id:, page: 1, per_page: 500
      @rate_limiter.track do
        flickr.photosets.getPhotos(
          photoset_id: photoset_id, user_id: user_id, page: page, per_page: per_page, extras: SET_PHOTO_EXTRAS
        )
      end
    end

    def sets user_id:
      @rate_limiter.track do
        flickr.photosets.getList(user_id: user_id, per_page: 500)
      end
    end

    def profile user_id:
      ProfileQuery.new(flickr: flickr, user_id: user_id, rate_limiter: @rate_limiter)
    end
  end
end
