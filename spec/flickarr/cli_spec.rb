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

  describe 'config command' do
    it 'displays current config values' do
      dir = File.join(Dir.tmpdir, "flickarr-cli-test-#{Process.pid}")
      path = File.join(dir, 'config.yml')
      FileUtils.mkdir_p(dir)
      config = Flickarr::Config.new
      config.api_key = 'my-key'
      config.save(path)

      cli = described_class.new(['config'], config_path: path)
      expect { cli.run }.to output(/api_key: my-key/).to_stdout
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'reports when no config file exists' do
      cli = described_class.new(['config'], config_path: '/tmp/nonexistent-flickarr.yml')
      expect { cli.run }.to output(/No config file found/).to_stdout
    end
  end

  describe 'config set command' do
    it 'sets a config value and saves to file' do
      dir = File.join(Dir.tmpdir, "flickarr-cli-test-#{Process.pid}")
      path = File.join(dir, 'config.yml')

      cli = described_class.new(%w[config set api_key new-key], config_path: path)
      cli.run

      config = Flickarr::Config.load(path)
      expect(config.api_key).to eq('new-key')
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'updates an existing config file without clobbering other values' do
      dir = File.join(Dir.tmpdir, "flickarr-cli-test-#{Process.pid}")
      path = File.join(dir, 'config.yml')
      FileUtils.mkdir_p(dir)
      config = Flickarr::Config.new
      config.api_key = 'existing-key'
      config.save(path)

      cli = described_class.new(%w[config set shared_secret my-secret], config_path: path)
      cli.run

      config = Flickarr::Config.load(path)
      expect(config.api_key).to eq('existing-key')
      expect(config.shared_secret).to eq('my-secret')
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'rejects unknown config keys' do
      dir = File.join(Dir.tmpdir, "flickarr-cli-test-#{Process.pid}")
      path = File.join(dir, 'config.yml')

      cli = described_class.new(%w[config set bogus_key value], config_path: path)
      expect { cli.run }.to output(/Unknown config key/).to_stdout
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'prints usage when key or value is missing' do
      cli = described_class.new(%w[config set], config_path: '/tmp/whatever.yml')
      expect { cli.run }.to output(/Usage:.*config set/).to_stdout
    end
  end
end
