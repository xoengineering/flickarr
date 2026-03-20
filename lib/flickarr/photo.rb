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
      Down.download original_url, destination: dest
    end

    def original_url
      original = @sizes.find { it.label == 'Original' }
      size     = original || @sizes.last

      size.source
    end
  end
end
