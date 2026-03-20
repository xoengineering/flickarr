module Flickarr
  class RateLimiter
    def initialize interval: 1.0
      @interval = interval
      @last_request_at = nil
    end

    def wait
      return unless @last_request_at

      elapsed = Time.now - @last_request_at
      remaining = @interval - elapsed

      sleep remaining if remaining.positive?
    end

    def track
      wait
      result = yield
      @last_request_at = Time.now
      result
    end
  end
end
