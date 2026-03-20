module Flickarr
  class Auth
    def initialize config, config_path: CLI::DEFAULT_CONFIG_PATH
      @config = config
      @config_path = config_path
      @client = Client.new(config)
    end

    def authenticated?
      !@config.access_token.nil? && !@config.access_secret.nil?
    end

    def authenticate
      flickr = @client.flickr

      request_token = flickr.get_request_token
      auth_url      = flickr.get_authorize_url request_token['oauth_token'], perms: 'read'

      puts 'Open this URL in your browser to authorize Flickarr:'
      puts auth_url

      verifier = prompt_for_verifier

      flickr.get_access_token request_token['oauth_token'], request_token['oauth_token_secret'], verifier

      login = flickr.test.login

      @config.access_token  = flickr.access_token
      @config.access_secret = flickr.access_secret
      @config.user_nsid     = login.nsid
      @config.username      = login.username

      @config.save @config_path

      puts "Authenticated as #{@config.username}"
    end

    def prompt_for_verifier
      print 'Enter the verification code: '
      $stdin.gets.strip
    end
  end
end
