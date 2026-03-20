## [Unreleased]

- Add `flickarr auth` command for Flickr OAuth authentication
- Add `flickarr config` and `flickarr config:set` for managing credentials
- Add `flickarr export:collections` to export collections as folders of set references
- Add `flickarr export` / `export:posts` to bulk export all posts (photos + videos)
- Add `flickarr export:photo URL` to export a single post by Flickr URL
- Add `flickarr export:photos` to export only photos
- Add `flickarr export:videos` to export only videos
- Add `--limit N` flag to stop bulk export after N posts
- Add `flickarr export:profile` to export Flickr profile (JSON, YAML, avatar, social links)
- Add `flickarr export:sets` to export photosets with photo reference files
- Add `--overwrite` flag to re-download existing files; default skips them
- Add `flickarr init` command to create config directory and stub file
- Add `flickarr status` command showing archive summary
- Add Client with query object API: `client.photo(id:).info`, `client.profile(user_id:).info`
- Add Config for loading/saving credentials with env var fallback
- Add Error class hierarchy (AuthError, ApiError, ConfigError, DownloadError)
- Add License model mapping Flickr license IDs to human-readable names and CC URLs
- Add Post/Photo/Video model hierarchy with delegated media behavior
- Add Profile model with data from both people.getInfo and profile.getProfile
- Add RateLimiter (1 req/sec) to all Flickr API calls
- Add resume state: saves last page to config, resumes from there on next run
- Add video post support with poster frame download
- Fast skip: check file existence from list data before making per-photo API calls
- Graceful Ctrl+C handling: saves progress and exits cleanly
- Graceful error handling for invalid photo IDs

## [0.1.0] - 2026-03-19

- Initial release
