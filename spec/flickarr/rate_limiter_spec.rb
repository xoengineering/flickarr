RSpec.describe Flickarr::RateLimiter do
  describe '#track' do
    it 'yields and returns the block result' do
      limiter = described_class.new(interval: 1.0)

      result = limiter.track { 42 }

      expect(result).to eq(42)
    end

    it 'does not sleep on the first call' do
      limiter = described_class.new(interval: 1.0)
      allow(limiter).to receive(:sleep)

      limiter.track { 'first' }

      expect(limiter).not_to have_received(:sleep)
    end

    it 'sleeps when calls are too fast' do
      limiter = described_class.new(interval: 1.0)
      allow(limiter).to receive(:sleep)

      limiter.track { 'first' }
      limiter.track { 'second' }

      expect(limiter).to have_received(:sleep).once
    end
  end
end
