# rubocop:disable RSpec/VerifiedDoubles
RSpec.describe Flickarr::Client::PhotoQuery do
  let(:flickr_instance) { double('Flickr') }
  let(:photos_api) { double('photos') }
  let(:rate_limiter) { Flickarr::RateLimiter.new(interval: 0) }
  let(:query) { described_class.new(flickr: flickr_instance, id: '3839885270', rate_limiter: rate_limiter) }

  before do
    allow(flickr_instance).to receive(:photos).and_return(photos_api)
  end

  describe '#exif' do
    it 'calls flickr.photos.getExif' do
      exif_response = double('exif')
      allow(photos_api).to receive(:getExif).with(photo_id: '3839885270').and_return(exif_response)

      expect(query.exif).to eq(exif_response)
    end
  end

  describe '#info' do
    it 'calls flickr.photos.getInfo' do
      info_response = double('info')
      allow(photos_api).to receive(:getInfo).with(photo_id: '3839885270').and_return(info_response)

      expect(query.info).to eq(info_response)
    end
  end

  describe '#sizes' do
    it 'calls flickr.photos.getSizes' do
      sizes_response = double('sizes')
      allow(photos_api).to receive(:getSizes).with(photo_id: '3839885270').and_return(sizes_response)

      expect(query.sizes).to eq(sizes_response)
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
