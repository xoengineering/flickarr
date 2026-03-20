# Flickarr TODO

## Refactors
- [ ] Refactor CLI arg parsing to use stdlib optparse
- [ ] Rename `_profile/` to `profile/`

## Features
- [ ] Export sets/collections as folders of reference files
- [ ] Graceful Ctrl+C handling (save progress, resume later)
- [ ] Resume state: save last photo ID/page after export:photos, start from there next run
- [ ] `flickarr status` command (show progress, photo count, etc.)
- [ ] Retry on transient network failures (5xx, timeouts)
- [ ] Verify downloaded file integrity (checksum or size check)
- [ ] Video post support (download video files, not just photos)
