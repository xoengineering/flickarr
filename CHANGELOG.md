## [Unreleased]

## [0.1.5] - 2026-03-23

- Add `flickarr version` / `-v` / `--version` command
- Show version header in help output
- Check for gem updates: always on `version` and `status`, periodically (daily) after other commands

## [0.1.4] - 2026-03-22

- Retry transient network errors (connection reset, timeouts, HTML-instead-of-JSON) up to 3 times with backoff

## [0.1.3] - 2026-03-22

- Fix crash on photos with partial location data (e.g. coordinates but no locality)

## [0.1.1] - 2026-03-19

- Fix repo URLs in the gem/gemspec, so that rubygems.org links to the correct place

## [0.1.0] - 2026-03-19

### Commands
- `flickarr init` — create config directory and stub config file
- `flickarr auth` — authenticate with Flickr via OAuth
- `flickarr config` / `flickarr config <key>` — show configuration
- `flickarr config:set key=value` — set configuration values
- `flickarr export` / `flickarr export:posts` — export all posts (photos + videos)
- `flickarr export URL` — export a single post by Flickr URL
- `flickarr export:photos` — export only photos
- `flickarr export:videos` — export only videos
- `flickarr export:sets` / `flickarr export:albums` — export photosets/albums
- `flickarr export:collections` — export collections (groups of albums)
- `flickarr export:profile` — export Flickr profile (avatar, metadata, social links)
- `flickarr status` — show archive summary with local/upstream counts
- `flickarr open` — open archive folder in Finder
- `flickarr path` — print archive path (for scripting)
- `flickarr errors` — print path to _errors.log
- `flickarr help` / `-h` / `--help` — show help

### Features
- Post/Photo/Video model hierarchy with delegated media behavior
- Full metadata sidecars (JSON + YAML) with EXIF, geo, tags, license, owner, sizes, URLs
- License model mapping Flickr IDs to human-readable names and Creative Commons URLs
- Profile data merged from people.getInfo and profile.getProfile
- Video support with poster frame download
- Fallback to smaller video sizes when original is unavailable on CDN
- Rate limiter (1 req/sec) on all Flickr API calls
- Resume state: saves last page per media type, resumes on next run
- Fast skip: checks file existence from list data before per-post API calls
- Graceful Ctrl+C: saves progress and exits cleanly
- Failed exports logged to _errors.log with post URL and timestamp
- `--limit N` counts actual downloads, not skips
- `--overwrite` to re-download existing files; default skips them
- `--overwrite` on `status` busts cached upstream totals
- Smart URL routing: `export URL` auto-detects post, set/album, collection, or profile URLs
- Single post/set/collection export by URL
- Client with query object API: `client.photo(id:).info`, `client.profile(user_id:).info`
