module Flickarr
  class Photo < Post
    def initialize info:, sizes:, exif: nil
      super
      @extension = info.originalformat.to_s
    end

    def download archive_path:
      dir  = post_dir archive_path
      dest = File.join dir, "#{basename}.#{extension}"

      FileUtils.mkdir_p dir

      begin
        Down.download original_url, destination: dest
      rescue Down::ClientError => e
        raise unless e.message.include?('410') && constructed_original_url

        warn "  Photo #{id}: getSizes URL returned 410, retrying with constructed URL..."
        Down.download constructed_original_url, destination: dest
      end
    end

    def constructed_original_url
      return nil unless @server && @originalsecret

      "https://live.staticflickr.com/#{@server}/#{id}_#{@originalsecret}_o.#{extension}"
    end

    def original_url
      original = @sizes.find { it.label == 'Original' }
      size     = original || @sizes.last

      size.source
    end
  end
end
