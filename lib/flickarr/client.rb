require 'flickr'

module Flickarr
  class Client
    attr_reader :flickr

    def initialize config
      raise ConfigError, 'api_key is required' unless config.api_key
      raise ConfigError, 'shared_secret is required' unless config.shared_secret

      @flickr = Flickr.new config.api_key, config.shared_secret

      return unless config.access_token && config.access_secret

      @flickr.access_token  = config.access_token
      @flickr.access_secret = config.access_secret
    end
  end
end
