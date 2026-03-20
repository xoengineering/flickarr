require 'down'
require 'fileutils'
require 'json'
require 'yaml'

module Flickarr
  class ProfileWriter
    attr_reader :archive_path, :profile

    def initialize archive_path:, profile:
      @archive_path = archive_path
      @profile      = profile
    end

    def write
      FileUtils.mkdir_p profile_dir
      write_json
      write_yaml
      download_avatar
    end

    def write_json
      FileUtils.mkdir_p profile_dir
      json = JSON.pretty_generate profile.to_h
      File.write json_path, json
    end

    def write_yaml
      FileUtils.mkdir_p profile_dir
      hash = profile.to_h.transform_keys(&:to_s)
      yaml = YAML.dump hash
      File.write yaml_path, yaml
    end

    def download_avatar
      FileUtils.mkdir_p profile_dir
      ext       = File.extname profile.avatar_url
      dest      = File.join profile_dir, "avatar#{ext}"
      tempfile  = Down.download profile.avatar_url

      FileUtils.mv tempfile.path, dest
    end

    private

    def json_path
      File.join profile_dir, 'profile.json'
    end

    def profile_dir
      File.join archive_path, '_profile'
    end

    def yaml_path
      File.join profile_dir, 'profile.yaml'
    end
  end
end
