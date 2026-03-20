require 'flickr'

module Flickarr
  class Client
    attr_reader :flickr

    def initialize config
      raise ConfigError, 'api_key is required' if config.api_key.nil? || config.api_key.empty?
      raise ConfigError, 'shared_secret is required' if config.shared_secret.nil? || config.shared_secret.empty?

      @flickr = Flickr.new config.api_key, config.shared_secret

      return unless config.access_token && config.access_secret

      @flickr.access_token  = config.access_token
      @flickr.access_secret = config.access_secret
    end

    def person_info user_id:
      flickr.people.getInfo(user_id: user_id)
    end

    def photo_info photo_id:
      flickr.photos.getInfo(photo_id: photo_id)
    end

    def photo_sizes photo_id:
      flickr.photos.getSizes(photo_id: photo_id)
    end

    def photos user_id:, page: 1, per_page: 100
      flickr.people.getPhotos(user_id: user_id, page: page, per_page: per_page)
    end
  end
end
