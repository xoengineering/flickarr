module Flickarr
  class Client
    class PhotoQuery
      def initialize flickr:, id:, rate_limiter:
        @flickr       = flickr
        @id           = id
        @rate_limiter = rate_limiter
      end

      def exif
        @rate_limiter.track { @flickr.photos.getExif(photo_id: @id) }
      end

      def info
        @rate_limiter.track { @flickr.photos.getInfo(photo_id: @id) }
      end

      def sizes
        @rate_limiter.track { @flickr.photos.getSizes(photo_id: @id) }
      end
    end
  end
end
