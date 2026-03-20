# rubocop:disable RSpec/VerifiedDoubles
RSpec.describe Flickarr::Client do
  let(:config) do
    c = Flickarr::Config.new
    c.api_key = 'test-api-key'
    c.shared_secret = 'test-shared-secret'
    c
  end

  describe '#initialize' do
    it 'creates a Flickr client with config credentials' do
      flickr_instance = instance_double(Flickr)
      allow(Flickr).to receive(:new).with('test-api-key', 'test-shared-secret').and_return(flickr_instance)

      client = described_class.new(config)

      expect(client.flickr).to eq(flickr_instance)
    end

    it 'sets access tokens when present in config' do
      config.access_token = 'my-token'
      config.access_secret = 'my-secret'

      flickr_instance = instance_double(Flickr, :access_token= => nil, :access_secret= => nil)
      allow(Flickr).to receive(:new).and_return(flickr_instance)

      described_class.new(config)

      expect(flickr_instance).to have_received(:access_token=).with('my-token')
      expect(flickr_instance).to have_received(:access_secret=).with('my-secret')
    end

    it 'raises ConfigError when api_key is nil' do
      config.api_key = nil

      expect { described_class.new(config) }.to raise_error(Flickarr::ConfigError, /api_key/)
    end

    it 'raises ConfigError when api_key is blank' do
      config.api_key = ''

      expect { described_class.new(config) }.to raise_error(Flickarr::ConfigError, /api_key/)
    end

    it 'raises ConfigError when shared_secret is nil' do
      config.shared_secret = nil

      expect { described_class.new(config) }.to raise_error(Flickarr::ConfigError, /shared_secret/)
    end

    it 'raises ConfigError when shared_secret is blank' do
      config.shared_secret = ''

      expect { described_class.new(config) }.to raise_error(Flickarr::ConfigError, /shared_secret/)
    end
  end

  describe '#photo' do
    let(:flickr_instance) { double('Flickr') }
    let(:client) do
      allow(Flickr).to receive(:new).and_return(flickr_instance)
      described_class.new(config)
    end

    it 'returns a PhotoQuery for the given id' do
      query = client.photo(id: '3839885270')

      expect(query).to be_a(Flickarr::Client::PhotoQuery)
    end
  end

  describe '#profile' do
    let(:flickr_instance) { double('Flickr') }
    let(:client) do
      allow(Flickr).to receive(:new).and_return(flickr_instance)
      described_class.new(config)
    end

    it 'returns a ProfileQuery for the given user_id' do
      query = client.profile(user_id: '12345@N00')

      expect(query).to be_a(Flickarr::Client::ProfileQuery)
    end
  end

  describe '#photos' do
    let(:flickr_instance) { double('Flickr') }
    let(:people_api) { double('people') }
    let(:client) do
      allow(Flickr).to receive(:new).and_return(flickr_instance)
      described_class.new(config)
    end

    before do
      allow(flickr_instance).to receive(:people).and_return(people_api)
    end

    it 'calls flickr.people.getPhotos with user_id, page, per_page, and extras' do
      photos_response = double('photos')
      allow(people_api).to receive(:getPhotos)
        .with(user_id: '123@N00', page: 1, per_page: 100, extras: Flickarr::Client::PHOTO_EXTRAS)
        .and_return(photos_response)

      result = client.photos(user_id: '123@N00', page: 1, per_page: 100)

      expect(result).to eq(photos_response)
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
