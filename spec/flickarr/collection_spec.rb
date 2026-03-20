# rubocop:disable RSpec/VerifiedDoubles
require 'json'
require 'tmpdir'
require 'yaml'

RSpec.describe Flickarr::Collection do
  let(:set_refs) do
    [
      double('set_ref', description: 'Roadtrip photos', id: '72157663446734094', title: '2015 U.S. Roadtrip'),
      double('set_ref', description: '', id: '72157665786561046', title: 'Border Crossings')
    ]
  end

  let(:collection_response) do
    double(
      'collection',
      description: 'Adventures on the road',
      iconlarge:   'https://combo.staticflickr.com/pw/images/collection_default_l.gif',
      iconsmall:   'https://combo.staticflickr.com/pw/images/collection_default_s.gif',
      id:          '375727-72157666222057746',
      set:         set_refs,
      title:       '#LittleMisadventureTime'
    )
  end

  let(:collection) { described_class.new(collection_response) }

  describe '#slug' do
    it 'returns a slugified title' do
      expect(collection.slug).to eq('littlemisadventuretime')
    end
  end

  describe '#dirname' do
    it 'combines id and slug' do
      expect(collection.dirname).to eq('375727-72157666222057746_littlemisadventuretime')
    end
  end

  describe '#to_h' do
    it 'returns collection metadata' do
      hash = collection.to_h

      expect(hash[:description]).to eq('Adventures on the road')
      expect(hash[:id]).to eq('375727-72157666222057746')
      expect(hash[:title]).to eq('#LittleMisadventureTime')
    end
  end

  describe '#sets_to_a' do
    it 'returns set references with paths' do
      refs = collection.sets_to_a

      expect(refs.length).to eq(2)
      expect(refs.first[:id]).to eq('72157663446734094')
      expect(refs.first[:path]).to eq('sets/72157663446734094_2015-u-s--roadtrip')
      expect(refs.first[:title]).to eq('2015 U.S. Roadtrip')
    end
  end

  describe '#write' do
    let(:archive_path) { Dir.mktmpdir('flickarr-collection-test') }
    let(:collection_dir) do
      File.join(archive_path, 'collections', '375727-72157666222057746_littlemisadventuretime')
    end

    after { FileUtils.rm_rf archive_path }

    it 'creates the collection directory with metadata and set references' do
      result = collection.write(archive_path: archive_path)

      expect(result).to eq(:created)
      expect(Dir.exist?(collection_dir)).to be true
      expect(File.exist?(File.join(collection_dir, 'collection.json'))).to be true
      expect(File.exist?(File.join(collection_dir, 'collection.yaml'))).to be true
      expect(File.exist?(File.join(collection_dir, 'sets.json'))).to be true
      expect(File.exist?(File.join(collection_dir, 'sets.yaml'))).to be true
    end

    it 'writes valid JSON metadata' do
      collection.write(archive_path: archive_path)

      data = JSON.parse(File.read(File.join(collection_dir, 'collection.json')), symbolize_names: true)
      expect(data[:title]).to eq('#LittleMisadventureTime')
    end

    it 'writes valid set references' do
      collection.write(archive_path: archive_path)

      refs = JSON.parse(File.read(File.join(collection_dir, 'sets.json')), symbolize_names: true)
      expect(refs.length).to eq(2)
      expect(refs.first[:id]).to eq('72157663446734094')
      expect(refs.first[:path]).to eq('sets/72157663446734094_2015-u-s--roadtrip')
    end

    it 'skips when collection.json already exists' do
      FileUtils.mkdir_p collection_dir
      File.write File.join(collection_dir, 'collection.json'), 'existing'

      result = collection.write(archive_path: archive_path)

      expect(result).to eq(:skipped)
    end

    it 'overwrites when overwrite: true' do
      FileUtils.mkdir_p collection_dir
      File.write File.join(collection_dir, 'collection.json'), 'existing'

      result = collection.write(archive_path: archive_path, overwrite: true)

      expect(result).to eq(:overwritten)
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
