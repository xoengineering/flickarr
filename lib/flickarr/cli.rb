module Flickarr
  class CLI
    DEFAULT_CONFIG_PATH = File.join(Dir.home, '.flickarr', 'config.yml').freeze
    VALID_CONFIG_KEYS = %i[access_secret access_token api_key last_export_page library_path shared_secret user_nsid
                           username].freeze

    def initialize args, config_path: DEFAULT_CONFIG_PATH
      @config_path = config_path
      @limit       = extract_option(args, '--limit')&.to_i
      @overwrite   = args.delete('--overwrite') ? true : false
      @args        = args
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
      when 'export:photos'
        run_export_photos
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
      query   = client.photo(id: photo_id)

      begin
        photo = Photo.new(info: query.info, sizes: query.sizes.size, exif: query.exif)
      rescue Flickr::FailedResponse => e
        warn "Error: #{e.message}"
        return
      end

      archive = config.archive_path
      status  = photo.write(archive_path: archive, overwrite: @overwrite)
      path    = File.join archive, photo.folder_path

      case status
      when :created     then puts "Downloaded photo #{photo_id} to #{path}"
      when :overwritten then puts "Re-downloaded photo #{photo_id} to #{path}"
      when :skipped     then puts "Skipped photo #{photo_id} (already exists at #{path})"
      end
    end

    def run_export_photos
      config = Config.load(@config_path)

      unless config.access_token && config.access_secret && config.user_nsid
        warn 'Error: Not authenticated. Run `flickarr auth` first.'
        return
      end

      client     = Client.new(config)
      archive    = config.archive_path
      start_page = config.last_export_page || 1
      page       = start_page
      count      = 0

      puts "Starting from page #{page}..." if page > 1

      catch(:limit_reached) do
        loop do
          response    = client.photos(user_id: config.user_nsid, page: page)
          total       = response.total.to_i
          total_pages = response.pages.to_i

          puts "Page #{page}/#{total_pages}"

          response.each do |list_photo|
            count += 1

            if !@overwrite && File.exist?(Photo.file_path_from_list_item(list_photo, archive_path: archive))
              puts "Skipped photo #{list_photo.id} (#{count}/#{total})"
            else
              export_single_photo(client: client, photo_id: list_photo.id, archive: archive, count: count, total: total)
            end

            throw(:limit_reached) if @limit && count >= @limit
          end

          config.last_export_page = page
          config.save @config_path

          break if page >= total_pages

          page += 1
        end
      end

      puts "Reached limit of #{@limit} photos." if @limit && count >= @limit
      puts "Done. #{count} photos processed."
    end

    def export_single_photo client:, photo_id:, archive:, count:, total:
      query = client.photo(id: photo_id)

      begin
        photo = Photo.new(info: query.info, sizes: query.sizes.size, exif: query.exif)
      rescue Flickr::FailedResponse => e
        warn "Error on photo #{photo_id}: #{e.message}"
        return
      end

      status = photo.write(archive_path: archive, overwrite: @overwrite)
      path   = File.join archive, photo.folder_path

      case status
      when :created     then puts "Downloaded photo #{photo_id} to #{path} (#{count}/#{total})"
      when :overwritten then puts "Re-downloaded photo #{photo_id} to #{path} (#{count}/#{total})"
      when :skipped     then puts "Skipped photo #{photo_id} (#{count}/#{total})"
      end
    end

    def run_export_profile
      config = Config.load(@config_path)

      unless config.access_token && config.access_secret && config.user_nsid
        warn 'Error: Not authenticated. Run `flickarr auth` first.'
        return
      end

      client = Client.new(config)
      profile_query = client.profile(user_id: config.user_nsid)
      profile = Profile.new(person: profile_query.info, profile: profile_query.profile)
      archive = config.archive_path

      status      = profile.write(archive_path: archive, overwrite: @overwrite)
      profile_dir = File.join archive, 'profile'

      case status
      when :created     then puts "Downloaded profile to #{profile_dir}"
      when :overwritten then puts "Re-downloaded profile to #{profile_dir}"
      when :skipped     then puts "Skipped profile (already exists at #{profile_dir})"
      end
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
      when 'access_secret'    then config.access_secret = value
      when 'access_token'     then config.access_token = value
      when 'api_key'          then config.api_key = value
      when 'last_export_page' then config.last_export_page = value.to_i
      when 'library_path'     then config.library_path = value
      when 'shared_secret'    then config.shared_secret = value
      when 'user_nsid'        then config.user_nsid = value
      when 'username'         then config.username = value
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
          export:photos       Export all photos from your timeline
          export:profile      Export Flickr profile to archive
          init                Create config directory and stub config file

        Options:
          --limit N           Stop after N photos (export:photos only)
          --overwrite         Re-download and overwrite existing files
      USAGE
    end

    def extract_option args, flag
      index = args.index(flag)
      return nil unless index

      args.delete_at(index)
      args.delete_at(index)
    end
  end
end
