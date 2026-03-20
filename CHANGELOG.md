## [Unreleased]

- Add `flickarr auth` command for Flickr OAuth authentication
- Add `flickarr config` and `flickarr config:set` for managing credentials
- Add `flickarr export:profile` to export Flickr profile (JSON, YAML, avatar)
- Add `flickarr init` command to create config directory and stub file
- Add Config for loading/saving credentials with env var fallback
- Add Client wrapping the Flickr gem with OAuth token management
- Add Error class hierarchy (AuthError, ApiError, ConfigError, DownloadError)
- Add Profile model with avatar URL construction and disk writing

## [0.1.0] - 2026-03-19

- Initial release
