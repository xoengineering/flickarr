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

  describe '#person_info' do
    # Flickr gem uses dynamic method dispatch, so verified doubles won't work
    let(:flickr_instance) { double('Flickr') } # rubocop:disable RSpec/VerifiedDoubles
    let(:people_api) { double('people') } # rubocop:disable RSpec/VerifiedDoubles
    let(:client) do
      allow(Flickr).to receive(:new).and_return(flickr_instance)
      described_class.new(config)
    end

    before do
      allow(flickr_instance).to receive(:people).and_return(people_api)
    end

    it 'calls flickr.people.getInfo with the given nsid' do
      person_response = double('person') # rubocop:disable RSpec/VerifiedDoubles
      allow(people_api).to receive(:getInfo).with(user_id: '12345@N00').and_return(person_response)

      result = client.person_info(user_id: '12345@N00')

      expect(result).to eq(person_response)
    end
  end

  describe '#photos' do
    # Flickr gem uses dynamic method dispatch, so verified doubles won't work
    let(:flickr_instance) { double('Flickr') } # rubocop:disable RSpec/VerifiedDoubles
    let(:people_api) { double('people') } # rubocop:disable RSpec/VerifiedDoubles
    let(:client) do
      allow(Flickr).to receive(:new).and_return(flickr_instance)
      described_class.new(config)
    end

    before do
      allow(flickr_instance).to receive(:people).and_return(people_api)
    end

    it 'calls flickr.people.getPhotos with user_id, page, and per_page' do
      photos_response = double('photos') # rubocop:disable RSpec/VerifiedDoubles
      allow(people_api).to receive(:getPhotos)
        .with(user_id: '123@N00', page: 1, per_page: 100)
        .and_return(photos_response)

      result = client.photos(user_id: '123@N00', page: 1, per_page: 100)

      expect(result).to eq(photos_response)
    end
  end

  describe '#photo_exif' do
    # Flickr gem uses dynamic method dispatch, so verified doubles won't work
    let(:flickr_instance) { double('Flickr') } # rubocop:disable RSpec/VerifiedDoubles
    let(:photos_api) { double('photos') } # rubocop:disable RSpec/VerifiedDoubles
    let(:client) do
      allow(Flickr).to receive(:new).and_return(flickr_instance)
      described_class.new(config)
    end

    before do
      allow(flickr_instance).to receive(:photos).and_return(photos_api)
    end

    it 'calls flickr.photos.getExif with photo_id' do
      exif_response = double('exif') # rubocop:disable RSpec/VerifiedDoubles
      allow(photos_api).to receive(:getExif)
        .with(photo_id: '3839885270')
        .and_return(exif_response)

      result = client.photo_exif(photo_id: '3839885270')

      expect(result).to eq(exif_response)
    end
  end

  describe '#photo_info' do
    # Flickr gem uses dynamic method dispatch, so verified doubles won't work
    let(:flickr_instance) { double('Flickr') } # rubocop:disable RSpec/VerifiedDoubles
    let(:photos_api) { double('photos') } # rubocop:disable RSpec/VerifiedDoubles
    let(:client) do
      allow(Flickr).to receive(:new).and_return(flickr_instance)
      described_class.new(config)
    end

    before do
      allow(flickr_instance).to receive(:photos).and_return(photos_api)
    end

    it 'calls flickr.photos.getInfo with photo_id' do
      info_response = double('info') # rubocop:disable RSpec/VerifiedDoubles
      allow(photos_api).to receive(:getInfo)
        .with(photo_id: '3839885270')
        .and_return(info_response)

      result = client.photo_info(photo_id: '3839885270')

      expect(result).to eq(info_response)
    end
  end

  describe '#photo_sizes' do
    # Flickr gem uses dynamic method dispatch, so verified doubles won't work
    let(:flickr_instance) { double('Flickr') } # rubocop:disable RSpec/VerifiedDoubles
    let(:photos_api) { double('photos') } # rubocop:disable RSpec/VerifiedDoubles
    let(:client) do
      allow(Flickr).to receive(:new).and_return(flickr_instance)
      described_class.new(config)
    end

    before do
      allow(flickr_instance).to receive(:photos).and_return(photos_api)
    end

    it 'calls flickr.photos.getSizes with photo_id' do
      sizes_response = double('sizes') # rubocop:disable RSpec/VerifiedDoubles
      allow(photos_api).to receive(:getSizes)
        .with(photo_id: '3839885270')
        .and_return(sizes_response)

      result = client.photo_sizes(photo_id: '3839885270')

      expect(result).to eq(sizes_response)
    end
  end
end
