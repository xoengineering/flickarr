RSpec.describe Flickarr::Profile do
  let(:person_response) do
    double( # rubocop:disable RSpec/VerifiedDoubles
      'person',
      id:          '12345678@N00',
      nsid:        '12345678@N00',
      username:    'testuser',
      realname:    'Test User',
      description: 'A photographer',
      location:    'Portland, OR',
      iconserver:  '1234',
      iconfarm:    5,
      ispro:       1,
      path_alias:  'testuser',
      photosurl:   'https://www.flickr.com/photos/testuser/',
      profileurl:  'https://www.flickr.com/people/testuser/',
      timezone:    double('timezone', label: 'Pacific Time', offset: '-08:00') # rubocop:disable RSpec/VerifiedDoubles
    )
  end

  let(:profile) { described_class.new(person_response) }

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

    it 'extracts username' do
      expect(profile.username).to eq('testuser')
    end
  end

  describe '#avatar_url' do
    it 'builds the buddy icon URL from iconfarm, iconserver, and nsid' do
      expect(profile.avatar_url).to eq('https://farm5.staticflickr.com/1234/buddyicons/12345678@N00.jpg')
    end

    context 'when iconserver is 0' do
      let(:person_response) do
        double( # rubocop:disable RSpec/VerifiedDoubles
          'person',
          id:          '12345678@N00',
          nsid:        '12345678@N00',
          username:    'testuser',
          realname:    '',
          description: '',
          iconserver:  '0',
          iconfarm:    0,
          ispro:       0,
          location:    '',
          path_alias:  nil,
          photosurl:   '',
          profileurl:  '',
          timezone:    double('timezone', label: '', offset: '') # rubocop:disable RSpec/VerifiedDoubles
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

      expect(hash[:avatar_url]).to eq('https://farm5.staticflickr.com/1234/buddyicons/12345678@N00.jpg')
      expect(hash[:description]).to eq('A photographer')
      expect(hash[:location]).to eq('Portland, OR')
      expect(hash[:nsid]).to eq('12345678@N00')
      expect(hash[:realname]).to eq('Test User')
      expect(hash[:username]).to eq('testuser')
    end
  end
end
