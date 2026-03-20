module Flickarr
  class License
    LICENSES = {
      '0'  => { name: 'All Rights Reserved',                url: nil },
      '1'  => { name: 'CC BY-NC-SA 2.0',                    url: 'https://creativecommons.org/licenses/by-nc-sa/2.0/' },
      '2'  => { name: 'CC BY-NC 2.0',                       url: 'https://creativecommons.org/licenses/by-nc/2.0/' },
      '3'  => { name: 'CC BY-NC-ND 2.0',                    url: 'https://creativecommons.org/licenses/by-nc-nd/2.0/' },
      '4'  => { name: 'CC BY 2.0',                          url: 'https://creativecommons.org/licenses/by/2.0/' },
      '5'  => { name: 'CC BY-SA 2.0',                       url: 'https://creativecommons.org/licenses/by-sa/2.0/' },
      '6'  => { name: 'CC BY-ND 2.0',                       url: 'https://creativecommons.org/licenses/by-nd/2.0/' },
      '7'  => { name: 'No Known Copyright Restrictions',     url: 'https://www.flickr.com/commons/usage/' },
      '8'  => { name: 'United States Government Work',       url: 'http://www.usa.gov/copyright.shtml' },
      '9'  => { name: 'CC0 1.0 Universal', url: 'https://creativecommons.org/publicdomain/zero/1.0/' },
      '10' => { name: 'Public Domain Mark 1.0', url: 'https://creativecommons.org/publicdomain/mark/1.0/' }
    }.freeze

    attr_reader :id, :name, :url

    def initialize id
      @id   = id.to_s
      entry = LICENSES.fetch(@id, { name: 'Unknown', url: nil })
      @name = entry[:name]
      @url  = entry[:url]
    end

    def to_h
      {
        id:   id,
        name: name,
        url:  url
      }
    end
  end
end
