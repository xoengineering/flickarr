# rubocop:disable RSpec/VerifiedDoubles
require 'slugify'

RSpec.describe Flickarr::Post do
  describe '.id_from_url' do
    it 'extracts post id from a standard Flickr URL' do
      url = 'https://www.flickr.com/photos/testuser/3839885270'
      expect(described_class.id_from_url(url)).to eq('3839885270')
    end

    it 'extracts post id from a URL with trailing path segments' do
      url = 'https://www.flickr.com/photos/testuser/3839885270/in/photostream/'
      expect(described_class.id_from_url(url)).to eq('3839885270')
    end

    it 'extracts post id from a URL with nsid instead of username' do
      url = 'https://www.flickr.com/photos/12345678@N00/3839885270'
      expect(described_class.id_from_url(url)).to eq('3839885270')
    end

    it 'returns nil for non-Flickr URLs' do
      expect(described_class.id_from_url('https://example.com/photo/123')).to be_nil
    end
  end

  describe '.file_path_from_list_item' do
    it 'computes the expected file path for photos' do
      item = double(
        'list_item',
        datetaken: '2024-03-15 14:30:00', datetakenunknown: '0', dateupload: '1710500000',
        id: '3839885270', media: 'photo', originalformat: 'jpg', title: 'My Cool Cat!'
      )

      path = described_class.file_path_from_list_item(item, archive_path: '/archive')

      expect(path).to eq('/archive/2024/03/15/3839885270_my-cool-cat.jpg')
    end

    it 'uses mp4 for videos' do
      item = double(
        'video_item',
        datetaken: '2024-03-15 14:30:00', datetakenunknown: '0', dateupload: '1710500000',
        id: '111', media: 'video', originalformat: 'jpg', title: 'My Video'
      )

      path = described_class.file_path_from_list_item(item, archive_path: '/archive')

      expect(path).to eq('/archive/2024/03/15/111_my-video.mp4')
    end
  end

  describe '.build' do
    let(:dates) do
      double('dates', taken: '2024-03-15 14:30:00', posted: '1710500000', takenunknown: 0, lastupdate: '1710600000')
    end
    let(:owner) { double('owner', nsid: '123@N00', realname: 'Test', username: 'testuser') }
    let(:visibility) { double('visibility', isfamily: 0, isfriend: 0, ispublic: 1) }
    let(:urls) { double('urls', url: []) }
    let(:tags) { double('tags', tag: []) }
    let(:sizes) { [double('size', height: 1200, label: 'Original', source: 'https://example.com/o.jpg', media: 'photo', width: 1600)] }

    it 'returns a Photo for photo media' do
      info = double('info', dates: dates, description: '', id: '1', license: '0', media: 'photo',
                            originalformat: 'jpg', owner: owner, tags: tags, title: 'Test',
                            urls: urls, views: '0', visibility: visibility)

      post = described_class.build(info: info, sizes: sizes)

      expect(post).to be_a(Flickarr::Photo)
    end

    it 'returns a Video for video media' do
      info = double('info', dates: dates, description: '', id: '1', license: '0', media: 'video',
                            originalformat: 'jpg', owner: owner, tags: tags, title: 'Test',
                            urls: urls, views: '0', visibility: visibility)

      post = described_class.build(info: info, sizes: sizes)

      expect(post).to be_a(Flickarr::Video)
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
