RSpec.describe Flickarr::Error do
  it 'inherits from StandardError' do
    expect(described_class).to be < StandardError
  end

  describe Flickarr::AuthError do
    it 'inherits from Flickarr::Error' do
      expect(described_class).to be < Flickarr::Error
    end
  end

  describe Flickarr::ApiError do
    it 'inherits from Flickarr::Error' do
      expect(described_class).to be < Flickarr::Error
    end
  end

  describe Flickarr::DownloadError do
    it 'inherits from Flickarr::Error' do
      expect(described_class).to be < Flickarr::Error
    end
  end

  describe Flickarr::ConfigError do
    it 'inherits from Flickarr::Error' do
      expect(described_class).to be < Flickarr::Error
    end
  end
end
