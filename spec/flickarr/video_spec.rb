# rubocop:disable RSpec/VerifiedDoubles
require 'down'
require 'http'
require 'tmpdir'

RSpec.describe Flickarr::Video do
  let(:dates) do
    double('dates', taken: '2024-03-15 14:30:00', posted: '1710500000', takenunknown: 0, lastupdate: '1710600000')
  end
  let(:owner) { double('owner', nsid: '123@N00', realname: 'Test', username: 'testuser') }
  let(:visibility) { double('visibility', isfamily: 0, isfriend: 0, ispublic: 1) }
  let(:urls) { double('urls', url: []) }
  let(:tags) { double('tags', tag: []) }

  let(:info_response) do
    double(
      'info',
      dates:          dates,
      description:    'A video',
      id:             '3839885270',
      license:        '0',
      media:          'video',
      originalformat: 'jpg',
      owner:          owner,
      tags:           tags,
      title:          'My Cool Video!',
      urls:           urls,
      views:          '0',
      visibility:     visibility
    )
  end

  let(:sizes_response) do
    [
      double('size', height: 1200, label: 'Original', source: 'https://live.staticflickr.com/o.jpg',
             media: 'photo', width: 1600),
      double('size', height: 0, label: 'Video Original',
             source: 'https://www.flickr.com/photos/user/123/play/orig/abc/', media: 'video', width: 0)
    ]
  end

  let(:video) { described_class.new(info: info_response, sizes: sizes_response) }

  it 'is a Post' do
    expect(video).to be_a(Flickarr::Post)
  end

  describe '#extension' do
    it 'returns mp4' do
      expect(video.extension).to eq('mp4')
    end
  end

  describe '#original_url' do
    it 'returns the Video Original URL' do
      expect(video.original_url).to eq('https://www.flickr.com/photos/user/123/play/orig/abc/')
    end
  end

  describe '#download' do
    let(:archive_path) { Dir.mktmpdir('flickarr-video-test') }

    after { FileUtils.rm_rf archive_path }

    it 'downloads both the video and poster frame' do
      redirect_url = 'https://live.staticflickr.com/video/123/abc/orig.mp4?s=token'
      status = instance_double(HTTP::Response::Status, redirect?: true)
      headers = { 'Location' => redirect_url }
      redirect_response = instance_double(HTTP::Response, status: status, headers: headers)
      allow(HTTP).to receive(:head).and_return(redirect_response)
      allow(Down).to receive(:download)

      video.download(archive_path: archive_path)

      expect(Down).to have_received(:download).with(redirect_url, destination: anything).once
      expect(Down).to have_received(:download).with('https://live.staticflickr.com/o.jpg', destination: anything).once
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
