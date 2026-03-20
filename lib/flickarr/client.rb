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

    def photo id:
      PhotoQuery.new(flickr: flickr, id: id)
    end

    def photos user_id:, page: 1, per_page: 100
      flickr.people.getPhotos(user_id: user_id, page: page, per_page: per_page)
    end

    def profile user_id:
      ProfileQuery.new(flickr: flickr, user_id: user_id)
    end

    class PhotoQuery
      def initialize flickr:, id:
        @flickr = flickr
        @id     = id
      end

      def exif
        @flickr.photos.getExif(photo_id: @id)
      end

      def info
        @flickr.photos.getInfo(photo_id: @id)
      end

      def sizes
        @flickr.photos.getSizes(photo_id: @id)
      end
    end

    class ProfileQuery
      def initialize flickr:, user_id:
        @flickr  = flickr
        @user_id = user_id
      end

      def info
        @flickr.people.getInfo(user_id: @user_id)
      end
    end
  end
end
