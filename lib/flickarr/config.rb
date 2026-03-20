module Flickarr
  class Config
    attr_accessor :api_key, :shared_secret, :access_token, :access_secret, :user_nsid, :username

    def initialize
      @api_key = ENV.fetch('FLICKARR_API_KEY', nil)
      @shared_secret = ENV.fetch('FLICKARR_SHARED_SECRET', nil)
      @access_token = nil
      @access_secret = nil
      @user_nsid = nil
      @username = nil
    end
  end
end
