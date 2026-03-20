module Flickarr
  class CLI
    DEFAULT_CONFIG_PATH = File.join(Dir.home, '.flickarr', 'config.yml').freeze

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
      unless File.exist?(@config_path)
        puts "No config file found at #{@config_path}"
        return
      end

      config = Config.load(@config_path)
      Config::ATTRIBUTES.each do |attr|
        value = config.public_send(attr)
        puts "#{attr}: #{value || '(not set)'}"
      end
    end

    def print_usage
      puts <<~USAGE
        Usage: flickarr <command> [options]

        Commands:
          config    Show current configuration
      USAGE
    end
  end
end
