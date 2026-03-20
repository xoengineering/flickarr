require 'fileutils'
require 'yaml'

module Flickarr
  class Config
    ATTRIBUTES = %i[api_key shared_secret access_token access_secret user_nsid username].freeze

    attr_accessor(*ATTRIBUTES)

    def initialize
      @api_key = ENV.fetch('FLICKARR_API_KEY', nil)
      @shared_secret = ENV.fetch('FLICKARR_SHARED_SECRET', nil)
      @access_token = nil
      @access_secret = nil
      @user_nsid = nil
      @username = nil
    end

    def save path
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, YAML.dump(to_h))
    end

    def to_h
      ATTRIBUTES.to_h { |attr| [attr.to_s, public_send(attr)] }
    end

    def self.load path
      config = new
      return config unless File.exist?(path)

      yaml = YAML.load_file(path)
      return config unless yaml.is_a?(Hash)

      ATTRIBUTES.each do |attr|
        value = yaml[attr.to_s]
        config.public_send(:"#{attr}=", value) if value
      end

      config
    end
  end
end
