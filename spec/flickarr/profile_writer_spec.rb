require 'down'
require 'json'
require 'tempfile'
require 'tmpdir'
require 'yaml'

RSpec.describe Flickarr::ProfileWriter do
  let(:archive_path) { Dir.mktmpdir('flickarr-profile-test') }
  let(:profile_dir) { File.join(archive_path, '_profile') }

  let(:profile) do
    instance_double(
      Flickarr::Profile,
      avatar_url:  'https://farm5.staticflickr.com/1234/buddyicons/12345678@N00.jpg',
      description: 'A photographer',
      iconfarm:    5,
      iconserver:  '1234',
      ispro:       1,
      location:    'Portland, OR',
      nsid:        '12345678@N00',
      path_alias:  'testuser',
      photosurl:   'https://www.flickr.com/photos/testuser/',
      profileurl:  'https://www.flickr.com/people/testuser/',
      realname:    'Test User',
      timezone:    { label: 'Pacific Time', offset: '-08:00' },
      to_h:        {
        avatar_url:  'https://farm5.staticflickr.com/1234/buddyicons/12345678@N00.jpg',
        description: 'A photographer',
        iconfarm:    5,
        iconserver:  '1234',
        ispro:       1,
        location:    'Portland, OR',
        nsid:        '12345678@N00',
        path_alias:  'testuser',
        photosurl:   'https://www.flickr.com/photos/testuser/',
        profileurl:  'https://www.flickr.com/people/testuser/',
        realname:    'Test User',
        timezone:    { label: 'Pacific Time', offset: '-08:00' },
        username:    'testuser'
      },
      username:    'testuser'
    )
  end

  let(:writer) { described_class.new(archive_path: archive_path, profile: profile) }

  after { FileUtils.rm_rf archive_path }

  describe '#write_json' do
    it 'writes profile.json to the _profile directory' do
      writer.write_json

      json_path = File.join(profile_dir, 'profile.json')
      expect(File.exist?(json_path)).to be true
    end

    it 'writes valid JSON with profile data' do
      writer.write_json

      json_path = File.join(profile_dir, 'profile.json')
      data = JSON.parse(File.read(json_path), symbolize_names: true)
      expect(data[:username]).to eq('testuser')
      expect(data[:location]).to eq('Portland, OR')
    end
  end

  describe '#write_yaml' do
    it 'writes profile.yaml to the _profile directory' do
      writer.write_yaml

      yaml_path = File.join(profile_dir, 'profile.yaml')
      expect(File.exist?(yaml_path)).to be true
    end

    it 'writes valid YAML with profile data' do
      writer.write_yaml

      yaml_path = File.join(profile_dir, 'profile.yaml')
      data = YAML.load_file(yaml_path, symbolize_names: true)
      expect(data[:username]).to eq('testuser')
      expect(data[:location]).to eq('Portland, OR')
    end
  end

  describe '#download_avatar' do
    let(:tempfile) do
      file = Tempfile.new(['avatar', '.jpg'])
      file.write('fake image data')
      file.rewind
      file
    end

    after { tempfile.close! }

    it 'downloads the avatar to the _profile directory' do
      allow(Down).to receive(:download).with(profile.avatar_url).and_return(tempfile)

      writer.download_avatar

      avatar_path = File.join(profile_dir, 'avatar.jpg')
      expect(File.exist?(avatar_path)).to be true
      expect(File.read(avatar_path)).to eq('fake image data')
    end

    it 'uses the extension from the avatar URL' do
      png_profile = instance_double(
        Flickarr::Profile,
        avatar_url: 'https://www.flickr.com/images/buddyicon.gif',
        to_h:       {}
      )
      png_writer = described_class.new(archive_path: archive_path, profile: png_profile)
      allow(Down).to receive(:download).with(png_profile.avatar_url).and_return(tempfile)

      png_writer.download_avatar

      avatar_path = File.join(profile_dir, 'avatar.gif')
      expect(File.exist?(avatar_path)).to be true
    end
  end

  describe '#write' do
    let(:tempfile) do
      file = Tempfile.new(['avatar', '.jpg'])
      file.write('fake image data')
      file.rewind
      file
    end

    before do
      allow(Down).to receive(:download).and_return(tempfile)
    end

    after { tempfile.close! }

    it 'creates the _profile directory' do
      writer.write

      expect(Dir.exist?(profile_dir)).to be true
    end

    it 'writes JSON, YAML, and avatar files' do
      writer.write

      expect(File.exist?(File.join(profile_dir, 'profile.json'))).to be true
      expect(File.exist?(File.join(profile_dir, 'profile.yaml'))).to be true
      expect(File.exist?(File.join(profile_dir, 'avatar.jpg'))).to be true
    end
  end
end
