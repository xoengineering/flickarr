require 'date'
require 'down'
require 'fileutils'
require 'json'
require 'net/http'
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
                :location,
                :media,
                :owner,
                :tags,
                :title,
                :views,
                :visibility

    def initialize info:, sizes:, exif: nil
      @id          = info.id
      @description = info.description.to_s
      @extension   = info.media.to_s == 'video' ? 'mp4' : info.originalformat.to_s
      @license     = License.new(info.license)
      @media       = info.media.to_s
      @tags        = extract_tags info
      @title       = info.title.to_s
      @views       = info.views.to_s
      @visibility  = extract_visibility info
      @owner       = extract_owner info

      @dates    = info.dates
      @location = extract_location info
      @sizes    = sizes
      @urls     = extract_urls info
      @camera   = exif&.camera.to_s if exif
      @exif     = extract_exif exif
    end

    def basename
      [id, slug].compact.join '_'
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
      url  = resolve_download_url

      FileUtils.mkdir_p dir
      Down.download url, destination: dest
    end

    def folder_path
      date_taken.strftime '%Y/%m/%d'
    end

    def original_url
      video_original = @sizes.find { it.label == 'Video Original' }
      photo_original = @sizes.find { it.label == 'Original' }
      size           = video_original || photo_original || @sizes.last

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
          lastupdate:   @dates.respond_to?(:lastupdate) ? @dates.lastupdate.to_s : '',
          posted:       @dates.posted.to_s,
          taken:        @dates.taken.to_s,
          takenunknown: @dates.takenunknown.to_i
        },
        description:  description,
        exif:         exif,
        extension:    extension,
        id:           id,
        license:      license.to_h,
        location:     location,
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

    def write archive_path:, overwrite: false
      dir        = photo_dir archive_path
      image_path = File.join dir, "#{basename}.#{extension}"
      existed    = File.exist? image_path

      return :skipped if existed && !overwrite

      FileUtils.mkdir_p dir
      download archive_path: archive_path
      write_json archive_path: archive_path
      write_yaml archive_path: archive_path

      existed ? :overwritten : :created
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

    def resolve_download_url
      url = original_url
      return url unless media == 'video'

      uri      = URI(url)
      response = Net::HTTP.get_response(uri)

      response.is_a?(Net::HTTPRedirection) ? response['location'] : url
    end

    def extract_exif exif_response
      return [] unless exif_response
      return [] unless exif_response.respond_to?(:exif)

      exif_response.exif.map do |tag|
        {
          clean:    tag.respond_to?(:clean) ? tag.clean&.to_s : nil,
          label:    tag.label.to_s,
          raw:      tag.raw.to_s,
          tag:      tag.tag.to_s,
          tagspace: tag.tagspace.to_s
        }
      end
    end

    def extract_location info
      return nil unless info.respond_to?(:location)

      loc = info.location

      {
        accuracy:  loc.accuracy.to_s,
        context:   loc.context.to_s,
        country:   loc.country.to_s,
        county:    loc.county.to_s,
        latitude:  loc.latitude.to_s,
        locality:  loc.locality.to_s,
        longitude: loc.longitude.to_s,
        region:    loc.region.to_s
      }
    end

    def extract_owner info
      return {} unless info.respond_to?(:owner)

      o = info.owner

      {
        nsid:     o.nsid.to_s,
        realname: o.realname.to_s,
        username: o.username.to_s
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
      return [] unless info.tags.respond_to?(:tag)

      info.tags.tag.map(&:_content)
    end

    def extract_urls info
      return {} unless info.respond_to?(:urls)
      return {} unless info.urls.respond_to?(:url)

      info.urls.url.to_h do |url|
        [url.type.to_s, url.to_s]
      end
    end

    def extract_visibility info
      return {} unless info.respond_to?(:visibility)

      vis = info.visibility

      {
        isfamily: vis.isfamily.to_i,
        isfriend: vis.isfriend.to_i,
        ispublic: vis.ispublic.to_i
      }
    end

    def photo_dir archive_path
      File.join archive_path, folder_path
    end
  end
end
