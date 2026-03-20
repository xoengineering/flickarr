require 'down'
require 'fileutils'
require 'json'
require 'yaml'

module Flickarr
  class Profile
    DEFAULT_AVATAR_URL = 'https://www.flickr.com/images/buddyicon.gif'.freeze

    attr_reader :city,
                :country,
                :description,
                :email,
                :facebook,
                :first_name,
                :hometown,
                :iconfarm,
                :iconserver,
                :instagram,
                :ispro,
                :join_date,
                :last_name,
                :location,
                :nsid,
                :occupation,
                :path_alias,
                :photo_count,
                :photosurl,
                :pinterest,
                :profileurl,
                :realname,
                :timezone,
                :tumblr,
                :twitter,
                :upload_count,
                :username,
                :website

    def initialize person:, profile: nil
      @description  = person.description.to_s
      @iconfarm     = person.iconfarm
      @iconserver   = person.iconserver.to_s
      @ispro        = person.ispro
      @location     = person.location.to_s
      @nsid         = person.nsid
      @path_alias   = person.path_alias
      @photosurl    = person.photosurl.to_s
      @profileurl   = person.profileurl.to_s
      @realname     = person.realname.to_s
      @timezone     = { label: person.timezone.label.to_s, offset: person.timezone.offset.to_s }
      @upload_count = person.respond_to?(:upload_count) ? person.upload_count.to_i : nil
      @username     = person.username.to_s

      extract_photos person

      return unless profile

      @city         = profile.city.to_s
      @country      = profile.country.to_s
      @email        = profile.email.to_s
      @facebook     = profile.facebook.to_s
      @first_name   = profile.first_name.to_s
      @hometown     = profile.hometown.to_s
      @instagram    = profile.instagram.to_s
      @join_date    = profile.join_date.to_s
      @last_name    = profile.last_name.to_s
      @occupation   = profile.occupation.to_s
      @pinterest    = profile.pinterest.to_s
      @tumblr       = profile.tumblr.to_s
      @twitter      = profile.twitter.to_s
      @website      = profile.website.to_s
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
        avatar_url:   avatar_url,
        city:         city,
        country:      country,
        description:  description,
        email:        email,
        facebook:     facebook,
        first_name:   first_name,
        hometown:     hometown,
        iconfarm:     iconfarm,
        iconserver:   iconserver,
        instagram:    instagram,
        ispro:        ispro,
        join_date:    join_date,
        last_name:    last_name,
        location:     location,
        nsid:         nsid,
        occupation:   occupation,
        path_alias:   path_alias,
        photo_count:  photo_count,
        photosurl:    photosurl,
        pinterest:    pinterest,
        profileurl:   profileurl,
        realname:     realname,
        timezone:     timezone,
        tumblr:       tumblr,
        twitter:      twitter,
        upload_count: upload_count,
        username:     username,
        website:      website
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

    def extract_photos person
      return unless person.respond_to?(:photos)

      photos = person.photos
      @photo_count = photos.respond_to?(:count) ? photos.count.to_i : nil
    end

    def profile_dir archive_path
      File.join archive_path, '_profile'
    end
  end
end
