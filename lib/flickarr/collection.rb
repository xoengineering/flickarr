require 'fileutils'
require 'json'
require 'slugify'
require 'yaml'

module Flickarr
  class Collection
    COLLECTION_URL_PATTERN = %r{\Ahttps?://(?:www\.)?flickr\.com/photos/[^/]+/collections/(\d+)}

    def self.id_from_url url
      match = url.to_s.match COLLECTION_URL_PATTERN
      match&.captures&.first
    end

    attr_reader :description,
                :iconlarge,
                :iconsmall,
                :id,
                :title

    def initialize collection
      @description = collection.description.to_s
      @iconlarge   = collection.iconlarge.to_s
      @iconsmall   = collection.iconsmall.to_s
      @id          = collection.id
      @title       = collection.title.to_s
      @set_refs    = collection.set
    end

    def dirname
      [id, slug].compact.join '_'
    end

    def sets_to_a
      @set_refs.map do |s|
        set_slug = s.title.to_s.slugify
        set_dirname = [s.id, set_slug.empty? ? nil : set_slug].compact.join('_')

        {
          description: s.description.to_s,
          id:          s.id,
          path:        File.join('Sets', set_dirname),
          title:       s.title.to_s
        }
      end
    end

    def slug
      s = title.slugify
      s.empty? ? nil : s
    end

    def to_h
      {
        description: description,
        iconlarge:   iconlarge,
        iconsmall:   iconsmall,
        id:          id,
        title:       title
      }
    end

    def write archive_path:, overwrite: false
      dir       = collection_dir archive_path
      json_path = File.join dir, 'collection.json'
      existed   = File.exist? json_path

      return :skipped if existed && !overwrite

      FileUtils.mkdir_p dir
      write_collection_files dir: dir
      write_sets_files dir: dir

      existed ? :overwritten : :created
    end

    private

    def collection_dir archive_path
      File.join archive_path, 'Collections', dirname
    end

    def deep_stringify_keys obj
      case obj
      when Hash  then obj.transform_keys(&:to_s).transform_values { deep_stringify_keys it }
      when Array then obj.map { deep_stringify_keys it }
      else obj
      end
    end

    def write_collection_files dir:
      File.write File.join(dir, 'collection.json'), JSON.pretty_generate(to_h)
      File.write File.join(dir, 'collection.yaml'), YAML.dump(to_h.transform_keys(&:to_s))
    end

    def write_sets_files dir:
      refs = sets_to_a

      File.write File.join(dir, 'sets.json'), JSON.pretty_generate(refs)
      File.write File.join(dir, 'sets.yaml'), YAML.dump(deep_stringify_keys(refs))
    end
  end
end
