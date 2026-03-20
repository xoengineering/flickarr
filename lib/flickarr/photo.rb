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

    attr_reader :camera,
                :description,
                :exif,
                :extension,
                :id,
                :license,
                :media,
                :owner,
                :tags,
                :title,
                :views,
                :visibility

    def initialize info:, sizes:, exif: nil
      @id          = info.id
      @description = info.description.to_s
      @extension   = info.originalformat.to_s
      @license     = info.license.to_s
      @media       = info.media.to_s
      @tags        = extract_tags info
      @title       = info.title.to_s
      @views       = info.views.to_s
      @visibility  = extract_visibility info
      @owner       = extract_owner info

      @dates   = info.dates
      @sizes   = sizes
      @urls    = extract_urls info
      @camera  = exif_camera exif
      @exif    = extract_exif exif
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

    def download archive_path:
      dir  = photo_dir archive_path
      dest = File.join dir, "#{basename}.#{extension}"

      FileUtils.mkdir_p dir
      Down.download original_url, destination: dest
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
        camera:       camera,
        dates:        {
          posted:       @dates.posted.to_s,
          taken:        @dates.taken.to_s,
          lastupdate:   safe_call(@dates, :lastupdate).to_s,
          takenunknown: @dates.takenunknown.to_i
        },
        description:  description,
        exif:         exif,
        extension:    extension,
        id:           id,
        license:      license,
        media:        media,
        original_url: original_url,
        owner:        owner,
        sizes:        extract_sizes,
        tags:         tags,
        title:        title,
        urls:         @urls,
        views:        views,
        visibility:   visibility
      }
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
      hash = deep_stringify_keys to_h
      yaml = YAML.dump hash

      FileUtils.mkdir_p dir
      File.write File.join(dir, "#{basename}.yaml"), yaml
    end

    private

    def deep_stringify_keys obj
      case obj
      when Hash  then obj.transform_keys(&:to_s).transform_values { deep_stringify_keys it }
      when Array then obj.map { deep_stringify_keys it }
      else obj
      end
    end

    def exif_camera exif_response
      return nil unless exif_response

      safe_call(exif_response, :camera).to_s
    end

    def extract_exif exif_response
      return [] unless exif_response

      tags = safe_call(exif_response, :exif)
      return [] unless tags.respond_to?(:map)

      tags.map do |tag|
        raw   = safe_call(tag, :raw).to_s
        clean = safe_call(tag, :clean)

        {
          label:    tag.label.to_s,
          raw:      raw,
          clean:    clean&.to_s,
          tag:      tag.tag.to_s,
          tagspace: tag.tagspace.to_s
        }
      end
    end

    def extract_owner info
      o = safe_call(info, :owner)
      return {} unless o

      {
        nsid:     safe_call(o, :nsid).to_s,
        realname: safe_call(o, :realname).to_s,
        username: safe_call(o, :username).to_s
      }
    end

    def extract_sizes
      @sizes.map do |size|
        {
          height: size.height.to_i,
          label:  size.label.to_s,
          source: size.source.to_s,
          width:  size.width.to_i
        }
      end
    end

    def extract_tags info
      tag_list = safe_call(info.tags, :tag)
      return [] unless tag_list.respond_to?(:map)

      tag_list.map(&:_content)
    end

    def extract_urls info
      url_list = safe_call(safe_call(info, :urls), :url)
      return {} unless url_list.respond_to?(:map)

      url_list.to_h do |url|
        [url.type.to_s, url.to_s]
      end
    end

    def extract_visibility info
      vis = safe_call(info, :visibility)
      return {} unless vis

      {
        isfamily: vis.isfamily.to_i,
        isfriend: vis.isfriend.to_i,
        ispublic: vis.ispublic.to_i
      }
    end

    def photo_dir archive_path
      File.join archive_path, folder_path
    end

    def safe_call obj, method
      obj.respond_to?(method) ? obj.send(method) : nil
    end
  end
end
