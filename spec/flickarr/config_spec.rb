require 'tmpdir'

RSpec.describe Flickarr::Config do
  describe '#initialize' do
    it 'has nil attributes by default except library_path' do
      config = described_class.new

      expect(config.access_secret).to be_nil
      expect(config.access_token).to be_nil
      expect(config.api_key).to be_nil
      expect(config.library_path).to eq(File.join(Dir.home, 'Pictures', 'Flickarr'))
      expect(config.shared_secret).to be_nil
      expect(config.user_nsid).to be_nil
      expect(config.username).to be_nil
    end

    it 'reads api_key from FLICKARR_API_KEY env var' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('FLICKARR_API_KEY', nil).and_return('env-key')
      allow(ENV).to receive(:fetch).with('FLICKARR_SHARED_SECRET', nil).and_return(nil)

      config = described_class.new

      expect(config.api_key).to eq('env-key')
    end

    it 'reads shared_secret from FLICKARR_SHARED_SECRET env var' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('FLICKARR_API_KEY', nil).and_return(nil)
      allow(ENV).to receive(:fetch).with('FLICKARR_SHARED_SECRET', nil).and_return('env-secret')

      config = described_class.new

      expect(config.shared_secret).to eq('env-secret')
    end
  end

  describe '#save' do
    it 'writes config to a YAML file' do
      path = File.join(Dir.tmpdir, "flickarr-test-#{Process.pid}", 'config.yml')
      config = described_class.new
      config.api_key = 'test-key'
      config.shared_secret = 'test-secret'

      config.save(path)

      yaml = YAML.load_file(path)
      expect(yaml['api_key']).to eq('test-key')
      expect(yaml['shared_secret']).to eq('test-secret')
    ensure
      FileUtils.rm_rf(File.dirname(path))
    end
  end

  describe '.load' do
    it 'reads config from a YAML file' do
      dir = File.join(Dir.tmpdir, "flickarr-test-#{Process.pid}")
      path = File.join(dir, 'config.yml')
      FileUtils.mkdir_p(dir)
      data = {
        'api_key'       => 'file-key',
        'shared_secret' => 'file-secret',
        'access_token'  => 'file-token',
        'access_secret' => 'file-access-secret',
        'user_nsid'     => '12345@N00',
        'username'      => 'testuser'
      }
      File.write(path, YAML.dump(data))

      config = described_class.load(path)

      expect(config.api_key).to eq('file-key')
      expect(config.shared_secret).to eq('file-secret')
      expect(config.access_token).to eq('file-token')
      expect(config.access_secret).to eq('file-access-secret')
      expect(config.user_nsid).to eq('12345@N00')
      expect(config.username).to eq('testuser')
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'falls back to env vars when file values are missing' do
      dir = File.join(Dir.tmpdir, "flickarr-test-#{Process.pid}")
      path = File.join(dir, 'config.yml')
      FileUtils.mkdir_p(dir)
      File.write(path, YAML.dump('username' => 'testuser'))

      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('FLICKARR_API_KEY', nil).and_return('env-key')
      allow(ENV).to receive(:fetch).with('FLICKARR_SHARED_SECRET', nil).and_return(nil)

      config = described_class.load(path)

      expect(config.api_key).to eq('env-key')
      expect(config.username).to eq('testuser')
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'loads library_path from file' do
      dir = File.join(Dir.tmpdir, "flickarr-test-#{Process.pid}")
      path = File.join(dir, 'config.yml')
      FileUtils.mkdir_p(dir)
      File.write(path, YAML.dump('library_path' => '/custom/path'))

      config = described_class.load(path)

      expect(config.library_path).to eq('/custom/path')
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'returns a default config when file does not exist' do
      config = described_class.load('/tmp/nonexistent-flickarr-config.yml')

      expect(config.api_key).to be_nil
      expect(config.username).to be_nil
    end

    it 'loads last_page_posts from file' do
      dir = File.join(Dir.tmpdir, "flickarr-test-#{Process.pid}")
      path = File.join(dir, 'config.yml')
      FileUtils.mkdir_p(dir)
      File.write(path, YAML.dump('last_page_posts' => 42))

      config = described_class.load(path)

      expect(config.last_page_posts).to eq(42)
    ensure
      FileUtils.rm_rf(dir)
    end
  end

  describe '#archive_path' do
    it 'combines library_path and username' do
      config = described_class.new
      config.username = 'testuser'

      expect(config.archive_path).to eq(File.join(Dir.home, 'Pictures', 'Flickarr', 'testuser'))
    end

    it 'returns nil when username is nil' do
      config = described_class.new

      expect(config.archive_path).to be_nil
    end

    it 'returns nil when username is blank' do
      config = described_class.new
      config.username = ''

      expect(config.archive_path).to be_nil
    end
  end
end
