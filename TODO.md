# Flickarr TODO

## Refactors
- [ ] Refactor CLI arg parsing to use stdlib optparse

## Features
- [ ] Export sets/collections as folders of reference files
- [ ] Graceful Ctrl+C handling (save progress, resume later)
- [ ] State tracking for resumable bulk exports
- [ ] `flickarr status` command (show progress, photo count, etc.)
- [ ] Retry on transient network failures (5xx, timeouts)
- [ ] Verify downloaded file integrity (checksum or size check)
