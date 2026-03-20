# Flickarr

Export an archive of your Flickr library — photos, videos, metadata, tags, albums, collections, and profile.

## What you get

```
~/Pictures/Flickarr/username/
  Profile/
    avatar.jpg
    profile.json
    profile.yaml
  2016/
    11/
      02/
        12345678901_cubs-win-photo.jpg
        12345678901_cubs-win-photo.json
        12345678901_cubs-win-photo.yaml
  Sets/
    72157718538273371_vacation-photos/
      set.json
      set.yaml
      photos.json
      photos.yaml
  Collections/
    375727-72157666222057746_travel/
      collection.json
      collection.yaml
      sets.json
      sets.yaml
```

Photos and videos are organized by date taken (`YYYY/MM/DD`). Each media file has JSON and YAML sidecar files with full metadata: EXIF, geo/location, tags, license, owner, sizes, and more.

Sets and collections are folders of reference files that point to the downloaded media.

## Installation

```sh
gem install flickarr
```

## Quick start

```sh
flickarr init
flickarr config:set api_key=YOUR_KEY shared_secret=YOUR_SECRET
flickarr auth
flickarr export
```

See [HOWTO.md](HOWTO.md) for detailed setup instructions.

## Usage

```sh
# Export everything
flickarr export

# Export a single post by URL
flickarr export https://www.flickr.com/photos/username/12345678901

# Export only photos or only videos
flickarr export:photos
flickarr export:videos

# Export with a limit
flickarr export --limit 10

# Re-download existing files
flickarr export --overwrite

# Export albums, sets, collections, profile
flickarr export:sets
flickarr export:albums
flickarr export:collections
flickarr export:profile

# Utility commands
flickarr status
flickarr open
flickarr path
flickarr config
flickarr errors
```

Run `flickarr help` for the full command reference.

## Requirements

- Ruby >= 4.0
- A [Flickr API key](https://flickr.com/services/apps/create)

## Development

```sh
git clone https://github.com/veganstraightedge/flickarr.git
cd flickarr
bin/setup
bundle exec rake spec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/veganstraightedge/flickarr.

## License

MIT License. See [LICENSE.txt](LICENSE.txt).
