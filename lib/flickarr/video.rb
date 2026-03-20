require 'http'

module Flickarr
  class Video < Post
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
      url      = original_url
      response = HTTP.head(url)

      response.status.redirect? ? response.headers['Location'] : url
    end
  end
end
