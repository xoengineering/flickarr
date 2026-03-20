## [Unreleased]

- Add `flickarr auth` command for Flickr OAuth authentication
- Add `flickarr config` and `flickarr config:set` for managing credentials
- Add `flickarr export:photo URL` to export a single photo with full metadata sidecars
- Add `flickarr export:photos` to bulk export all photos from timeline (paginated, recent first)
- Add `--limit N` flag to stop bulk export after N photos
- Add `flickarr export:profile` to export Flickr profile (JSON, YAML, avatar, social links)
- Add `--overwrite` flag to re-download existing files; default skips them
- Add `flickarr init` command to create config directory and stub file
- Add Client with query object API: `client.photo(id:).info`, `client.profile(user_id:).info`
- Add Config for loading/saving credentials with env var fallback
- Add Error class hierarchy (AuthError, ApiError, ConfigError, DownloadError)
- Add License model mapping Flickr license IDs to human-readable names and CC URLs
- Add Photo model with slug, date-based folder paths, EXIF, geo, and original size download
- Add Profile model with data from both people.getInfo and profile.getProfile
- Add RateLimiter (1 req/sec) to all Flickr API calls
- Add resume state: saves last page to config, resumes from there on next run
- Add video post support with poster frame download
- Graceful error handling for invalid photo IDs

## [0.1.0] - 2026-03-19

- Initial release
