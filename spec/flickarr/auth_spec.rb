# rubocop:disable RSpec/VerifiedDoubles
require 'tmpdir'

RSpec.describe Flickarr::Auth do
  let(:config) do
    c = Flickarr::Config.new
    c.api_key = 'test-api-key'
    c.shared_secret = 'test-shared-secret'
    c
  end

  let(:flickr_instance) do
    double('Flickr', access_token: nil, :access_token= => nil, access_secret: nil, :access_secret= => nil)
  end

  before do
    allow(Flickr).to receive(:new).and_return(flickr_instance)
  end

  describe '#authenticated?' do
    it 'returns true when config has access tokens' do
      config.access_token = 'token'
      config.access_secret = 'secret'

      auth = described_class.new(config)

      expect(auth).to be_authenticated
    end

    it 'returns false when config is missing access tokens' do
      auth = described_class.new(config)

      expect(auth).not_to be_authenticated
    end
  end

  describe '#authenticate' do
    it 'performs the OAuth flow and saves tokens to config' do
      dir = File.join(Dir.tmpdir, "flickarr-auth-test-#{Process.pid}")
      config_path = File.join(dir, 'config.yml')

      request_token = { 'oauth_token' => 'req-token', 'oauth_token_secret' => 'req-secret' }
      allow(flickr_instance).to receive(:get_authorize_url).with('req-token', perms: 'read').and_return('https://flickr.com/auth')
      allow(flickr_instance).to receive(:get_access_token).with('req-token', 'req-secret', '12345')

      login = double('login', id: '123@N00', username: 'testuser')
      test_namespace = double('test', login: login)
      allow(flickr_instance).to receive_messages(get_request_token: request_token, access_token: 'access-token',
                                                 access_secret: 'access-secret', test: test_namespace)

      auth = described_class.new(config, config_path: config_path)
      allow(auth).to receive(:prompt_for_verifier).and_return('12345')
      allow(auth).to receive(:puts)

      auth.authenticate

      expect(config.access_token).to eq('access-token')
      expect(config.access_secret).to eq('access-secret')
      expect(config.user_nsid).to eq('123@N00')
      expect(config.username).to eq('testuser')

      saved_config = Flickarr::Config.load(config_path)
      expect(saved_config.access_token).to eq('access-token')
    ensure
      FileUtils.rm_rf(dir)
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
