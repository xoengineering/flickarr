## [Unreleased]

- Add `flickarr auth` command for Flickr OAuth authentication
- Add `flickarr config` and `flickarr config:set` for managing credentials
- Add `flickarr export:photo URL` to export a single photo with full metadata sidecars
- Add `flickarr export:photos` to bulk export all photos from timeline (paginated, recent first)
- Add `flickarr export:profile` to export Flickr profile (JSON, YAML, avatar)
- Add `--overwrite` flag to re-download existing files; default skips them
- Add `flickarr init` command to create config directory and stub file
- Add Client with query object API: `client.photo(id:).info`, `client.profile(user_id:).info`
- Add Config for loading/saving credentials with env var fallback
- Add Error class hierarchy (AuthError, ApiError, ConfigError, DownloadError)
- Add Photo model with slug, date-based folder paths, EXIF, and original size download
- Add Profile model with avatar URL construction and disk writing

## [0.1.0] - 2026-03-19

- Initial release
