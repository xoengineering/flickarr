# rubocop:disable RSpec/VerifiedDoubles
require 'down'
require 'json'
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
      farm:           66,
      id:             '3839885270',
      license:        '4',
      media:          'photo',
      originalformat: 'jpg',
      originalsecret: 'abc123secret',
      owner:          owner,
      server:         '65535',
      tags:           tags,
      title:          'My Cool Cat!',
      urls:           urls,
      views:          '2781',
      visibility:     visibility
    )
  end

  let(:sizes_response) do
    [
      double('size', height: 75, label: 'Square', source: 'https://live.staticflickr.com/s.jpg', media: 'photo',
             width: 75),
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

  it 'is a Post' do
    expect(photo).to be_a(Flickarr::Post)
  end

  describe '#extension' do
    it 'returns the original format' do
      expect(photo.extension).to eq('jpg')
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

  describe '#download' do
    let(:archive_path) { Dir.mktmpdir('flickarr-photo-test') }

    after { FileUtils.rm_rf archive_path }

    it 'downloads the original image to the correct path' do
      dest = File.join(archive_path, '2024/03/15', '3839885270_my-cool-cat.jpg')
      allow(Down).to receive(:download).with(photo.original_url, destination: dest)

      photo.download(archive_path: archive_path)

      expect(Down).to have_received(:download).with(photo.original_url, destination: dest)
    end

    it 'falls back to constructed URL when getSizes URL returns 410' do
      dest = File.join(archive_path, '2024/03/15', '3839885270_my-cool-cat.jpg')
      fallback_url = 'https://live.staticflickr.com/65535/3839885270_abc123secret_o.jpg'

      allow(Down).to receive(:download).with(photo.original_url, destination: dest)
                                       .and_raise(Down::ClientError.new('410 Gone'))
      allow(Down).to receive(:download).with(fallback_url, destination: dest)

      photo.download(archive_path: archive_path)

      expect(Down).to have_received(:download).with(fallback_url, destination: dest)
    end
  end

  describe '#write' do
    let(:archive_path) { Dir.mktmpdir('flickarr-photo-test') }
    let(:photo_dir) { File.join(archive_path, '2024/03/15') }

    before { allow(Down).to receive(:download) }

    after { FileUtils.rm_rf archive_path }

    it 'creates the date folder and writes all files' do
      result = photo.write(archive_path: archive_path)

      expect(result).to eq(:created)
      expect(Dir.exist?(photo_dir)).to be true
      expect(File.exist?(File.join(photo_dir, '3839885270_my-cool-cat.json'))).to be true
      expect(File.exist?(File.join(photo_dir, '3839885270_my-cool-cat.yaml'))).to be true
      expect(Down).to have_received(:download)
    end

    it 'skips when image file already exists' do
      image_path = File.join(photo_dir, '3839885270_my-cool-cat.jpg')
      FileUtils.mkdir_p photo_dir
      File.write image_path, 'existing'

      result = photo.write(archive_path: archive_path)

      expect(result).to eq(:skipped)
      expect(Down).not_to have_received(:download)
    end

    it 'overwrites when overwrite: true' do
      image_path = File.join(photo_dir, '3839885270_my-cool-cat.jpg')
      FileUtils.mkdir_p photo_dir
      File.write image_path, 'existing'

      result = photo.write(archive_path: archive_path, overwrite: true)

      expect(result).to eq(:overwritten)
      expect(Down).to have_received(:download)
    end

    it 'still writes json and yaml when download fails' do
      allow(Down).to receive(:download).and_raise(Down::Error.new('410 Gone'))

      result = photo.write(archive_path: archive_path)

      expect(result).to eq(:download_failed)
      expect(File.exist?(File.join(photo_dir, '3839885270_my-cool-cat.json'))).to be true
      expect(File.exist?(File.join(photo_dir, '3839885270_my-cool-cat.yaml'))).to be true
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
