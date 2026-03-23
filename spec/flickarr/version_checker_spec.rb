require 'tmpdir'

RSpec.describe Flickarr::VersionChecker do
  let(:config) { Flickarr::Config.new }

  describe '#stale?' do
    it 'is stale when never checked' do
      checker = described_class.new(config)
      expect(checker.stale?).to be true
    end

    it 'is not stale when checked recently' do
      config.latest_version_checked_at = Time.now.iso8601
      checker = described_class.new(config)
      expect(checker.stale?).to be false
    end

    it 'is stale when checked more than a day ago' do
      config.latest_version_checked_at = (Time.now - 90_000).iso8601
      checker = described_class.new(config)
      expect(checker.stale?).to be true
    end
  end

  describe '#update_available?' do
    it 'returns false when latest matches current' do
      config.latest_version = Flickarr::VERSION
      config.latest_version_checked_at = Time.now.iso8601
      checker = described_class.new(config)
      expect(checker.update_available?).to be false
    end

    it 'returns true when latest is newer' do
      config.latest_version = '99.0.0'
      config.latest_version_checked_at = Time.now.iso8601
      checker = described_class.new(config)
      expect(checker.update_available?).to be true
    end

    it 'returns false when latest is older' do
      config.latest_version = '0.0.1'
      config.latest_version_checked_at = Time.now.iso8601
      checker = described_class.new(config)
      expect(checker.update_available?).to be false
    end
  end

  describe '#update_message' do
    it 'returns nil when up to date' do
      config.latest_version = Flickarr::VERSION
      config.latest_version_checked_at = Time.now.iso8601
      checker = described_class.new(config)
      expect(checker.update_message).to be_nil
    end

    it 'returns a message when update is available' do
      config.latest_version = '99.0.0'
      config.latest_version_checked_at = Time.now.iso8601
      checker = described_class.new(config)
      expect(checker.update_message).to include('99.0.0')
      expect(checker.update_message).to include('gem update flickarr')
    end
  end
end
