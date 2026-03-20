require 'tmpdir'

RSpec.describe Flickarr::CLI do
  describe 'status command' do
    it 'reports archive status' do
      dir = File.join(Dir.tmpdir, "flickarr-cli-test-#{Process.pid}")
      config_path = File.join(dir, 'config.yml')
      archive_path = File.join(dir, 'library', 'testuser')
      FileUtils.mkdir_p(dir)

      config = Flickarr::Config.new
      config.api_key = 'test-key'
      config.shared_secret = 'test-secret'
      config.username = 'testuser'
      config.library_path = File.join(dir, 'library')
      config.save(config_path)

      FileUtils.mkdir_p File.join(archive_path, 'Profile')
      File.write File.join(archive_path, 'Profile', 'profile.json'), '{}'

      FileUtils.mkdir_p File.join(archive_path, '2024', '03', '15')
      File.write File.join(archive_path, '2024', '03', '15', '12345_cat.jpg'), 'photo'
      File.write File.join(archive_path, '2024', '03', '15', '12345_cat.json'), '{}'
      File.write File.join(archive_path, '2024', '03', '15', '12345_cat.yaml'), '{}'
      File.write File.join(archive_path, '2024', '03', '15', '67890_dog.mp4'), 'video'
      File.write File.join(archive_path, '2024', '03', '15', '67890_dog.json'), '{}'
      File.write File.join(archive_path, '2024', '03', '15', '67890_dog.yaml'), '{}'

      FileUtils.mkdir_p File.join(archive_path, 'Sets', '111_my-set')
      File.write File.join(archive_path, 'Sets', '111_my-set', 'set.json'), '{}'

      FileUtils.mkdir_p File.join(archive_path, 'Collections', '222_my-collection')
      File.write File.join(archive_path, 'Collections', '222_my-collection', 'collection.json'), '{}'

      cli = described_class.new(['status'], config_path: config_path)

      expect { cli.run }.to output(
        a_string_matching(/Archive:/)
        .and(matching(/Collections:.*1/))
        .and(matching(/Disk usage:/))
        .and(matching(/Photos:.*1/))
        .and(matching(/Profile:.*Downloaded/))
        .and(matching(/Sets:.*1/))
        .and(matching(/Videos:.*1/))
      ).to_stdout
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'reports when archive does not exist' do
      dir = File.join(Dir.tmpdir, "flickarr-cli-test-#{Process.pid}")
      config_path = File.join(dir, 'config.yml')
      FileUtils.mkdir_p(dir)

      config = Flickarr::Config.new
      config.username = 'testuser'
      config.library_path = File.join(dir, 'library')
      config.save(config_path)

      cli = described_class.new(['status'], config_path: config_path)
      expect { cli.run }.to output(/No archive found/).to_stdout
    ensure
      FileUtils.rm_rf(dir)
    end
  end
end
