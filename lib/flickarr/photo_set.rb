require 'fileutils'
require 'json'
require 'slugify'
require 'yaml'

module Flickarr
  class PhotoSet
    SET_URL_PATTERN = %r{\Ahttps?://(?:www\.)?flickr\.com/photos/[^/]+/(?:sets|albums)/(\d+)}

    def self.id_from_url url
      match = url.to_s.match SET_URL_PATTERN
      match&.captures&.first
    end

    attr_reader :count_comments,
                :count_photos,
                :count_videos,
                :count_views,
                :date_create,
                :date_update,
                :description,
                :id,
                :owner,
                :primary,
                :title,
                :username

    def initialize set:, photo_items:
      @count_comments = set.count_comments.to_s
      @count_photos   = set.count_photos.to_i
      @count_videos   = set.count_videos.to_i
      @count_views    = set.count_views.to_s
      @date_create    = set.date_create.to_s
      @date_update    = set.date_update.to_s
      @description    = set.description.to_s
      @id             = set.id
      @owner          = set.owner.to_s
      @primary        = set.primary.to_s
      @title          = set.title.to_s
      @username       = set.username.to_s
      @photo_items    = photo_items
    end

    def dirname
      [id, slug].compact.join '_'
    end

    def photos_to_a
      @photo_items.map do |item|
        path = relative_photo_path item
        {
          datetaken:  item.datetaken.to_s,
          dateupload: item.dateupload.to_s,
          id:         item.id,
          isprimary:  item.isprimary.to_s == '1',
          media:      item.media.to_s,
          path:       path,
          tags:       item.tags.to_s,
          title:      item.title.to_s
        }
      end
    end

    def slug
      s = title.slugify
      s.empty? ? nil : s
    end

    def to_h
      {
        count_comments: count_comments,
        count_photos:   count_photos,
        count_videos:   count_videos,
        count_views:    count_views,
        date_create:    date_create,
        date_update:    date_update,
        description:    description,
        id:             id,
        owner:          owner,
        primary:        primary,
        title:          title,
        username:       username
      }
    end

    def write archive_path:, overwrite: false
      dir       = dir_for_set archive_path
      json_path = File.join dir, 'set.json'
      existed   = File.exist? json_path

      return :skipped if existed && !overwrite

      FileUtils.mkdir_p dir
      write_set_files dir: dir
      write_photos_files dir: dir

      existed ? :overwritten : :created
    end

    private

    def deep_stringify_keys obj
      case obj
      when Hash  then obj.transform_keys(&:to_s).transform_values { deep_stringify_keys it }
      when Array then obj.map { deep_stringify_keys it }
      else obj
      end
    end

    def relative_photo_path item
      ext  = item.media.to_s == 'video' ? 'mp4' : item.originalformat.to_s
      slug = item.title.to_s.slugify
      base = [item.id, slug.empty? ? nil : slug].compact.join('_')
      date = if item.datetakenunknown.to_i.zero?
               Date.parse item.datetaken
             else
               Time.at(item.dateupload.to_i).to_date
             end

      File.join date.strftime('%Y/%m/%d'), "#{base}.#{ext}"
    end

    def dir_for_set archive_path
      File.join archive_path, 'Sets', dirname
    end

    def write_photos_files dir:
      refs = photos_to_a

      File.write File.join(dir, 'photos.json'), JSON.pretty_generate(refs)
      File.write File.join(dir, 'photos.yaml'), YAML.dump(deep_stringify_keys(refs))
    end

    def write_set_files dir:
      File.write File.join(dir, 'set.json'), JSON.pretty_generate(to_h)
      File.write File.join(dir, 'set.yaml'), YAML.dump(to_h.transform_keys(&:to_s))
    end
  end
end
