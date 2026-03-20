# rubocop:disable RSpec/VerifiedDoubles
RSpec.describe Flickarr::Client::ProfileQuery do
  let(:flickr_instance) { double('Flickr') }
  let(:people_api) { double('people') }
  let(:rate_limiter) { Flickarr::RateLimiter.new(interval: 0) }
  let(:query) { described_class.new(flickr: flickr_instance, user_id: '12345@N00', rate_limiter: rate_limiter) }

  before do
    allow(flickr_instance).to receive(:people).and_return(people_api)
  end

  describe '#info' do
    it 'calls flickr.people.getInfo' do
      person_response = double('person')
      allow(people_api).to receive(:getInfo).with(user_id: '12345@N00').and_return(person_response)

      expect(query.info).to eq(person_response)
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
