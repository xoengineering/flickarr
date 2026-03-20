require 'http'

module Flickarr
  class Video < Post
    # Preferred video sizes, largest to smallest
    VIDEO_SIZE_PRIORITY = ['Video Original', '1080p', '720p', '700', '360p', '288p', 'iphone_wifi'].freeze

    def initialize info:, sizes:, exif: nil
      super
      @extension = 'mp4'
    end

    def download archive_path:
      dir  = post_dir archive_path
      dest = File.join dir, "#{basename}.#{extension}"
      url  = resolve_download_url

      FileUtils.mkdir_p dir
      Down.download url, destination: dest
      download_poster_frame dir: dir
    end

    def original_url
      video_original = @sizes.find { it.label == 'Video Original' }
      photo_original = @sizes.find { it.label == 'Original' }
      size           = video_original || photo_original || @sizes.last

      size.source
    end

    private

    def download_poster_frame dir:
      poster = @sizes.find { it.label == 'Original' && it.media == 'photo' }
      return unless poster

      ext  = File.extname(poster.source)
      dest = File.join dir, "#{basename}#{ext}"

      Down.download poster.source, destination: dest
    end

    def resolve_download_url
      video_sizes = VIDEO_SIZE_PRIORITY.filter_map do |label|
        @sizes.find { it.label == label && it.media == 'video' }
      end

      video_sizes.each do |size|
        url      = resolve_redirect(size.source)
        response = HTTP.head(url)

        return url if response.status.success?
      end

      # Fall back to original_url if nothing worked
      resolve_redirect original_url
    end

    def resolve_redirect url
      response = HTTP.head(url)

      response.status.redirect? ? response.headers['Location'] : url
    end
  end
end
