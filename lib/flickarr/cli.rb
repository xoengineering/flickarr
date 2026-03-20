module Flickarr
  class CLI
    DEFAULT_CONFIG_PATH = File.join(Dir.home, '.flickarr', 'config.yml').freeze
    VALID_CONFIG_KEYS = %i[access_secret access_token api_key library_path shared_secret user_nsid username].freeze

    def initialize args, config_path: DEFAULT_CONFIG_PATH
      @args = args
      @config_path = config_path
    end

    def run
      command = @args.shift

      case command
      when 'auth'
        run_auth
      when 'config'
        run_config
      when 'config:set'
        run_config_set
      when 'export:photo'
        run_export_photo
      when 'export:profile'
        run_export_profile
      when 'init'
        run_init
      else
        print_usage
      end
    end

    private

    def run_init
      if File.exist?(@config_path)
        puts "Config already exists at #{@config_path}"
        return
      end

      library_path = @args.shift
      config = Config.new
      config.library_path = File.expand_path(library_path) if library_path
      config.save @config_path
      puts "Initialized Flickarr config at #{@config_path}"
    end

    def run_export_photo
      url = @args.shift
      photo_id = Photo.id_from_url(url.to_s)

      unless photo_id
        warn 'Error: Could not extract photo ID from URL.'
        return
      end

      config = Config.load(@config_path)

      unless config.access_token && config.access_secret
        warn 'Error: Not authenticated. Run `flickarr auth` first.'
        return
      end

      client  = Client.new(config)
      info    = client.photo_info(photo_id: photo_id)
      sizes   = client.photo_sizes(photo_id: photo_id)
      exif    = client.photo_exif(photo_id: photo_id)
      photo   = Photo.new(info: info, sizes: sizes.size, exif: exif)
      archive = config.archive_path

      photo.write(archive_path: archive)
      puts "Exported photo #{photo_id} to #{File.join(archive, photo.folder_path)}"
    end

    def run_export_profile
      config = Config.load(@config_path)

      unless config.access_token && config.access_secret && config.user_nsid
        warn 'Error: Not authenticated. Run `flickarr auth` first.'
        return
      end

      client   = Client.new(config)
      person   = client.person_info(user_id: config.user_nsid)
      profile  = Profile.new(person)
      archive  = config.archive_path

      profile.write(archive_path: archive)
      puts "Exported profile to #{File.join(archive, '_profile')}"
    end

    def run_auth
      config = Config.load(@config_path)
      auth = Auth.new(config, config_path: @config_path)
      auth.authenticate
    rescue ConfigError => e
      warn "Error: #{e.message}"
    end

    def run_config
      key = @args.shift

      if key
        show_config_value(key)
      else
        show_config
      end
    end

    def show_config
      unless File.exist?(@config_path)
        puts "No config file found at #{@config_path}"
        return
      end

      config = Config.load(@config_path)
      print_config(config)
    end

    def show_config_value key
      unless File.exist?(@config_path)
        puts "No config file found at #{@config_path}"
        return
      end

      config = Config.load(@config_path)
      puts config.to_h[key.to_sym]
    end

    def run_config_set
      if @args.empty?
        puts 'Usage: flickarr config:set <key>=<value> [<key>=<value> ...]'
        return
      end

      pairs = @args.map { it.split('=', 2) }
      invalid_key = pairs.map(&:first).find { !VALID_CONFIG_KEYS.include?(it.to_sym) }

      if invalid_key
        puts "Unknown config key: #{invalid_key}"
        return
      end

      config = Config.load(@config_path)
      pairs.each { |key, value| set_config_attr(config, key, value) }
      config.save(@config_path)
      print_config(config)
    end

    def set_config_attr config, key, value
      case key
      when 'access_secret' then config.access_secret = value
      when 'access_token'  then config.access_token = value
      when 'api_key'       then config.api_key = value
      when 'library_path'  then config.library_path = value
      when 'shared_secret' then config.shared_secret = value
      when 'user_nsid'     then config.user_nsid = value
      when 'username'      then config.username = value
      end
    end

    def print_config config
      hash      = config.to_h
      max_width = hash.keys.map { it.to_s.length }.max

      hash.each do |key, value|
        label = key.to_s.ljust max_width
        puts "#{label}  #{value || '(not set)'}"
      end
    end

    def print_usage
      puts <<~USAGE
        Usage: flickarr <command> [options]

        Commands:
          auth                Authenticate with Flickr
          config              Show current configuration
          config <key>        Show a single config value
          config:set          Set configuration values (key=value)
          export:photo <url>  Export a single photo by Flickr URL
          export:profile      Export Flickr profile to archive
          init                Create config directory and stub config file
      USAGE
    end
  end
end
