RSpec.describe Flickarr::Config do
  describe '#initialize' do
    it 'has nil attributes by default' do
      config = described_class.new

      expect(config.api_key).to be_nil
      expect(config.shared_secret).to be_nil
      expect(config.access_token).to be_nil
      expect(config.access_secret).to be_nil
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
end
