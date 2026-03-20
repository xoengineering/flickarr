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
        "https://farm#{iconfarm}.staticflickr.com/#{iconserver}/buddyicons/#{nsid}.jpg"
      end
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
  end
end
