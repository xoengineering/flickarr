module Flickarr
  class CLI
    DEFAULT_CONFIG_PATH = File.join(Dir.home, '.flickarr', 'config.yml').freeze
    VALID_CONFIG_KEYS = %i[api_key shared_secret access_token access_secret user_nsid username].freeze

    def initialize args, config_path: DEFAULT_CONFIG_PATH
      @args = args
      @config_path = config_path
    end

    def run
      command = @args.shift

      case command
      when 'config'
        run_config
      else
        print_usage
      end
    end

    private

    def run_config
      subcommand = @args.shift

      case subcommand
      when 'set'
        run_config_set
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
      config.to_h.each do |key, value|
        puts "#{key}: #{value || '(not set)'}"
      end
    end

    def run_config_set
      key = @args.shift
      value = @args.shift

      unless key && value
        puts 'Usage: flickarr config set <key> <value>'
        return
      end

      unless VALID_CONFIG_KEYS.include?(key.to_sym)
        puts "Unknown config key: #{key}"
        return
      end

      config = Config.load(@config_path)
      config.public_send(:"#{key}=", value)
      config.save(@config_path)
    end

    def print_usage
      puts <<~USAGE
        Usage: flickarr <command> [options]

        Commands:
          config          Show current configuration
          config set      Set a configuration value
      USAGE
    end
  end
end
