# rubocop:disable RSpec/VerifiedDoubles
RSpec.describe Flickarr::Client do
  let(:config) do
    c = Flickarr::Config.new
    c.api_key = 'test-api-key'
    c.shared_secret = 'test-shared-secret'
    c
  end

  let(:flickr_instance) { double('Flickr') }
  let(:client) do
    allow(Flickr).to receive(:new).and_return(flickr_instance)
    described_class.new(config)
  end

  describe '#sets' do
    it 'calls flickr.photosets.getList with user_id' do
      photosets_api = double('photosets')
      allow(flickr_instance).to receive(:photosets).and_return(photosets_api)
      sets_response = double('sets_response')
      allow(photosets_api).to receive(:getList).with(user_id: '123@N00', per_page: 500).and_return(sets_response)

      result = client.sets(user_id: '123@N00')

      expect(result).to eq(sets_response)
    end
  end

  describe '#set_photos' do
    it 'calls flickr.photosets.getPhotos with photoset_id and extras' do
      photosets_api = double('photosets')
      allow(flickr_instance).to receive(:photosets).and_return(photosets_api)
      photos_response = double('photos_response')
      allow(photosets_api).to receive(:getPhotos).and_return(photos_response)

      result = client.set_photos(photoset_id: '72157718538273371', user_id: '123@N00')

      expect(photosets_api).to have_received(:getPhotos).with(
        hash_including(photoset_id: '72157718538273371', user_id: '123@N00')
      )
      expect(result).to eq(photos_response)
    end
  end

  describe '#collections' do
    it 'calls flickr.collections.getTree with user_id' do
      collections_api = double('collections')
      allow(flickr_instance).to receive(:collections).and_return(collections_api)
      tree_response = double('tree_response')
      allow(collections_api).to receive(:getTree).with(user_id: '123@N00').and_return(tree_response)

      result = client.collections(user_id: '123@N00')

      expect(result).to eq(tree_response)
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
