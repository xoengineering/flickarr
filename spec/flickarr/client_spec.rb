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
end
