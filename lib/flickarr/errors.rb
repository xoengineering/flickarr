module Flickarr
  class Error < StandardError; end
  class AuthError < Error; end
  class ApiError < Error; end
  class DownloadError < Error; end
  class ConfigError < Error; end
end
