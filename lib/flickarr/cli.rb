module Flickarr
  class CLI
    DEFAULT_CONFIG_PATH = File.join(Dir.home, '.flickarr', 'config.yml').freeze
    VALID_CONFIG_KEYS = %i[access_secret access_token api_key shared_secret user_nsid username].freeze

    def initialize args, config_path: DEFAULT_CONFIG_PATH
      @args = args
      @config_path = config_path
    end

    def run
      command = @args.shift

      case command
      when 'config'
        run_config
      when 'config:set'
        run_config_set
      else
        print_usage
      end
    end

    private

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

      pairs = @args.map { |pair| pair.split('=', 2) }
      invalid_key = pairs.map(&:first).find { |key| !VALID_CONFIG_KEYS.include?(key.to_sym) }

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
      when 'shared_secret' then config.shared_secret = value
      when 'user_nsid'     then config.user_nsid = value
      when 'username'      then config.username = value
      end
    end

    def print_config config
      config.to_h.each do |key, value|
        puts "#{key}: #{value || '(not set)'}"
      end
    end

    def print_usage
      puts <<~USAGE
        Usage: flickarr <command> [options]

        Commands:
          config              Show current configuration
          config <key>        Show a single config value
          config:set          Set configuration values (key=value)
      USAGE
    end
  end
end
