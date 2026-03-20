# rubocop:disable RSpec/VerifiedDoubles
require 'down'
require 'json'
require 'slugify'
require 'tmpdir'
require 'yaml'

RSpec.describe Flickarr::Photo do
  let(:dates) do
    double('dates', taken: '2024-03-15 14:30:00', posted: '1710500000', takenunknown: 0, lastupdate: '1710600000')
  end
  let(:owner) { double('owner', nsid: '123@N00', realname: 'Test User', username: 'testuser') }
  let(:visibility) { double('visibility', isfamily: 0, isfriend: 0, ispublic: 1) }
  let(:photo_url) { double('url', type: 'photopage', to_s: 'https://www.flickr.com/photos/testuser/3839885270/') }
  let(:urls) { double('urls', url: [photo_url]) }
  let(:tags) do
    double('tags', tag: [
             double('tag', raw: 'cat', _content: 'cat', machine_tag: 0),
             double('tag', raw: 'pet', _content: 'pet', machine_tag: 0)
           ])
  end

  let(:info_response) do
    double(
      'info',
      dates:          dates,
      description:    'This is my cat',
      id:             '3839885270',
      license:        '4',
      media:          'photo',
      originalformat: 'jpg',
      owner:          owner,
      tags:           tags,
      title:          'My Cool Cat!',
      urls:           urls,
      views:          '2781',
      visibility:     visibility
    )
  end

  let(:sizes_response) do
    [
      double('size', height: 75, label: 'Square', source: 'https://live.staticflickr.com/s.jpg', media: 'photo', width: 75),
      double('size', height: 768, label: 'Large', source: 'https://live.staticflickr.com/b.jpg', media: 'photo',
width: 1024),
      double('size', height: 1200, label: 'Original', source: 'https://live.staticflickr.com/o.jpg', media: 'photo',
width: 1600)
    ]
  end

  let(:exif_response) do
    double(
      'exif_response',
      camera: 'Canon Digital IXUS 55',
      exif:   [
        double('exif_tag', label: 'Make', raw: 'Canon', clean: nil, tag: 'Make', tagspace: 'IFD0'),
        double('exif_tag', label: 'Exposure', raw: '1/60', clean: '0.017 sec (1/60)', tag: 'ExposureTime',
tagspace: 'ExifIFD')
      ]
    )
  end

  let(:photo) { described_class.new(info: info_response, sizes: sizes_response, exif: exif_response) }

  describe '.id_from_url' do
    it 'extracts photo id from a standard Flickr URL' do
      url = 'https://www.flickr.com/photos/testuser/3839885270'
      expect(described_class.id_from_url(url)).to eq('3839885270')
    end

    it 'extracts photo id from a URL with trailing path segments' do
      url = 'https://www.flickr.com/photos/testuser/3839885270/in/photostream/'
      expect(described_class.id_from_url(url)).to eq('3839885270')
    end

    it 'extracts photo id from a URL with nsid instead of username' do
      url = 'https://www.flickr.com/photos/12345678@N00/3839885270'
      expect(described_class.id_from_url(url)).to eq('3839885270')
    end

    it 'returns nil for non-Flickr URLs' do
      expect(described_class.id_from_url('https://example.com/photo/123')).to be_nil
    end
  end

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

  describe '#location' do
    it 'returns nil when photo has no location' do
      expect(photo.location).to be_nil
    end

    context 'when photo is geotagged' do
      let(:geo_location) do
        double(
          'location',
          accuracy:  '16',
          context:   '0',
          country:   'United States',
          county:    'Multnomah',
          latitude:  '45.523064',
          locality:  'Portland',
          longitude: '-122.676483',
          region:    'Oregon'
        )
      end

      let(:info_response) do
        double(
          'info',
          dates:          dates,
          description:    'This is my cat',
          id:             '3839885270',
          license:        '4',
          location:       geo_location,
          media:          'photo',
          originalformat: 'jpg',
          owner:          owner,
          tags:           tags,
          title:          'My Cool Cat!',
          urls:           urls,
          views:          '2781',
          visibility:     visibility
        )
      end

      it 'extracts location data' do
        expect(photo.location[:latitude]).to eq('45.523064')
        expect(photo.location[:longitude]).to eq('-122.676483')
        expect(photo.location[:locality]).to eq('Portland')
        expect(photo.location[:region]).to eq('Oregon')
        expect(photo.location[:country]).to eq('United States')
      end
    end
  end

  describe '#camera' do
    it 'returns the camera name from EXIF' do
      expect(photo.camera).to eq('Canon Digital IXUS 55')
    end

    it 'returns nil when no EXIF data' do
      photo_no_exif = described_class.new(info: info_response, sizes: sizes_response)
      expect(photo_no_exif.camera).to be_nil
    end
  end

  describe '#exif' do
    it 'returns parsed EXIF tags' do
      expect(photo.exif.length).to eq(2)
      expect(photo.exif.first[:label]).to eq('Make')
      expect(photo.exif.first[:raw]).to eq('Canon')
    end

    it 'includes clean values when present' do
      exposure = photo.exif.last
      expect(exposure[:clean]).to eq('0.017 sec (1/60)')
    end

    it 'returns empty array when no EXIF data' do
      photo_no_exif = described_class.new(info: info_response, sizes: sizes_response)
      expect(photo_no_exif.exif).to eq([])
    end
  end

  describe '#slug' do
    it 'returns a slugified version of the title' do
      expect(photo.slug).to eq('my-cool-cat')
    end

    context 'when title is empty' do
      let(:info_response) do
        double(
          'info',
          dates:          dates,
          description:    '',
          id:             '3839885270',
          license:        '0',
          media:          'photo',
          originalformat: 'jpg',
          owner:          owner,
          tags:           double('tags', tag: []),
          title:          '',
          urls:           urls,
          views:          '0',
          visibility:     visibility
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
        double(
          'info',
          dates:          dates,
          description:    '',
          id:             '3839885270',
          license:        '0',
          media:          'photo',
          originalformat: 'jpg',
          owner:          owner,
          tags:           double('tags', tag: []),
          title:          '',
          urls:           urls,
          views:          '0',
          visibility:     visibility
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
      let(:dates) do
        double('dates', taken: '2024-03-15 14:30:00', posted: '1710500000', takenunknown: 1, lastupdate: '1710600000')
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
          double('size', height: 75, label: 'Square', source: 'https://live.staticflickr.com/s.jpg', media: 'photo',
width: 75),
          double('size', height: 768, label: 'Large', source: 'https://live.staticflickr.com/b.jpg', media: 'photo',
width: 1024)
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
      expect(hash[:dates][:taken]).to eq('2024-03-15 14:30:00')
      expect(hash[:description]).to eq('This is my cat')
      expect(hash[:original_url]).to eq('https://live.staticflickr.com/o.jpg')
      expect(hash[:tags]).to eq(%w[cat pet])
      expect(hash[:title]).to eq('My Cool Cat!')
    end

    it 'includes owner info' do
      expect(photo.to_h[:owner]).to eq(nsid: '123@N00', realname: 'Test User', username: 'testuser')
    end

    it 'includes visibility' do
      expect(photo.to_h[:visibility]).to eq(isfamily: 0, isfriend: 0, ispublic: 1)
    end

    it 'includes camera and EXIF' do
      hash = photo.to_h
      expect(hash[:camera]).to eq('Canon Digital IXUS 55')
      expect(hash[:exif].length).to eq(2)
    end

    it 'includes sizes' do
      sizes = photo.to_h[:sizes]
      expect(sizes.length).to eq(3)
      expect(sizes.last[:label]).to eq('Original')
      expect(sizes.last[:width]).to eq(1600)
    end

    it 'includes post URL' do
      expect(photo.to_h[:urls]).to eq('photopage' => 'https://www.flickr.com/photos/testuser/3839885270/')
    end

    it 'includes license and views' do
      expect(photo.to_h[:license]).to eq(id: '4', name: 'CC BY 2.0', url: 'https://creativecommons.org/licenses/by/2.0/')
      expect(photo.to_h[:views]).to eq('2781')
    end
  end

  describe '#download' do
    let(:archive_path) { Dir.mktmpdir('flickarr-photo-test') }

    after { FileUtils.rm_rf archive_path }

    it 'downloads the original image to the correct path' do
      dest = File.join(archive_path, '2024/03/15', '3839885270_my-cool-cat.jpg')
      allow(Down).to receive(:download).with(photo.original_url, destination: dest)

      photo.download(archive_path: archive_path)

      expect(Down).to have_received(:download).with(photo.original_url, destination: dest)
    end
  end

  describe '#write_json' do
    let(:archive_path) { Dir.mktmpdir('flickarr-photo-test') }
    let(:photo_dir) { File.join(archive_path, '2024/03/15') }

    after { FileUtils.rm_rf archive_path }

    it 'writes a JSON sidecar file' do
      photo.write_json(archive_path: archive_path)

      json_path = File.join(photo_dir, '3839885270_my-cool-cat.json')
      expect(File.exist?(json_path)).to be true

      data = JSON.parse(File.read(json_path), symbolize_names: true)
      expect(data[:id]).to eq('3839885270')
      expect(data[:title]).to eq('My Cool Cat!')
      expect(data[:camera]).to eq('Canon Digital IXUS 55')
    end
  end

  describe '#write_yaml' do
    let(:archive_path) { Dir.mktmpdir('flickarr-photo-test') }
    let(:photo_dir) { File.join(archive_path, '2024/03/15') }

    after { FileUtils.rm_rf archive_path }

    it 'writes a YAML sidecar file' do
      photo.write_yaml(archive_path: archive_path)

      yaml_path = File.join(photo_dir, '3839885270_my-cool-cat.yaml')
      expect(File.exist?(yaml_path)).to be true

      data = YAML.load_file(yaml_path, symbolize_names: true)
      expect(data[:id]).to eq('3839885270')
      expect(data[:title]).to eq('My Cool Cat!')
    end
  end

  describe '#write' do
    let(:archive_path) { Dir.mktmpdir('flickarr-photo-test') }
    let(:photo_dir) { File.join(archive_path, '2024/03/15') }

    before { allow(Down).to receive(:download) }

    after { FileUtils.rm_rf archive_path }

    it 'creates the date folder and writes all files' do
      photo.write(archive_path: archive_path)

      expect(Dir.exist?(photo_dir)).to be true
      expect(File.exist?(File.join(photo_dir, '3839885270_my-cool-cat.json'))).to be true
      expect(File.exist?(File.join(photo_dir, '3839885270_my-cool-cat.yaml'))).to be true
      expect(Down).to have_received(:download)
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
