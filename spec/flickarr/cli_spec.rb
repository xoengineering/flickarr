# rubocop:disable RSpec/VerifiedDoubles
require 'tmpdir'

RSpec.describe Flickarr::CLI do
  describe '#run' do
    it 'prints help when no command is given' do
      cli = described_class.new([])
      expect { cli.run }.to output(/USAGE/).to_stdout
    end

    it 'prints help for unknown commands' do
      cli = described_class.new(['bogus'])
      expect { cli.run }.to output(/USAGE/).to_stdout
    end

    it 'prints help for help command' do
      cli = described_class.new(['help'])
      expect { cli.run }.to output(/USAGE/).to_stdout
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
      expect { cli.run }.to output(String).to_stdout

      config = Flickarr::Config.load(path)
      expect(config.api_key).to eq('new-key')
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'sets multiple values at once' do
      dir = File.join(Dir.tmpdir, "flickarr-cli-test-#{Process.pid}")
      path = File.join(dir, 'config.yml')

      cli = described_class.new(['config:set', 'api_key=my-key', 'shared_secret=my-secret'], config_path: path)
      expect { cli.run }.to output(String).to_stdout

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
      expect { cli.run }.to output(String).to_stdout

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

  describe 'export:photos command' do
    it 'exports all photos from the timeline' do
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
      config.library_path = File.join(dir, 'library')
      config.save(config_path)

      flickr_instance = double('Flickr')
      allow(Flickr).to receive(:new).and_return(flickr_instance)
      allow(flickr_instance).to receive(:access_token=)
      allow(flickr_instance).to receive(:access_secret=)

      photos_api = double('photos')
      allow(flickr_instance).to receive(:photos).and_return(photos_api)

      list_photo = double('list_photo', id: '111', title: 'Test Photo', media: 'photo',
                                        originalformat: 'jpg', datetaken: '2024-03-15 14:30:00',
                                        datetakenunknown: '0', dateupload: '1710500000')
      list_response = double('list_response', pages: 1, total: 1)
      allow(list_response).to receive(:each).and_yield(list_photo)
      allow(photos_api).to receive(:search).and_return(list_response)

      dates = double('dates', taken: '2024-03-15 14:30:00', posted: '1710500000', takenunknown: 0, lastupdate: '1710600000')
      owner = double('owner', nsid: '123@N00', realname: 'Test User', username: 'testuser')
      vis = double('visibility', isfamily: 0, isfriend: 0, ispublic: 1)
      photo_url = double('url', type: 'photopage', to_s: 'https://www.flickr.com/photos/testuser/111/')

      info = double(
        'info',
        dates: dates, description: 'A photo', id: '111', license: '0', media: 'photo',
        originalformat: 'jpg', owner: owner, tags: double('tags', tag: []),
        title: 'Test Photo', urls: double('urls', url: [photo_url]), views: '5', visibility: vis
      )
      original = double('size', height: 1200, label: 'Original',
                                source: 'https://live.staticflickr.com/o.jpg', media: 'photo', width: 1600)
      sizes = double('sizes', size: [original])
      exif = double('exif', camera: 'Canon', exif: [])

      allow(photos_api).to receive_messages(getInfo: info, getSizes: sizes, getExif: exif)
      allow(Down).to receive(:download)

      cli = described_class.new(['export:photos'], config_path: config_path)
      expect { cli.run }.to output(%r{Downloaded photo 111.*1/1}).to_stdout
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'reports error when not authenticated' do
      cli = described_class.new(['export:photos'], config_path: '/tmp/nonexistent-flickarr.yml')
      expect { cli.run }.to output(/Not authenticated/).to_stderr
    end

    it 'respects --limit flag' do
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
      config.library_path = File.join(dir, 'library')
      config.save(config_path)

      flickr_instance = double('Flickr')
      allow(Flickr).to receive(:new).and_return(flickr_instance)
      allow(flickr_instance).to receive(:access_token=)
      allow(flickr_instance).to receive(:access_secret=)

      photos_api = double('photos')
      allow(flickr_instance).to receive(:photos).and_return(photos_api)

      first_photo = double('first_photo', id: '111', title: 'Photo', media: 'photo',
                                          originalformat: 'jpg', datetaken: '2024-03-15 14:30:00',
                                          datetakenunknown: '0', dateupload: '1710500000')
      second_photo = double('second_photo', id: '222', title: 'Photo', media: 'photo',
                                            originalformat: 'jpg', datetaken: '2024-03-15 14:30:00',
                                            datetakenunknown: '0', dateupload: '1710500000')
      list_response = double('list_response', pages: 1, total: 2)
      allow(list_response).to receive(:each).and_yield(first_photo).and_yield(second_photo)
      allow(photos_api).to receive(:search).and_return(list_response)

      dates = double('dates', taken: '2024-03-15 14:30:00', posted: '1710500000', takenunknown: 0, lastupdate: '1710600000')
      owner = double('owner', nsid: '123@N00', realname: 'Test', username: 'testuser')
      vis = double('visibility', isfamily: 0, isfriend: 0, ispublic: 1)
      photo_url = double('url', type: 'photopage', to_s: 'https://www.flickr.com/photos/testuser/111/')

      info = double(
        'info',
        dates: dates, description: 'A', id: '111', license: '0', media: 'photo',
        originalformat: 'jpg', owner: owner, tags: double('tags', tag: []),
        title: 'Photo', urls: double('urls', url: [photo_url]), views: '0', visibility: vis
      )
      original = double('size', height: 1200, label: 'Original',
                                source: 'https://live.staticflickr.com/o.jpg', media: 'photo', width: 1600)
      sizes = double('sizes', size: [original])
      exif = double('exif', camera: 'Canon', exif: [])

      allow(photos_api).to receive_messages(getInfo: info, getSizes: sizes, getExif: exif)
      allow(Down).to receive(:download)

      cli = described_class.new(['export:photos', '--limit', '1'], config_path: config_path)
      expect { cli.run }.to output(/Reached limit of 1 posts/).to_stdout
    ensure
      FileUtils.rm_rf(dir)
    end
  end

  describe 'export:collections command' do
    it 'exports all collections' do
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

      collections_api = double('collections')
      allow(flickr_instance).to receive(:collections).and_return(collections_api)

      set_ref = double('set_ref', description: '', id: '111', title: 'My Set')
      collection_data = double(
        'collection',
        description: 'A collection',
        iconlarge:   '',
        iconsmall:   '',
        id:          '375727-123',
        set:         [set_ref],
        title:       'My Collection'
      )
      tree_response = double('tree')
      allow(tree_response).to receive(:each).and_yield(collection_data)
      allow(collections_api).to receive(:getTree).and_return(tree_response)

      cli = described_class.new(['export:collections'], config_path: config_path)
      expect { cli.run }.to output(/My Collection.*Downloaded to/m).to_stdout

      expect(Dir.exist?(File.join(archive_path, 'Collections', '375727-123_my-collection'))).to be true
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'reports error when not authenticated' do
      cli = described_class.new(['export:collections'], config_path: '/tmp/nonexistent-flickarr.yml')
      expect { cli.run }.to output(/Not authenticated/).to_stderr
    end
  end

  describe 'export:sets command' do
    it 'exports all sets' do
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

      photosets_api = double('photosets')
      allow(flickr_instance).to receive(:photosets).and_return(photosets_api)

      set_data = double(
        'set',
        count_comments: '0', count_photos: 1, count_videos: 0, count_views: '0',
        date_create: '1615022202', date_update: '1615023685',
        description: '', id: '72157718538273371', owner: '123@N00',
        primary: '12345', title: 'My Set', username: 'testuser'
      )
      sets_response = double('sets_response', total: 1)
      allow(sets_response).to receive(:each).and_yield(set_data)

      photo_item = double(
        'photo_item',
        datetaken: '2024-03-15 14:30:00', datetakenunknown: '0', dateupload: '1710500000',
        description: 'A photo', id: '12345', isprimary: '1', media: 'photo',
        originalformat: 'jpg', tags: '', title: 'Test'
      )
      photos_response = double('photos_response', photo: [photo_item])
      allow(photosets_api).to receive_messages(getList: sets_response, getPhotos: photos_response)

      cli = described_class.new(['export:sets'], config_path: config_path)
      expect { cli.run }.to output(/My Set.*Downloaded to/m).to_stdout

      expect(Dir.exist?(File.join(archive_path, 'Sets', '72157718538273371_my-set'))).to be true
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'reports error when not authenticated' do
      cli = described_class.new(['export:sets'], config_path: '/tmp/nonexistent-flickarr.yml')
      expect { cli.run }.to output(/Not authenticated/).to_stderr
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

      dates = double('dates', taken: '2024-03-15 14:30:00', posted: '1710500000', takenunknown: 0, lastupdate: '1710600000')
      owner = double('owner', nsid: '123@N00', realname: 'Test User', username: 'testuser')
      visibility = double('visibility', isfamily: 0, isfriend: 0, ispublic: 1)
      photo_url = double('url', type: 'photopage', to_s: 'https://www.flickr.com/photos/testuser/3839885270/')
      info_response = double(
        'info',
        dates:          dates,
        description:    'A cat',
        id:             '3839885270',
        license:        '0',
        media:          'photo',
        originalformat: 'jpg',
        owner:          owner,
        tags:           double('tags', tag: []),
        title:          'My Cat',
        urls:           double('urls', url: [photo_url]),
        views:          '0',
        visibility:     visibility
      )
      original = double('size', height: 1200, label: 'Original', source: 'https://live.staticflickr.com/o.jpg',
                                media: 'photo', width: 1600)
      sizes_response = double('sizes', size: [original])
      exif_response = double('exif_response', camera: 'Canon', exif: [])

      allow(photos_api).to receive(:getInfo).with(photo_id: '3839885270').and_return(info_response)
      allow(photos_api).to receive(:getSizes).with(photo_id: '3839885270').and_return(sizes_response)
      allow(photos_api).to receive(:getExif).with(photo_id: '3839885270').and_return(exif_response)
      allow(Down).to receive(:download)

      url = 'https://www.flickr.com/photos/testuser/3839885270'
      cli = described_class.new(['export:photo', url], config_path: config_path)
      expect { cli.run }.to output(/Downloaded photo 3839885270/).to_stdout

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
      expect { cli.run }.to output(/Could not extract post ID/).to_stderr
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'reports error when Flickr API rejects the photo ID' do
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
      config.library_path = File.join(dir, 'library')
      config.save(config_path)

      flickr_instance = double('Flickr')
      allow(Flickr).to receive(:new).and_return(flickr_instance)
      allow(flickr_instance).to receive(:access_token=)
      allow(flickr_instance).to receive(:access_secret=)

      photos_api = double('photos')
      allow(flickr_instance).to receive(:photos).and_return(photos_api)
      allow(photos_api).to receive(:getInfo)
        .and_raise(Flickr::FailedResponse.new('Photo not found (invalid ID)', '1', 'flickr.photos.getInfo'))

      url = 'https://www.flickr.com/photos/testuser/9999999999'
      cli = described_class.new(['export:photo', url], config_path: config_path)
      expect { cli.run }.to output(/Photo not found/).to_stderr
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
      profile_api = double('profile_api')
      allow(flickr_instance).to receive_messages(people: people_api, profile: profile_api)

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
      profile_response = double(
        'profile_response',
        city: '', country: '', email: '', facebook: '', first_name: 'Test',
        hometown: '', instagram: '', join_date: '1110764731', last_name: 'User',
        occupation: '', pinterest: '', tumblr: '', twitter: '', website: ''
      )
      allow(people_api).to receive(:getInfo).with(user_id: '123@N00').and_return(person_response)
      allow(profile_api).to receive(:getProfile).with(user_id: '123@N00').and_return(profile_response)
      allow(Down).to receive(:download)

      cli = described_class.new(['export:profile'], config_path: config_path)
      expect { cli.run }.to output(/Downloaded profile to/).to_stdout

      expect(File.exist?(File.join(archive_path, 'Profile', 'profile.json'))).to be true
      expect(File.exist?(File.join(archive_path, 'Profile', 'profile.yaml'))).to be true
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
      expect { cli.run }.to output(String).to_stdout

      config = Flickarr::Config.load(path)
      expect(config.library_path).to eq('/custom/photos')
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'uses default library_path when none provided' do
      dir = File.join(Dir.tmpdir, "flickarr-init-test-#{Process.pid}")
      path = File.join(dir, 'config.yml')

      cli = described_class.new(['init'], config_path: path)
      expect { cli.run }.to output(String).to_stdout

      config = Flickarr::Config.load(path)
      expect(config.library_path).to eq(File.join(Dir.home, 'Pictures', 'Flickarr'))
    ensure
      FileUtils.rm_rf(dir)
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
