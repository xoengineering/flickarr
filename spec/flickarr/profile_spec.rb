# rubocop:disable RSpec/VerifiedDoubles
require 'down'
require 'json'
require 'tmpdir'
require 'yaml'

RSpec.describe Flickarr::Profile do
  let(:person_response) do
    double(
      'person',
      description:  'A photographer',
      iconfarm:     5,
      iconserver:   '1234',
      id:           '12345678@N00',
      ispro:        1,
      location:     'Portland, OR',
      nsid:         '12345678@N00',
      path_alias:   'testuser',
      photosurl:    'https://www.flickr.com/photos/testuser/',
      profileurl:   'https://www.flickr.com/people/testuser/',
      realname:     'Test User',
      timezone:     double('timezone', label: 'Pacific Time', offset: '-08:00'),
      upload_count: 1337,
      username:     'testuser'
    )
  end

  let(:profile_response) do
    double(
      'profile',
      city:       'San Francisco',
      country:    'USA',
      email:      'test@example.com',
      facebook:   '',
      first_name: 'Test',
      hometown:   'Portland',
      instagram:  'testuser',
      join_date:  '1110764731',
      last_name:  'User',
      occupation: 'Developer',
      pinterest:  '',
      tumblr:     '',
      twitter:    'testuser',
      website:    'https://example.com'
    )
  end

  let(:profile) { described_class.new(person: person_response, profile: profile_response) }

  describe '#initialize' do
    it 'extracts description' do
      expect(profile.description).to eq('A photographer')
    end

    it 'extracts iconfarm' do
      expect(profile.iconfarm).to eq(5)
    end

    it 'extracts iconserver' do
      expect(profile.iconserver).to eq('1234')
    end

    it 'extracts ispro' do
      expect(profile.ispro).to eq(1)
    end

    it 'extracts location' do
      expect(profile.location).to eq('Portland, OR')
    end

    it 'extracts nsid' do
      expect(profile.nsid).to eq('12345678@N00')
    end

    it 'extracts path_alias' do
      expect(profile.path_alias).to eq('testuser')
    end

    it 'extracts photosurl' do
      expect(profile.photosurl).to eq('https://www.flickr.com/photos/testuser/')
    end

    it 'extracts profileurl' do
      expect(profile.profileurl).to eq('https://www.flickr.com/people/testuser/')
    end

    it 'extracts realname' do
      expect(profile.realname).to eq('Test User')
    end

    it 'extracts timezone' do
      expect(profile.timezone).to eq(label: 'Pacific Time', offset: '-08:00')
    end

    it 'extracts upload_count' do
      expect(profile.upload_count).to eq(1337)
    end

    it 'extracts username' do
      expect(profile.username).to eq('testuser')
    end
  end

  describe 'profile fields' do
    it 'extracts city' do
      expect(profile.city).to eq('San Francisco')
    end

    it 'extracts country' do
      expect(profile.country).to eq('USA')
    end

    it 'extracts email' do
      expect(profile.email).to eq('test@example.com')
    end

    it 'extracts first_name' do
      expect(profile.first_name).to eq('Test')
    end

    it 'extracts hometown' do
      expect(profile.hometown).to eq('Portland')
    end

    it 'extracts instagram' do
      expect(profile.instagram).to eq('testuser')
    end

    it 'extracts join_date' do
      expect(profile.join_date).to eq('1110764731')
    end

    it 'extracts last_name' do
      expect(profile.last_name).to eq('User')
    end

    it 'extracts occupation' do
      expect(profile.occupation).to eq('Developer')
    end

    it 'extracts twitter' do
      expect(profile.twitter).to eq('testuser')
    end

    it 'extracts website' do
      expect(profile.website).to eq('https://example.com')
    end
  end

  describe 'without profile response' do
    let(:profile) { described_class.new(person: person_response) }

    it 'still works with just person data' do
      expect(profile.username).to eq('testuser')
      expect(profile.city).to be_nil
      expect(profile.website).to be_nil
    end
  end

  describe '#avatar_url' do
    it 'builds the buddy icon URL from iconfarm, iconserver, and nsid' do
      expect(profile.avatar_url).to eq('https://farm5.staticflickr.com/1234/buddyicons/12345678@N00_r.jpg')
    end

    context 'when iconserver is 0' do
      let(:person_response) do
        double(
          'person',
          description: '',
          iconfarm:    0,
          iconserver:  '0',
          id:          '12345678@N00',
          ispro:       0,
          location:    '',
          nsid:        '12345678@N00',
          path_alias:  nil,
          photosurl:   '',
          profileurl:  '',
          realname:    '',
          timezone:    double('timezone', label: '', offset: ''),
          username:    'testuser'
        )
      end

      it 'returns the default buddy icon URL' do
        expect(profile.avatar_url).to eq('https://www.flickr.com/images/buddyicon.gif')
      end
    end
  end

  describe '#to_h' do
    it 'returns a hash of all profile attributes' do
      hash = profile.to_h

      expect(hash[:avatar_url]).to eq('https://farm5.staticflickr.com/1234/buddyicons/12345678@N00_r.jpg')
      expect(hash[:city]).to eq('San Francisco')
      expect(hash[:description]).to eq('A photographer')
      expect(hash[:first_name]).to eq('Test')
      expect(hash[:location]).to eq('Portland, OR')
      expect(hash[:nsid]).to eq('12345678@N00')
      expect(hash[:realname]).to eq('Test User')
      expect(hash[:username]).to eq('testuser')
      expect(hash[:website]).to eq('https://example.com')
    end
  end

  describe '#write_json' do
    let(:archive_path) { Dir.mktmpdir('flickarr-profile-test') }
    let(:profile_dir) { File.join(archive_path, '_profile') }

    after { FileUtils.rm_rf archive_path }

    it 'writes profile.json to the _profile directory' do
      profile.write_json(dir: profile_dir)

      expect(File.exist?(File.join(profile_dir, 'profile.json'))).to be true
    end

    it 'writes valid JSON with profile data' do
      profile.write_json(dir: profile_dir)

      data = JSON.parse(File.read(File.join(profile_dir, 'profile.json')), symbolize_names: true)
      expect(data[:username]).to eq('testuser')
      expect(data[:location]).to eq('Portland, OR')
    end
  end

  describe '#write_yaml' do
    let(:archive_path) { Dir.mktmpdir('flickarr-profile-test') }
    let(:profile_dir) { File.join(archive_path, '_profile') }

    after { FileUtils.rm_rf archive_path }

    it 'writes profile.yaml to the _profile directory' do
      profile.write_yaml(dir: profile_dir)

      expect(File.exist?(File.join(profile_dir, 'profile.yaml'))).to be true
    end

    it 'writes valid YAML with profile data' do
      profile.write_yaml(dir: profile_dir)

      data = YAML.load_file(File.join(profile_dir, 'profile.yaml'), symbolize_names: true)
      expect(data[:username]).to eq('testuser')
      expect(data[:location]).to eq('Portland, OR')
    end
  end

  describe '#download_avatar' do
    let(:archive_path) { Dir.mktmpdir('flickarr-profile-test') }
    let(:profile_dir) { File.join(archive_path, '_profile') }

    after { FileUtils.rm_rf archive_path }

    it 'downloads the avatar to the _profile directory' do
      avatar_path = File.join(profile_dir, 'avatar.jpg')
      allow(Down).to receive(:download)
        .with(profile.avatar_url, destination: avatar_path)

      profile.download_avatar(archive_path: archive_path)

      expect(Down).to have_received(:download)
        .with(profile.avatar_url, destination: avatar_path)
    end
  end

  describe '#write' do
    let(:archive_path) { Dir.mktmpdir('flickarr-profile-test') }
    let(:profile_dir) { File.join(archive_path, '_profile') }

    before { allow(Down).to receive(:download) }

    after { FileUtils.rm_rf archive_path }

    it 'creates the _profile directory' do
      profile.write(archive_path: archive_path)

      expect(Dir.exist?(profile_dir)).to be true
    end

    it 'writes JSON, YAML, and downloads avatar' do
      result = profile.write(archive_path: archive_path)

      expect(result).to eq(:created)
      expect(File.exist?(File.join(profile_dir, 'profile.json'))).to be true
      expect(File.exist?(File.join(profile_dir, 'profile.yaml'))).to be true
      expect(Down).to have_received(:download)
    end

    it 'skips when profile.json already exists' do
      FileUtils.mkdir_p profile_dir
      File.write File.join(profile_dir, 'profile.json'), 'existing'

      result = profile.write(archive_path: archive_path)

      expect(result).to eq(:skipped)
      expect(Down).not_to have_received(:download)
    end

    it 'overwrites when overwrite: true' do
      FileUtils.mkdir_p profile_dir
      File.write File.join(profile_dir, 'profile.json'), 'existing'

      result = profile.write(archive_path: archive_path, overwrite: true)

      expect(result).to eq(:overwritten)
      expect(Down).to have_received(:download)
      expect(File.exist?(File.join(profile_dir, 'profile.yaml'))).to be true
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
