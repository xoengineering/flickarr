# Flickarr TODO

## Refactors
- [x] Refactor CLI arg parsing to use stdlib optparse
- [ ] Refactor to Post, with Photo < Post, Video < Post

## Features
- [ ] `flickarr status` command (show progress, photo count, etc.)
- [ ] Retry on transient network failures (5xx, timeouts)
- [ ] Verify downloaded file integrity (checksum or size check)
