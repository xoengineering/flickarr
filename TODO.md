# Flickarr v0.1 — Implementation Plan

## Context

Flickarr is a Ruby gem for exporting and archiving a user's Flickr photo library via the Flickr API. It downloads photos (originals when available) with complete metadata — EXIF embedded in images, plus sidecar JSON files. Output is an intuitive local folder/file structure. The gem provides both a Ruby library and a CLI.

## Dependencies

- **flickr** gem (from GitHub: `cyclotron3k/flickr`) — Flickr API client, OAuth 1.0a, zero runtime deps
- **down** — streaming file downloads with progress, retry, size limits
- **http** (http.rb) — modern HTTP client, used as `down` backend
- **optparse** (stdlib) — CLI argument parsing

## Architecture Overview

```
lib/
  flickarr.rb                    # Main entry, top-level require
  flickarr/
    version.rb                   # (exists)
    config.rb                    # Credentials storage (~/.flickarr/config.yml)
    client.rb                    # Wraps Flickr gem, auth flow, connection
    auth.rb                      # OAuth 1.0a interactive flow, token persistence
    downloader.rb                # Download photos using Down gem
    archive.rb                   # Orchestrator: paginate timeline, download + write
    photo.rb                     # Photo model: metadata, paths, filenames
    writer.rb                    # Write files to disk: photos, sidecar JSON, EXIF
    errors.rb                    # Custom error classes
    logger.rb                    # Logging wrapper

exe/
  flickarr                       # CLI entrypoint

spec/
  ...
```

## Phase 1: Foundation (auth, connection, client, errors)

### 1a. Config (`lib/flickarr/config.rb`)
- Load/save credentials to `~/.flickarr/config.yml`
- Stores: `api_key`, `shared_secret`, `access_token`, `access_secret`, `user_nsid`, `username`
- Can also be set via env vars: `FLICKARR_API_KEY`, `FLICKARR_SHARED_SECRET`

### 1b. Auth (`lib/flickarr/auth.rb`)
- Interactive OAuth 1.0a flow using the flickr gem
- `Flickarr::Auth.new(config).authenticate` → opens browser or prints URL, prompts for verifier
- Persists tokens back to config file
- `Flickarr::Auth.new(config).authenticated?` → checks for existing valid tokens

### 1c. Client (`lib/flickarr/client.rb`)
- Wraps `Flickr.new(api_key, shared_secret)` with token loading
- Sets `Flickr.cache` for API definition caching (in `~/.flickarr/flickr-api.yml`)
- Exposes convenience methods that map to Flickr API calls we need:
  - `photos(page:, per_page:)` → `flickr.people.getPhotos` (user's own, recent first)
  - `photo_info(photo_id:)` → `flickr.photos.getInfo`
  - `photo_exif(photo_id:)` → `flickr.photos.getExif`
  - `photo_sizes(photo_id:)` → `flickr.photos.getSizes`
- Error handling: wraps `Flickr::FailedResponse`, rate limit awareness

### 1d. Errors (`lib/flickarr/errors.rb`)
- `Flickarr::Error` (base)
- `Flickarr::AuthError`
- `Flickarr::ApiError`
- `Flickarr::DownloadError`
- `Flickarr::ConfigError`

## Phase 2: Local file structure & disk I/O

### 2a. Archive folder structure
```
flickarr-archive/
  photos/
    2024/
      2024-03-15_photo-title_abc123.jpg
      2024-03-15_photo-title_abc123.json    # sidecar metadata
    2023/
      ...
  .flickarr/
    config.yml          # can also live in archive root
    state.yml           # tracks progress: last page fetched, photo IDs done
    flickr-api.yml      # cached API definition
```

- Photos organized by year (from date taken)
- Filename: `{date-taken}_{sanitized-title}_{flickr-id}.{ext}`
- Flickr ID in filename guarantees uniqueness

### 2b. Writer (`lib/flickarr/writer.rb`)
- Write photo file to correct year folder
- Write sidecar JSON with all metadata (info, EXIF, sizes, tags, geo, license, URLs)
- Verify file written successfully (checksum or size check)
- Skip if file already exists (idempotent/resumable)

### 2c. Downloader (`lib/flickarr/downloader.rb`)
- Uses `Down` gem with `http.rb` backend
- Downloads original size when available, falls back to largest
- Streams to temp file, then moves to final location
- Retry on transient failures (network errors, 5xx)

## Phase 3: Photo timeline export

### 3a. Photo model (`lib/flickarr/photo.rb`)
- Wraps Flickr API response into a clean object
- Knows how to derive its filename, year folder, download URL
- Holds merged metadata from getInfo + getExif + getSizes

### 3b. Archive orchestrator (`lib/flickarr/archive.rb`)
- `Flickarr::Archive.new(config:, output_path:)`
- `#run` — main loop:
  1. Authenticate (or load tokens)
  2. Paginate through `people.getPhotos` (recent first, working older)
  3. For each photo: fetch metadata, download, write to disk
  4. Track progress in state file (resumable)
  5. Log progress: "Downloaded 42/1337 photos..."
- Handles interruption gracefully (Ctrl+C saves state)

## Phase 4: CLI

### CLI (`exe/flickarr`)
- `flickarr auth` — run OAuth flow, save credentials
- `flickarr export [--output PATH]` — run the archive
- `flickarr status` — show progress, photo count, etc.
- Use stdlib `optparse` for argument parsing

## Verification

- `bundle exec rake spec` — unit tests for config, photo model, writer, filename sanitization
- `bundle exec rake rubocop` — style compliance
- Manual test: `flickarr auth` then `flickarr export --output ./test-archive` with real credentials
- Check output folder structure, sidecar JSON completeness, image file integrity

## Implementation Order

1. Add dependencies to gemspec (flickr from git, down, http)
2. Errors
3. Config
4. Auth
5. Client
6. Photo model
7. Writer
8. Downloader
9. Archive orchestrator
10. CLI
11. Tests throughout
