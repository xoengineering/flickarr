# rubocop:disable RSpec/VerifiedDoubles
require 'slugify'

RSpec.describe Flickarr::Photo do
  let(:info_response) do
    dates = double('dates', taken: '2024-03-15 14:30:00', posted: '1710500000', takenunknown: 0)
    tags = double('tags', tag: [
                    double('tag', raw: 'cat', _content: 'cat', machine_tag: 0),
                    double('tag', raw: 'pet', _content: 'pet', machine_tag: 0)
                  ])
    double(
      'info',
      id:             '3839885270',
      dates:          dates,
      description:    'This is my cat',
      media:          'photo',
      originalformat: 'jpg',
      tags:           tags,
      title:          'My Cool Cat!'
    )
  end

  let(:sizes_response) do
    [
      double('size', label: 'Square', source: 'https://live.staticflickr.com/s.jpg', media: 'photo'),
      double('size', label: 'Large', source: 'https://live.staticflickr.com/b.jpg', media: 'photo'),
      double('size', label: 'Original', source: 'https://live.staticflickr.com/o.jpg', media: 'photo')
    ]
  end

  let(:photo) { described_class.new(info: info_response, sizes: sizes_response) }

  describe '#id' do
    it 'returns the photo id' do
      expect(photo.id).to eq('3839885270')
    end
  end

  describe '#title' do
    it 'returns the photo title' do
      expect(photo.title).to eq('My Cool Cat!')
    end
  end

  describe '#slug' do
    it 'returns a slugified version of the title' do
      expect(photo.slug).to eq('my-cool-cat')
    end

    context 'when title is empty' do
      let(:info_response) do
        dates = double('dates', taken: '2024-03-15 14:30:00', posted: '1710500000', takenunknown: 0)
        double(
          'info',
          id:             '3839885270',
          dates:          dates,
          description:    '',
          media:          'photo',
          originalformat: 'jpg',
          tags:           double('tags', tag: []),
          title:          ''
        )
      end

      it 'returns nil' do
        expect(photo.slug).to be_nil
      end
    end
  end

  describe '#basename' do
    it 'includes id and slug' do
      expect(photo.basename).to eq('3839885270_my-cool-cat')
    end

    context 'when title is empty' do
      let(:info_response) do
        dates = double('dates', taken: '2024-03-15 14:30:00', posted: '1710500000', takenunknown: 0)
        double(
          'info',
          id:             '3839885270',
          dates:          dates,
          description:    '',
          media:          'photo',
          originalformat: 'jpg',
          tags:           double('tags', tag: []),
          title:          ''
        )
      end

      it 'uses just the id' do
        expect(photo.basename).to eq('3839885270')
      end
    end
  end

  describe '#date_taken' do
    it 'parses the taken date' do
      expect(photo.date_taken).to eq(Date.new(2024, 3, 15))
    end

    context 'when taken date is unknown' do
      let(:info_response) do
        dates = double('dates', taken: '2024-03-15 14:30:00', posted: '1710500000', takenunknown: 1)
        double(
          'info',
          id:             '3839885270',
          dates:          dates,
          description:    '',
          media:          'photo',
          originalformat: 'jpg',
          tags:           double('tags', tag: []),
          title:          'Cat'
        )
      end

      it 'falls back to upload date' do
        expected = Time.at(1_710_500_000).to_date
        expect(photo.date_taken).to eq(expected)
      end
    end
  end

  describe '#folder_path' do
    it 'returns YYYY/MM/DD path components' do
      expect(photo.folder_path).to eq('2024/03/15')
    end
  end

  describe '#original_url' do
    it 'returns the Original size source URL' do
      expect(photo.original_url).to eq('https://live.staticflickr.com/o.jpg')
    end

    context 'when no Original size exists' do
      let(:sizes_response) do
        [
          double('size', label: 'Square', source: 'https://live.staticflickr.com/s.jpg', media: 'photo'),
          double('size', label: 'Large', source: 'https://live.staticflickr.com/b.jpg', media: 'photo')
        ]
      end

      it 'returns the last (largest) size' do
        expect(photo.original_url).to eq('https://live.staticflickr.com/b.jpg')
      end
    end
  end

  describe '#extension' do
    it 'returns the original format' do
      expect(photo.extension).to eq('jpg')
    end
  end

  describe '#to_h' do
    it 'returns a hash of photo metadata' do
      hash = photo.to_h

      expect(hash[:id]).to eq('3839885270')
      expect(hash[:date_taken]).to eq('2024-03-15')
      expect(hash[:description]).to eq('This is my cat')
      expect(hash[:original_url]).to eq('https://live.staticflickr.com/o.jpg')
      expect(hash[:tags]).to eq(%w[cat pet])
      expect(hash[:title]).to eq('My Cool Cat!')
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
