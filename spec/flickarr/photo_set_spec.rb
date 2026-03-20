# rubocop:disable RSpec/VerifiedDoubles
require 'json'
require 'tmpdir'
require 'yaml'

RSpec.describe Flickarr::PhotoSet do
  let(:set_response) do
    double(
      'set',
      count_comments: '0',
      count_photos:   72,
      count_videos:   9,
      count_views:    '5',
      date_create:    '1615022202',
      date_update:    '1615023685',
      description:    'My favorite photos',
      id:             '72157718538273371',
      owner:          '123@N00',
      primary:        '3947595697',
      title:          'Amy Fleming',
      username:       'testuser'
    )
  end

  let(:photo_items) do
    [
      double(
        'photo',
        datetaken:        '2024-03-15 14:30:00',
        datetakenunknown: '0',
        dateupload:       '1710500000',
        description:      'A cat photo',
        id:               '12345',
        isprimary:        '1',
        media:            'photo',
        originalformat:   'jpg',
        tags:             'cat pet',
        title:            'My Cat'
      ),
      double(
        'photo',
        datetaken:        '2023-07-04 12:00:00',
        datetakenunknown: '0',
        dateupload:       '1688472000',
        description:      'Fireworks',
        id:               '67890',
        isprimary:        '0',
        media:            'video',
        originalformat:   'jpg',
        tags:             'fireworks july4',
        title:            'Fireworks!'
      )
    ]
  end

  let(:photo_set) { described_class.new(set: set_response, photo_items: photo_items) }

  describe '#slug' do
    it 'returns a slugified title' do
      expect(photo_set.slug).to eq('amy-fleming')
    end
  end

  describe '#dirname' do
    it 'combines id and slug' do
      expect(photo_set.dirname).to eq('72157718538273371_amy-fleming')
    end
  end

  describe '#to_h' do
    it 'returns set metadata' do
      hash = photo_set.to_h

      expect(hash[:count_photos]).to eq(72)
      expect(hash[:count_videos]).to eq(9)
      expect(hash[:date_create]).to eq('1615022202')
      expect(hash[:description]).to eq('My favorite photos')
      expect(hash[:id]).to eq('72157718538273371')
      expect(hash[:title]).to eq('Amy Fleming')
    end
  end

  describe '#photos_to_a' do
    it 'returns photo references with computed file paths' do
      refs = photo_set.photos_to_a

      expect(refs.length).to eq(2)
      expect(refs.first[:id]).to eq('12345')
      expect(refs.first[:path]).to eq('2024/03/15/12345_my-cat.jpg')
      expect(refs.first[:isprimary]).to be(true)
      expect(refs.first[:title]).to eq('My Cat')
    end

    it 'uses mp4 extension for videos' do
      refs = photo_set.photos_to_a

      expect(refs.last[:path]).to eq('2023/07/04/67890_fireworks.mp4')
      expect(refs.last[:media]).to eq('video')
    end
  end

  describe '#write' do
    let(:archive_path) { Dir.mktmpdir('flickarr-set-test') }
    let(:set_dir) { File.join(archive_path, 'sets', '72157718538273371_amy-fleming') }

    after { FileUtils.rm_rf archive_path }

    it 'creates the set directory with metadata and photo references' do
      result = photo_set.write(archive_path: archive_path)

      expect(result).to eq(:created)
      expect(Dir.exist?(set_dir)).to be true
      expect(File.exist?(File.join(set_dir, 'set.json'))).to be true
      expect(File.exist?(File.join(set_dir, 'set.yaml'))).to be true
      expect(File.exist?(File.join(set_dir, 'photos.json'))).to be true
      expect(File.exist?(File.join(set_dir, 'photos.yaml'))).to be true
    end

    it 'writes valid JSON metadata' do
      photo_set.write(archive_path: archive_path)

      data = JSON.parse(File.read(File.join(set_dir, 'set.json')), symbolize_names: true)
      expect(data[:title]).to eq('Amy Fleming')
      expect(data[:id]).to eq('72157718538273371')
    end

    it 'writes valid photo references' do
      photo_set.write(archive_path: archive_path)

      refs = JSON.parse(File.read(File.join(set_dir, 'photos.json')), symbolize_names: true)
      expect(refs.length).to eq(2)
      expect(refs.first[:id]).to eq('12345')
      expect(refs.first[:path]).to eq('2024/03/15/12345_my-cat.jpg')
    end

    it 'skips when set.json already exists' do
      FileUtils.mkdir_p set_dir
      File.write File.join(set_dir, 'set.json'), 'existing'

      result = photo_set.write(archive_path: archive_path)

      expect(result).to eq(:skipped)
    end

    it 'overwrites when overwrite: true' do
      FileUtils.mkdir_p set_dir
      File.write File.join(set_dir, 'set.json'), 'existing'

      result = photo_set.write(archive_path: archive_path, overwrite: true)

      expect(result).to eq(:overwritten)
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
