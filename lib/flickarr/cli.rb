require 'optparse'

module Flickarr
  class CLI
    DEFAULT_CONFIG_PATH = File.join(Dir.home, '.flickarr', 'config.yml').freeze
    VALID_CONFIG_KEYS = %i[access_secret access_token api_key last_page_photos last_page_posts last_page_videos
                           latest_version latest_version_checked_at library_path shared_secret
                           total_collections total_photos total_sets total_videos
                           user_nsid username].freeze

    def initialize args, config_path: DEFAULT_CONFIG_PATH
      @config_path = config_path
      @limit       = nil
      @overwrite   = false

      if args.empty? || %w[-h --help help -v --version version].include?(args.first)
        @args = args
      else
        @parser = build_parser
        @args   = @parser.parse(args)
      end
    end

    def run
      command = @args.shift

      case command
      when 'auth'                                          then run_auth
      when 'config'                                        then run_config
      when 'config:set'                                    then run_config_set
      when 'errors'                                        then run_errors
      when 'export', 'export:posts'                        then run_export_or_post
      when 'export:albums', 'export:sets', 'export:set' then run_export_sets_or_one
      when 'export:collections'                            then run_export_collections_or_one
      when 'export:photo', 'export:video'                  then run_export_post
      when 'export:photos'                                 then run_export_posts(media: 'photos')
      when 'export:profile'                                then run_export_profile
      when 'export:videos'                                 then run_export_posts(media: 'videos')
      when '-v', '--version', 'version'                    then run_version
      when 'init'                                          then run_init
      when 'open'                                          then run_open
      when 'path'                                          then run_path
      when 'status'                                        then run_status
      else                                                      print_help
      end

      check_for_update unless %w[-v --version version status -h --help help config config:set init].include?(command)
    end

    private

    def build_parser
      OptionParser.new do |opts|
        opts.banner = 'Usage: flickarr <command> [options]'

        opts.on('--limit N', Integer, 'Stop after N items') do |n|
          @limit = n
        end

        opts.on('--overwrite', 'Re-download and overwrite existing files') do
          @overwrite = true
        end
      end
    end

    def run_errors
      config  = Config.load(@config_path)
      archive = config.archive_path

      unless archive
        warn 'Error: No archive path configured. Run `flickarr auth` first.'
        return
      end

      puts File.join(archive, '_errors.log')
    end

    def run_export_collections_or_one
      if @args.first && Collection.id_from_url(@args.first)
        run_export_single_collection
      else
        run_export_collections
      end
    end

    def run_export_collections
      config = Config.load(@config_path)

      unless config.access_token && config.access_secret && config.user_nsid
        warn 'Error: Not authenticated. Run `flickarr auth` first.'
        return
      end

      client  = Client.new(config)
      archive = config.archive_path
      tree    = client.collections(user_id: config.user_nsid)
      count   = 0

      total          = tree.respond_to?(:count) ? tree.count : 0
      download_count = 0
      interrupted    = false
      trap('INT') { interrupted = true }

      tree.each do |collection_data|
        break if interrupted

        count      += 1
        collection  = Collection.new(collection_data)
        status      = collection.write(archive_path: archive, overwrite: @overwrite)
        path        = File.join archive, 'Collections', collection.dirname

        puts "#{collection.title} (#{count}/#{total})"
        case status
        when :created
          puts "  Downloaded to #{path}"
          download_count += 1
        when :overwritten
          puts "  Re-downloaded to #{path}"
          download_count += 1
        when :skipped
          puts "  Skipped at #{path}"
        end

        break if @limit && download_count >= @limit
      end

      puts "\nInterrupted." if interrupted
      puts "Done. #{count} collections processed."
    end

    def run_export_single_collection
      url           = @args.shift
      collection_id = Collection.id_from_url(url)
      config        = Config.load(@config_path)
      archive       = config.archive_path

      unless config.access_token && config.access_secret && config.user_nsid
        warn 'Error: Not authenticated. Run `flickarr auth` first.'
        return
      end

      client = Client.new(config)
      tree   = client.collections(user_id: config.user_nsid)
      match  = tree.find { it.id.include?(collection_id) }

      unless match
        warn "Error: Collection #{collection_id} not found."
        return
      end

      collection = Collection.new(match)
      status     = collection.write(archive_path: archive, overwrite: @overwrite)
      path       = File.join archive, 'Collections', collection.dirname

      puts collection.title
      case status
      when :created     then puts "  Downloaded to #{path}"
      when :overwritten then puts "  Re-downloaded to #{path}"
      when :skipped     then puts "  Skipped at #{path}"
      end
    end

    def run_export_sets_or_one
      if @args.first && PhotoSet.id_from_url(@args.first)
        run_export_single_set
      else
        run_export_sets
      end
    end

    def run_export_sets
      config = Config.load(@config_path)

      unless config.access_token && config.access_secret && config.user_nsid
        warn 'Error: Not authenticated. Run `flickarr auth` first.'
        return
      end

      client  = Client.new(config)
      archive = config.archive_path
      sets    = client.sets(user_id: config.user_nsid)
      count   = 0
      total   = sets.respond_to?(:total) ? sets.total.to_i : 0

      download_count = 0
      interrupted    = false
      trap('INT') { interrupted = true }

      sets.each do |set_data|
        break if interrupted

        count += 1

        photos_response = client.set_photos(photoset_id: set_data.id, user_id: config.user_nsid)
        photo_items     = photos_response.respond_to?(:photo) ? photos_response.photo.to_a : []

        photo_set = PhotoSet.new(set: set_data, photo_items: photo_items)
        status    = photo_set.write(archive_path: archive, overwrite: @overwrite)
        path      = File.join archive, 'Sets', photo_set.dirname

        puts "#{photo_set.title} (#{count}/#{total})"
        case status
        when :created
          puts "  Downloaded to #{path}"
          download_count += 1
        when :overwritten
          puts "  Re-downloaded to #{path}"
          download_count += 1
        when :skipped
          puts "  Skipped at #{path}"
        end

        break if @limit && download_count >= @limit
      end

      puts "\nInterrupted." if interrupted
      puts "Done. #{count} sets processed."
    end

    def run_export_single_set
      url    = @args.shift
      set_id = PhotoSet.id_from_url(url)
      config = Config.load(@config_path)

      unless config.access_token && config.access_secret && config.user_nsid
        warn 'Error: Not authenticated. Run `flickarr auth` first.'
        return
      end

      client  = Client.new(config)
      archive = config.archive_path

      begin
        set_data        = client.flickr.photosets.getInfo(photoset_id: set_id, user_id: config.user_nsid)
        photos_response = client.set_photos(photoset_id: set_id, user_id: config.user_nsid)
      rescue Flickr::FailedResponse => e
        warn "Error: #{e.message}"
        return
      end

      photo_items = photos_response.respond_to?(:photo) ? photos_response.photo.to_a : []
      photo_set   = PhotoSet.new(set: set_data, photo_items: photo_items)
      status      = photo_set.write(archive_path: archive, overwrite: @overwrite)
      path        = File.join archive, 'Sets', photo_set.dirname

      puts photo_set.title
      case status
      when :created     then puts "  Downloaded to #{path}"
      when :overwritten then puts "  Re-downloaded to #{path}"
      when :skipped     then puts "  Skipped at #{path}"
      end
    end

    def run_open
      config  = Config.load(@config_path)
      archive = config.archive_path

      unless archive && Dir.exist?(archive)
        puts 'No archive found. Run `flickarr init` and `flickarr auth` first.'
        return
      end

      system 'open', archive
    end

    def run_path
      config  = Config.load(@config_path)
      archive = config.archive_path

      if archive
        puts archive
      else
        warn 'Error: No archive path configured. Run `flickarr auth` first.'
      end
    end

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

    def run_status
      config  = Config.load(@config_path)
      archive = config.archive_path

      unless archive && Dir.exist?(archive)
        puts 'No archive found. Run `flickarr init` and `flickarr auth` first.'
        return
      end

      fetch_and_cache_totals(config) if @overwrite || !config.total_photos

      profile_exists   = File.exist?(File.join(archive, 'Profile', 'profile.json'))
      photo_count      = count_media_files(archive, %w[jpg jpeg png gif tiff])
      video_count      = count_media_files(archive, %w[mp4])
      set_count        = count_subdirs(File.join(archive, 'Sets'))
      collection_count = count_subdirs(File.join(archive, 'Collections'))
      disk_usage       = human_size(dir_size(archive))

      checker = Version.new(config)
      checker.check
      config.save(@config_path)
      version_str = checker.update_message || "#{Flickarr::VERSION} (up to date)"

      rows = [
        ['Version',     version_str],
        ['Archive',     archive],
        ['Profile',     profile_exists ? 'Downloaded' : 'Not downloaded'],
        ['Photos',      format_count(photo_count, config.total_photos)],
        ['Videos',      format_count(video_count, config.total_videos)],
        ['Sets',        format_count(set_count, config.total_sets)],
        ['Collections', format_count(collection_count, config.total_collections)],
        ['Disk usage',  disk_usage]
      ]

      max_width = rows.map { it.first.length }.max + 1
      rows.each do |label, value|
        puts "#{"#{label}:".ljust(max_width)}  #{value}"
      end
    end

    def fetch_and_cache_totals config
      return unless config.access_token && config.access_secret && config.user_nsid

      client = Client.new(config)

      photos_response = client.photos(user_id: config.user_nsid, per_page: 1)
      config.total_photos = photos_response.total.to_i

      videos_response = client.flickr.photos.search(user_id: config.user_nsid, media: 'videos', per_page: 1)
      config.total_videos = videos_response.total.to_i

      sets_response = client.sets(user_id: config.user_nsid)
      config.total_sets = sets_response.respond_to?(:total) ? sets_response.total.to_i : 0

      collections_response = client.collections(user_id: config.user_nsid)
      config.total_collections = collections_response.respond_to?(:count) ? collections_response.count : 0

      config.save @config_path
    end

    def format_count local, total
      total ? "#{local} / #{total}" : local.to_s
    end

    def post_exists_on_disk? archive:, post_id:
      Dir.glob(File.join(archive, '**', "#{post_id}_*")).any? ||
        Dir.glob(File.join(archive, '**', "#{post_id}.*")).any?
    end

    def count_media_files archive, extensions
      pattern = File.join(archive, '**', "*.{#{extensions.join(',')}}")
      Dir.glob(pattern).count do |path|
        !path.include?('/Profile/') && !path.include?('/Sets/') && !path.include?('/Collections/')
      end
    end

    def check_for_update
      return unless File.exist?(@config_path)

      config  = Config.load(@config_path)
      checker = Version.new(config)
      return unless checker.stale?

      message = checker.update_message
      config.save(@config_path)
      return unless message

      warn "\n#{message}"
    rescue StandardError
      nil
    end

    def run_version
      config  = Config.load(@config_path)
      checker = Version.new(config)
      latest  = checker.check
      config.save(@config_path)

      if latest && Gem::Version.new(latest) > Gem::Version.new(Flickarr::VERSION)
        puts "#{Flickarr::VERSION} (latest: #{latest} — run `gem update flickarr`)"
      else
        puts "#{Flickarr::VERSION} (up to date)"
      end
    end

    def count_subdirs path
      return 0 unless Dir.exist?(path)

      Dir.children(path).count { File.directory?(File.join(path, it)) }
    end

    def dir_size path
      Dir.glob(File.join(path, '**', '*')).select { File.file?(it) }.sum { File.size(it) }
    end

    def human_size bytes
      units = %w[B KB MB GB TB]
      unit  = 0

      size = bytes.to_f
      while size >= 1024 && unit < units.length - 1
        size /= 1024
        unit += 1
      end

      format('%<size>.1f %<unit>s', size: size, unit: units[unit])
    end

    def run_export_or_post
      url = @args.first

      if Collection.id_from_url(url.to_s)
        run_export_single_collection
      elsif PhotoSet.id_from_url(url.to_s)
        run_export_single_set
      elsif Profile.matches_url?(url.to_s)
        @args.shift
        run_export_profile
      elsif Post.id_from_url(url.to_s)
        run_export_post
      else
        run_export_posts
      end
    end

    def run_export_post
      url     = @args.shift
      post_id = Post.id_from_url(url.to_s)

      unless post_id
        warn 'Error: Could not extract post ID from URL.'
        return
      end

      config  = Config.load(@config_path)
      archive = config.archive_path

      if !@overwrite && archive && post_exists_on_disk?(archive: archive, post_id: post_id)
        puts "Skipped #{post_id} (already exists)"
        return
      end

      unless config.access_token && config.access_secret
        warn 'Error: Not authenticated. Run `flickarr auth` first.'
        return
      end

      client = Client.new(config)
      query  = client.photo(id: post_id)

      begin
        post = Post.build(info: query.info, sizes: query.sizes.size, exif: query.exif)
      rescue Flickr::FailedResponse => e
        warn "Error: #{e.message}"
        return
      end

      status = post.write(archive_path: archive, overwrite: @overwrite)
      path = File.join archive, post.folder_path

      case status
      when :created     then puts "Downloaded #{post.media} #{post_id} to #{path}"
      when :overwritten then puts "Re-downloaded #{post.media} #{post_id} to #{path}"
      when :skipped     then puts "Skipped #{post.media} #{post_id} (already exists at #{path})"
      end
    end

    def run_export_posts media: 'all'
      config = Config.load(@config_path)

      unless config.access_token && config.access_secret && config.user_nsid
        warn 'Error: Not authenticated. Run `flickarr auth` first.'
        return
      end

      client     = Client.new(config)
      archive    = config.archive_path
      last_page  = read_last_page(config, media)
      start_page = last_page ? last_page + 1 : 1
      per_page   = 100
      page       = start_page
      count      = (start_page - 1) * per_page
      run_count  = 0

      interrupted = false
      trap('INT') { interrupted = true }

      puts "Starting from page #{page}..." if page > 1

      catch(:stop_export) do
        loop do
          page_retries = 3
          begin
            response = fetch_posts_page(client: client, config: config, media: media, page: page)
          rescue Errno::ECONNRESET, JSON::ParserError, Net::OpenTimeout, Net::ReadTimeout, Errno::ETIMEDOUT => e
            page_retries -= 1
            if page_retries.positive?
              warn "Transient error fetching page #{page}: #{e.message} — retrying in 5s (#{page_retries} left)"
              sleep 5
              retry
            end
            warn "Failed to fetch page #{page} after retries: #{e.message}"
            break
          rescue Flickr::FailedResponse => e
            if transient_flickr_error?(e)
              page_retries -= 1
              if page_retries.positive?
                warn "Transient API error fetching page #{page}: #{e.message} — retrying in 5s (#{page_retries} left)"
                sleep 5
                retry
              end
              warn "Failed to fetch page #{page} after retries: #{e.message}"
              break
            end
            raise
          end
          total       = response.total.to_i
          total_pages = response.pages.to_i

          puts "Page #{page}/#{total_pages}"

          response.each do |list_post|
            throw(:stop_export) if interrupted

            count += 1

            if !@overwrite && File.exist?(Post.file_path_from_list_item(list_post, archive_path: archive))
              puts "Skipped #{list_post.media} #{list_post.id} (#{count}/#{total})"
            else
              export_single_post(client: client, config: config, post_id: list_post.id, count: count, total: total)
              run_count += 1
              throw(:stop_export) if @limit && run_count >= @limit
            end
          end

          write_last_page config, media, page
          config.save @config_path

          break if page >= total_pages

          page += 1
        end
      end

      if interrupted
        write_last_page config, media, page - 1
        config.save @config_path
      end

      puts "\nInterrupted. Saved progress at page #{page}." if interrupted
      puts "Reached limit of #{@limit} posts." if !interrupted && @limit && run_count >= @limit
      puts "Done. #{run_count} posts processed this run."
    end

    def read_last_page config, media
      case media
      when 'photos' then config.last_page_photos
      when 'videos' then config.last_page_videos
      else               config.last_page_posts
      end
    end

    def write_last_page config, media, page
      case media
      when 'photos' then config.last_page_photos = page
      when 'videos' then config.last_page_videos = page
      else               config.last_page_posts = page
      end
    end

    def fetch_posts_page client:, config:, media:, page:
      case media
      when 'photos' then client.flickr.photos.search(user_id:  config.user_nsid,
                                                     media:    'photos',
                                                     page:     page,
                                                     per_page: 100,
                                                     extras:   Client::PHOTO_EXTRAS)
      when 'videos' then client.flickr.photos.search(user_id:  config.user_nsid,
                                                     media:    'videos',
                                                     page:     page,
                                                     per_page: 100,
                                                     extras:   Client::PHOTO_EXTRAS)
      else               client.photos(user_id: config.user_nsid, page: page)
      end
    end

    def export_single_post client:, config:, post_id:, count:, total:
      retries = 3
      query   = client.photo(id: post_id)
      archive = config.archive_path

      begin
        post   = Post.build(info: query.info, sizes: query.sizes.size, exif: query.exif)
        status = post.write(archive_path: archive, overwrite: @overwrite)
      rescue Errno::ECONNRESET, JSON::ParserError, Net::OpenTimeout, Net::ReadTimeout, Errno::ETIMEDOUT => e
        retries -= 1
        if retries.positive?
          warn "Transient error on post #{post_id}: #{e.message} — retrying in 5s (#{retries} left)"
          sleep 5
          retry
        end
        warn "Failed post #{post_id} after retries: #{e.message}"
        log_error archive: archive, post_id: post_id, username: config.username, error: e
        return
      rescue Flickr::FailedResponse => e
        if transient_flickr_error?(e)
          retries -= 1
          if retries.positive?
            warn "Transient API error on post #{post_id}: #{e.message} — retrying in 5s (#{retries} left)"
            sleep 5
            retry
          end
          warn "Failed post #{post_id} after retries: #{e.message}"
          log_error archive: archive, post_id: post_id, username: config.username, error: e
          return
        end
        warn "Error on post #{post_id}: #{e.message}"
        log_error archive: archive, post_id: post_id, username: config.username, error: e
        return
      rescue Down::Error => e
        warn "Download error on post #{post_id}: #{e.message}"
        log_error archive: archive, post_id: post_id, username: config.username, error: e
        return
      end

      path = File.join archive, post.folder_path

      case status
      when :created     then puts "Downloaded #{post.media} #{post_id} to #{path} (#{count}/#{total})"
      when :overwritten then puts "Re-downloaded #{post.media} #{post_id} to #{path} (#{count}/#{total})"
      when :skipped     then puts "Skipped #{post.media} #{post_id} (#{count}/#{total})"
      end
    end

    def transient_flickr_error? error
      message = error.message.to_s.downcase
      code    = error.respond_to?(:code) ? error.code.to_s : ''

      code == '105' || message.include?('not currently available') || message.include?('service unavailable')
    end

    def log_error archive:, post_id:, username:, error:
      log_path = File.join archive, '_errors.log'
      FileUtils.mkdir_p File.dirname(log_path)

      File.open(log_path, 'a') do |f|
        f.puts '---'
        f.puts "Time:      #{Time.now.utc.iso8601}"
        f.puts "Post ID:   #{post_id}"
        f.puts "URL:       https://www.flickr.com/photos/#{username}/#{post_id}/"
        f.puts "Error:     #{error.class}"
        f.puts "Message:   #{error.message}"
        f.puts
        f.puts
        f.puts
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
      profile_dir = File.join archive, 'Profile'

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
      when 'access_secret'     then config.access_secret = value
      when 'access_token'      then config.access_token = value
      when 'api_key'           then config.api_key = value
      when 'last_page_photos'  then config.last_page_photos = value.to_i
      when 'last_page_posts'   then config.last_page_posts = value.to_i
      when 'last_page_videos'  then config.last_page_videos = value.to_i
      when 'library_path'      then config.library_path = value
      when 'shared_secret'     then config.shared_secret = value
      when 'total_collections' then config.total_collections = value.to_i
      when 'total_photos'      then config.total_photos = value.to_i
      when 'total_sets'        then config.total_sets = value.to_i
      when 'total_videos'      then config.total_videos = value.to_i
      when 'user_nsid'         then config.user_nsid = value
      when 'username'          then config.username = value
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

    def print_help
      puts "flickarr version #{Flickarr::VERSION}"
      puts
      help_path = File.expand_path('../../HELP.txt', __dir__)
      puts File.read(help_path)
      puts
    end
  end
end
