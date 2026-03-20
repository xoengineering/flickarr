module Flickarr
  class Client
    class ProfileQuery
      def initialize flickr:, user_id:, rate_limiter:
        @flickr       = flickr
        @rate_limiter = rate_limiter
        @user_id      = user_id
      end

      def info
        @rate_limiter.track { @flickr.people.getInfo(user_id: @user_id) }
      end

      def profile
        @rate_limiter.track { @flickr.profile.getProfile(user_id: @user_id) }
      end
    end
  end
end
