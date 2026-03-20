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
end
