module Flickarr
  class Client
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
  end
end
