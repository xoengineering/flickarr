# How to use Flickarr

A step-by-step guide to exporting your Flickr library.

## 1. Install Flickarr

```sh
gem install flickarr
```

## 2. Create a Flickr API app

You need your own Flickr API key and secret. Flickarr uses these to authenticate with the Flickr API on your behalf.

1. Go to https://www.flickr.com/services/apps/create/
2. Click "Apply for a Non-Commercial Key"
3. Fill in the form:
   - **Application Name**: anything you want (e.g. "Flickarr Export")
   - **Description**: anything (e.g. "Personal archive export")
4. Submit the form
5. Copy your **Key** and **Secret** from the confirmation page

<!-- TODO: screenshot of Flickr API key creation page -->
<!-- TODO: screenshot of Flickr API key and secret confirmation page -->

## 3. Initialize Flickarr

This creates a config file at `~/.flickarr/config.yml`.

```sh
flickarr init
```

By default, your archive will be saved to `~/Pictures/Flickarr/`. To use a different location:

```sh
flickarr init /path/to/your/archive
```

## 4. Save your API credentials

```sh
flickarr config:set api_key=YOUR_KEY shared_secret=YOUR_SECRET
```

Verify they're saved:

```sh
flickarr config
```

## 5. Authenticate with Flickr

```sh
flickarr auth
```

This starts the OAuth flow:

1. Flickarr prints a URL — open it in your browser
2. Flickr asks you to authorize the app — click "OK, I'll Authorize It"
3. Flickr shows you a verification code (9 digits, like `483-221-837`)
4. Paste the code back into your terminal

<!-- TODO: screenshot of Flickr OAuth authorization page -->
<!-- TODO: screenshot of Flickr verification code page -->

After authenticating, your access tokens, username, and user ID are saved to the config file. You only need to do this once.

## 6. Export your profile

```sh
flickarr export:profile
```

This downloads your profile metadata (JSON + YAML), avatar image, and account info to `~/Pictures/Flickarr/username/Profile/`.

## 7. Export your photos and videos

Export everything:

```sh
flickarr export
```

This paginates through your entire Flickr timeline (most recent first) and downloads each photo/video with full metadata sidecars. It respects Flickr's rate limit (1 request per second).

For a large library, this will take a while. You can:

- **Limit** how many to download in one run: `flickarr export --limit 100`
- **Interrupt** with Ctrl+C — progress is saved and the next run picks up where you left off
- **Resume** — just run `flickarr export` again; already-downloaded files are skipped instantly

Export only photos or only videos:

```sh
flickarr export:photos
flickarr export:videos
```

Export a single post by its Flickr URL:

```sh
flickarr export https://www.flickr.com/photos/username/12345678901
```

## 8. Export your albums and collections

Albums (sets) are exported as folders of reference files that point to your downloaded photos/videos:

```sh
flickarr export:sets
# or
flickarr export:albums
```

Export a single album by URL:

```sh
flickarr export:sets https://www.flickr.com/photos/username/sets/72157718538273371/
```

Collections (groups of albums) work the same way:

```sh
flickarr export:collections
```

## 9. Check your progress

```sh
flickarr status
```

Shows a summary of your archive: how many photos, videos, sets, and collections are downloaded vs. total available.

## 10. Utility commands

Open your archive folder in Finder:

```sh
flickarr open
```

Print the archive path (useful for scripting):

```sh
flickarr path
```

Check the error log for any failed downloads:

```sh
flickarr errors
cat $(flickarr errors)
```

## Re-downloading

By default, Flickarr skips files that already exist. To force a re-download (e.g. after we added richer metadata):

```sh
flickarr export --overwrite
flickarr export:profile --overwrite
flickarr export:sets --overwrite
```

## Archive structure

```
~/Pictures/Flickarr/username/
  Profile/
    avatar.jpg
    profile.json
    profile.yaml

  2024/
    03/
      15/
        12345678901_my-cool-photo.jpg       # original size photo
        12345678901_my-cool-photo.json      # full metadata (EXIF, geo, tags, license, etc.)
        12345678901_my-cool-photo.yaml      # same metadata in YAML
      16/
        98765432101_sunset-video.mp4        # original video (or best available)
        98765432101_sunset-video.jpg        # poster frame
        98765432101_sunset-video.json
        98765432101_sunset-video.yaml

  Sets/
    72157718538273371_vacation-photos/
      set.json                              # set metadata (title, description, dates)
      set.yaml
      photos.json                           # ordered list of photo references with file paths
      photos.yaml

  Collections/
    375727-72157666222057746_travel/
      collection.json                       # collection metadata
      collection.yaml
      sets.json                             # references to sets in this collection
      sets.yaml

  _errors.log                               # log of any failed downloads
```

## Metadata sidecar contents

Each photo/video sidecar includes:

- **Camera**: make, model, and full EXIF data
- **Dates**: taken, uploaded, last updated
- **Description**: post description/caption
- **Geo/Location**: latitude, longitude, locality, region, country
- **License**: ID, human-readable name, and Creative Commons URL
- **Owner**: username, real name, NSID
- **Sizes**: all available sizes with dimensions and URLs
- **Tags**: full tag list
- **URLs**: Flickr page URL
- **Views**: view count
- **Visibility**: public, friends, family

## Troubleshooting

**"Not authenticated" error**: Run `flickarr auth` to complete the OAuth flow.

**Video download 404**: Some older videos may not have their original resolution available on Flickr's CDN. Flickarr automatically falls back to the next best available size. If all sizes fail, the error is logged to `_errors.log`.

**Rate limiting**: Flickarr respects Flickr's 1 request/second rate limit. If you see rate limit errors, just wait and try again.

**Resuming after interruption**: Flickarr saves your progress after each page. Just run the same export command again to resume.
