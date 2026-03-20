module Flickarr
  class Client
    class ProfileQuery
      def initialize flickr:, user_id:
        @flickr  = flickr
        @user_id = user_id
      end

      def info
        @flickr.people.getInfo(user_id: @user_id)
      end
    end
  end
end
