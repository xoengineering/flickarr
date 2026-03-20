require 'date'
require 'down'
require 'fileutils'
require 'json'
require 'slugify'
require 'yaml'

module Flickarr
  class Photo
    FLICKR_URL_PATTERN = %r{\Ahttps?://(?:www\.)?flickr\.com/photos/[^/]+/(\d+)}

    def self.id_from_url url
      match = url.match FLICKR_URL_PATTERN
      match&.captures&.first
    end

    attr_reader :description,
                :extension,
                :id,
                :media,
                :tags,
                :title

    def initialize info:, sizes:
      @id          = info.id
      @description = info.description.to_s
      @extension   = info.originalformat.to_s
      @media       = info.media.to_s
      @tags        = info.tags.tag.map(&:_content)
      @title       = info.title.to_s

      @dates          = info.dates
      @sizes          = sizes
    end

    def basename
      s = slug
      s ? "#{id}_#{s}" : id
    end

    def date_taken
      if @dates.takenunknown.to_i.zero?
        Date.parse @dates.taken
      else
        Time.at(@dates.posted.to_i).to_date
      end
    end

    def folder_path
      date_taken.strftime '%Y/%m/%d'
    end

    def original_url
      original = @sizes.find { it.label == 'Original' }
      size     = original || @sizes.last

      size.source
    end

    def slug
      s = title.slugify
      s.empty? ? nil : s
    end

    def to_h
      {
        date_taken:   date_taken.to_s,
        description:  description,
        extension:    extension,
        id:           id,
        media:        media,
        original_url: original_url,
        tags:         tags,
        title:        title
      }
    end

    def download archive_path:
      dir  = photo_dir archive_path
      dest = File.join dir, "#{basename}.#{extension}"

      FileUtils.mkdir_p dir
      Down.download original_url, destination: dest
    end

    def write archive_path:
      dir = photo_dir archive_path

      FileUtils.mkdir_p dir
      download archive_path: archive_path
      write_json archive_path: archive_path
      write_yaml archive_path: archive_path
    end

    def write_json archive_path:
      dir  = photo_dir archive_path
      json = JSON.pretty_generate to_h

      FileUtils.mkdir_p dir
      File.write File.join(dir, "#{basename}.json"), json
    end

    def write_yaml archive_path:
      dir  = photo_dir archive_path
      hash = to_h.transform_keys(&:to_s)
      yaml = YAML.dump hash

      FileUtils.mkdir_p dir
      File.write File.join(dir, "#{basename}.yaml"), yaml
    end

    private

    def photo_dir archive_path
      File.join archive_path, folder_path
    end
  end
end
