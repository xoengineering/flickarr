# rubocop:disable RSpec/VerifiedDoubles
require 'tmpdir'

RSpec.describe Flickarr::CLI do
  describe '#run' do
    it 'prints usage when no command is given' do
      cli = described_class.new([])
      expect { cli.run }.to output(/Usage:/).to_stdout
    end

    it 'prints usage for unknown commands' do
      cli = described_class.new(['bogus'])
      expect { cli.run }.to output(/Usage:/).to_stdout
    end
  end

  describe 'config' do
    it 'displays all config values' do
      dir = File.join(Dir.tmpdir, "flickarr-cli-test-#{Process.pid}")
      path = File.join(dir, 'config.yml')
      FileUtils.mkdir_p(dir)
      config = Flickarr::Config.new
      config.api_key = 'my-key'
      config.save(path)

      cli = described_class.new(['config'], config_path: path)
      expect { cli.run }.to output(/api_key\s+my-key/).to_stdout
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'displays a single config value by key' do
      dir = File.join(Dir.tmpdir, "flickarr-cli-test-#{Process.pid}")
      path = File.join(dir, 'config.yml')
      FileUtils.mkdir_p(dir)
      config = Flickarr::Config.new
      config.api_key = 'my-key'
      config.shared_secret = 'my-secret'
      config.save(path)

      cli = described_class.new(%w[config api_key], config_path: path)
      expect { cli.run }.to output("my-key\n").to_stdout
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'reports when no config file exists' do
      cli = described_class.new(['config'], config_path: '/tmp/nonexistent-flickarr.yml')
      expect { cli.run }.to output(/No config file found/).to_stdout
    end
  end

  describe 'config:set' do
    it 'sets a single value with key=value syntax' do
      dir = File.join(Dir.tmpdir, "flickarr-cli-test-#{Process.pid}")
      path = File.join(dir, 'config.yml')

      cli = described_class.new(['config:set', 'api_key=new-key'], config_path: path)
      cli.run

      config = Flickarr::Config.load(path)
      expect(config.api_key).to eq('new-key')
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'sets multiple values at once' do
      dir = File.join(Dir.tmpdir, "flickarr-cli-test-#{Process.pid}")
      path = File.join(dir, 'config.yml')

      cli = described_class.new(['config:set', 'api_key=my-key', 'shared_secret=my-secret'], config_path: path)
      cli.run

      config = Flickarr::Config.load(path)
      expect(config.api_key).to eq('my-key')
      expect(config.shared_secret).to eq('my-secret')
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'preserves existing values when setting new ones' do
      dir = File.join(Dir.tmpdir, "flickarr-cli-test-#{Process.pid}")
      path = File.join(dir, 'config.yml')
      FileUtils.mkdir_p(dir)
      config = Flickarr::Config.new
      config.api_key = 'existing-key'
      config.save(path)

      cli = described_class.new(['config:set', 'shared_secret=my-secret'], config_path: path)
      cli.run

      config = Flickarr::Config.load(path)
      expect(config.api_key).to eq('existing-key')
      expect(config.shared_secret).to eq('my-secret')
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'prints the full config after setting' do
      dir = File.join(Dir.tmpdir, "flickarr-cli-test-#{Process.pid}")
      path = File.join(dir, 'config.yml')

      cli = described_class.new(['config:set', 'api_key=my-key'], config_path: path)
      expect { cli.run }.to output(/api_key\s+my-key/).to_stdout
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'rejects unknown config keys' do
      dir = File.join(Dir.tmpdir, "flickarr-cli-test-#{Process.pid}")
      path = File.join(dir, 'config.yml')

      cli = described_class.new(['config:set', 'bogus_key=value'], config_path: path)
      expect { cli.run }.to output(/Unknown config key: bogus_key/).to_stdout
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'prints usage when no key=value pairs given' do
      cli = described_class.new(['config:set'], config_path: '/tmp/whatever.yml')
      expect { cli.run }.to output(/Usage:.*config:set/).to_stdout
    end
  end

  describe 'auth command' do
    it 'runs the OAuth flow' do
      dir = File.join(Dir.tmpdir, "flickarr-cli-test-#{Process.pid}")
      config_path = File.join(dir, 'config.yml')
      FileUtils.mkdir_p(dir)

      config = Flickarr::Config.new
      config.api_key = 'test-key'
      config.shared_secret = 'test-secret'
      config.save(config_path)

      flickr_instance = double(
        'Flickr',
        access_token:    nil,
        :access_token= => nil,
        access_secret:   nil,
        :access_secret= => nil
      )
      allow(Flickr).to receive(:new).and_return(flickr_instance)

      request_token = { 'oauth_token' => 'req-token', 'oauth_token_secret' => 'req-secret' }
      login = double('login', id: '123@N00', username: 'testuser')
      test_namespace = double('test', login: login)
      allow(flickr_instance).to receive_messages(get_request_token: request_token, test: test_namespace)
      allow(flickr_instance).to receive(:get_access_token)
      allow(flickr_instance).to receive_messages(get_authorize_url: 'https://flickr.com/auth', access_token: 'access-token',
                                                 access_secret: 'access-secret')

      cli = described_class.new(['auth'], config_path: config_path)
      allow_any_instance_of(Flickarr::Auth).to receive(:prompt_for_verifier).and_return('12345') # rubocop:disable RSpec/AnyInstance

      expect { cli.run }.to output(/Authenticated as testuser/).to_stdout
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'reports error when config is missing api credentials' do
      cli = described_class.new(['auth'], config_path: '/tmp/nonexistent-flickarr.yml')

      expect { cli.run }.to output(/api_key/).to_stderr
    end
  end

  describe 'export:photo command' do
    it 'exports a single photo by Flickr URL' do
      dir = File.join(Dir.tmpdir, "flickarr-cli-test-#{Process.pid}")
      config_path = File.join(dir, 'config.yml')
      archive_path = File.join(dir, 'library', 'testuser')
      FileUtils.mkdir_p(dir)

      config = Flickarr::Config.new
      config.api_key = 'test-key'
      config.shared_secret = 'test-secret'
      config.access_token = 'token'
      config.access_secret = 'secret'
      config.user_nsid = '123@N00'
      config.username = 'testuser'
      config.library_path = File.join(dir, 'library')
      config.save(config_path)

      flickr_instance = double('Flickr')
      allow(Flickr).to receive(:new).and_return(flickr_instance)
      allow(flickr_instance).to receive(:access_token=)
      allow(flickr_instance).to receive(:access_secret=)

      photos_api = double('photos')
      allow(flickr_instance).to receive(:photos).and_return(photos_api)

      dates = double('dates', taken: '2024-03-15 14:30:00', posted: '1710500000', takenunknown: 0)
      info_response = double(
        'info',
        id:             '3839885270',
        dates:          dates,
        description:    'A cat',
        media:          'photo',
        originalformat: 'jpg',
        tags:           double('tags', tag: []),
        title:          'My Cat'
      )
      original = double('size', label: 'Original', source: 'https://live.staticflickr.com/o.jpg', media: 'photo')
      sizes_response = double('sizes', size: [original])

      allow(photos_api).to receive(:getInfo).with(photo_id: '3839885270').and_return(info_response)
      allow(photos_api).to receive(:getSizes).with(photo_id: '3839885270').and_return(sizes_response)
      allow(Down).to receive(:download)

      url = 'https://www.flickr.com/photos/testuser/3839885270'
      cli = described_class.new(['export:photo', url], config_path: config_path)
      expect { cli.run }.to output(/Exported photo 3839885270/).to_stdout

      expect(File.exist?(File.join(archive_path, '2024/03/15', '3839885270_my-cat.json'))).to be true
      expect(File.exist?(File.join(archive_path, '2024/03/15', '3839885270_my-cat.yaml'))).to be true
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'reports error for invalid URL' do
      dir = File.join(Dir.tmpdir, "flickarr-cli-test-#{Process.pid}")
      config_path = File.join(dir, 'config.yml')
      FileUtils.mkdir_p(dir)

      config = Flickarr::Config.new
      config.api_key = 'test-key'
      config.shared_secret = 'test-secret'
      config.access_token = 'token'
      config.access_secret = 'secret'
      config.user_nsid = '123@N00'
      config.username = 'testuser'
      config.save(config_path)

      cli = described_class.new(['export:photo', 'https://example.com/bad'], config_path: config_path)
      expect { cli.run }.to output(/Could not extract photo ID/).to_stderr
    ensure
      FileUtils.rm_rf(dir)
    end
  end

  describe 'export:profile command' do
    it 'fetches profile info and writes to archive' do
      dir = File.join(Dir.tmpdir, "flickarr-cli-test-#{Process.pid}")
      config_path = File.join(dir, 'config.yml')
      archive_path = File.join(dir, 'library', 'testuser')
      FileUtils.mkdir_p(dir)

      config = Flickarr::Config.new
      config.api_key = 'test-key'
      config.shared_secret = 'test-secret'
      config.access_token = 'token'
      config.access_secret = 'secret'
      config.user_nsid = '123@N00'
      config.username = 'testuser'
      config.library_path = File.join(dir, 'library')
      config.save(config_path)

      flickr_instance = double('Flickr')
      allow(Flickr).to receive(:new).and_return(flickr_instance)
      allow(flickr_instance).to receive(:access_token=)
      allow(flickr_instance).to receive(:access_secret=)

      people_api = double('people')
      allow(flickr_instance).to receive(:people).and_return(people_api)

      person_response = double(
        'person',
        description: 'A photographer',
        iconfarm:    5,
        iconserver:  '1234',
        id:          '123@N00',
        ispro:       1,
        location:    'Portland, OR',
        nsid:        '123@N00',
        path_alias:  'testuser',
        photosurl:   'https://www.flickr.com/photos/testuser/',
        profileurl:  'https://www.flickr.com/people/testuser/',
        realname:    'Test User',
        timezone:    double('timezone', label: 'Pacific Time', offset: '-08:00'),
        username:    'testuser'
      )
      allow(people_api).to receive(:getInfo).with(user_id: '123@N00').and_return(person_response)
      allow(Down).to receive(:download)

      cli = described_class.new(['export:profile'], config_path: config_path)
      expect { cli.run }.to output(/Exported profile to/).to_stdout

      expect(File.exist?(File.join(archive_path, '_profile', 'profile.json'))).to be true
      expect(File.exist?(File.join(archive_path, '_profile', 'profile.yaml'))).to be true
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'reports error when not authenticated' do
      dir = File.join(Dir.tmpdir, "flickarr-cli-test-#{Process.pid}")
      config_path = File.join(dir, 'config.yml')
      FileUtils.mkdir_p(dir)

      config = Flickarr::Config.new
      config.api_key = 'test-key'
      config.shared_secret = 'test-secret'
      config.save(config_path)

      cli = described_class.new(['export:profile'], config_path: config_path)
      expect { cli.run }.to output(/Not authenticated/).to_stderr
    ensure
      FileUtils.rm_rf(dir)
    end
  end

  describe 'init command' do
    it 'creates the config directory and stub config file' do
      dir = File.join(Dir.tmpdir, "flickarr-init-test-#{Process.pid}")
      path = File.join(dir, 'config.yml')

      cli = described_class.new(['init'], config_path: path)
      expect { cli.run }.to output(/Initialized/).to_stdout

      expect(File.exist?(path)).to be(true)

      config = Flickarr::Config.load(path)
      expect(config.api_key).to be_nil
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'does not overwrite an existing config file' do
      dir = File.join(Dir.tmpdir, "flickarr-init-test-#{Process.pid}")
      path = File.join(dir, 'config.yml')
      FileUtils.mkdir_p(dir)
      config = Flickarr::Config.new
      config.api_key = 'existing-key'
      config.save(path)

      cli = described_class.new(['init'], config_path: path)
      expect { cli.run }.to output(/already exists/).to_stdout

      config = Flickarr::Config.load(path)
      expect(config.api_key).to eq('existing-key')
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'sets a custom library_path when provided' do
      dir = File.join(Dir.tmpdir, "flickarr-init-test-#{Process.pid}")
      path = File.join(dir, 'config.yml')

      cli = described_class.new(['init', '/custom/photos'], config_path: path)
      cli.run

      config = Flickarr::Config.load(path)
      expect(config.library_path).to eq('/custom/photos')
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'uses default library_path when none provided' do
      dir = File.join(Dir.tmpdir, "flickarr-init-test-#{Process.pid}")
      path = File.join(dir, 'config.yml')

      cli = described_class.new(['init'], config_path: path)
      cli.run

      config = Flickarr::Config.load(path)
      expect(config.library_path).to eq(File.join(Dir.home, 'Pictures', 'Flickarr'))
    ensure
      FileUtils.rm_rf(dir)
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
