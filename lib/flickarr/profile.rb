require 'down'
require 'fileutils'
require 'json'
require 'yaml'

module Flickarr
  class Profile
    DEFAULT_AVATAR_URL = 'https://www.flickr.com/images/buddyicon.gif'.freeze

    attr_reader :description,
                :iconfarm,
                :iconserver,
                :ispro,
                :location,
                :nsid,
                :path_alias,
                :photosurl,
                :profileurl,
                :realname,
                :timezone,
                :username

    def initialize person
      @description = person.description.to_s
      @iconfarm    = person.iconfarm
      @iconserver  = person.iconserver.to_s
      @ispro       = person.ispro
      @location    = person.location.to_s
      @nsid        = person.nsid
      @path_alias  = person.path_alias
      @photosurl   = person.photosurl.to_s
      @profileurl  = person.profileurl.to_s
      @realname    = person.realname.to_s
      @timezone    = { label: person.timezone.label.to_s, offset: person.timezone.offset.to_s }
      @username    = person.username.to_s
    end

    def avatar_url
      if iconserver == '0' || iconfarm.zero?
        DEFAULT_AVATAR_URL
      else
        "https://farm#{iconfarm}.staticflickr.com/#{iconserver}/buddyicons/#{nsid}_r.jpg"
      end
    end

    def download_avatar archive_path:
      dir  = profile_dir archive_path
      ext  = File.extname avatar_url
      dest = File.join dir, "avatar#{ext}"

      FileUtils.mkdir_p dir
      Down.download avatar_url, destination: dest
    end

    def to_h
      {
        avatar_url:  avatar_url,
        description: description,
        iconfarm:    iconfarm,
        iconserver:  iconserver,
        ispro:       ispro,
        location:    location,
        nsid:        nsid,
        path_alias:  path_alias,
        photosurl:   photosurl,
        profileurl:  profileurl,
        realname:    realname,
        timezone:    timezone,
        username:    username
      }
    end

    def write archive_path:, overwrite: false
      dir       = profile_dir archive_path
      json_path = File.join dir, 'profile.json'
      existed   = File.exist? json_path

      return :skipped if existed && !overwrite

      FileUtils.mkdir_p dir
      write_json dir: dir
      write_yaml dir: dir
      download_avatar archive_path: archive_path

      existed ? :overwritten : :created
    end

    def write_json dir:
      FileUtils.mkdir_p dir
      json = JSON.pretty_generate to_h
      File.write File.join(dir, 'profile.json'), json
    end

    def write_yaml dir:
      FileUtils.mkdir_p dir
      hash = to_h.transform_keys(&:to_s)
      yaml = YAML.dump hash
      File.write File.join(dir, 'profile.yaml'), yaml
    end

    private

    def profile_dir archive_path
      File.join archive_path, '_profile'
    end
  end
end
