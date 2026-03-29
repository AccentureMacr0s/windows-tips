# Instagram GIF Guide — Automated GIPHY Pipeline

A complete guide for creating iOS-optimised GIFs with AI tools, uploading them
to GIPHY automatically via a GitHub Actions pipeline, and surfacing them in
Instagram Stories and DMs via the GIF sticker search.

---

## Table of Contents

1. [Quick-start Overview](#1-quick-start-overview)
2. [Prerequisites](#2-prerequisites)
3. [Step 1 — Generate the GIF](#3-step-1--generate-the-gif)
4. [Step 2 — Add Metadata and Tags](#4-step-2--add-metadata-and-tags)
5. [Step 3 — Upload to GIPHY](#5-step-3--upload-to-giphy)
6. [Step 4 — GitHub Actions Pipeline](#6-step-4--github-actions-pipeline)
7. [Step 5 — Use in Instagram](#7-step-5--use-in-instagram)
8. [Security and Anonymity Best Practices](#8-security-and-anonymity-best-practices)
9. [Tool Reference](#9-tool-reference)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Quick-start Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  video file  →  generate_gif.py  →  output_ios.gif              │
│  base tags   →  add_tags.py      →  tags.txt                    │
│  tags.txt    →  upload_to_giphy.rb →  GIPHY GIF URL             │
│  all steps   →  giphy-pipeline.yml (GitHub Actions)             │
└─────────────────────────────────────────────────────────────────┘
```

The entire flow is automated via the pipeline in
`.github/workflows/giphy-pipeline.yml`.  Trigger it manually from the
**Actions** tab, or push a video file under the `videos/` directory.

---

## 2. Prerequisites

| Tool / Account | Purpose | Install |
|---|---|---|
| FFmpeg | GIF generation | `sudo apt install ffmpeg` / [ffmpeg.org](https://ffmpeg.org) |
| Python 3.7+ | `generate_gif.py`, `add_tags.py` | [python.org](https://www.python.org) |
| Ruby 3.x | `register_account.rb`, `upload_to_giphy.rb` | [ruby-lang.org](https://www.ruby-lang.org) |
| Bundler | Ruby gem management | `gem install bundler` |
| GIPHY Developer account | Upload API key | [developers.giphy.com](https://developers.giphy.com) |

### Install Ruby dependencies

```bash
cd scripts
bundle install
```

---

## 3. Step 1 — Generate the GIF

### `scripts/generate_gif.py`

Converts any video file to a GIF optimised for iOS/iPhone playback using a
two-pass FFmpeg palette workflow for maximum colour fidelity.

**iOS-specific FFmpeg settings:**

| Parameter | Value | Reason |
|---|---|---|
| `fps` | 12 | Keeps file size < 15 MB on typical iPhone clips |
| `scale` | `480:-1` | Matches Instagram Story display width |
| `flags=lanczos` | — | Sharper downscale than bilinear |
| `palettegen/paletteuse` | 256 colours | Best GIF quality within format limits |
| `loop` | `0` | Infinite loop (required for Instagram) |

**Basic conversion:**

```bash
python scripts/generate_gif.py videos/clip.mp4
# → output_ios.gif  (480px wide, 12 fps, ≤ 15 MB)
```

**Custom options:**

```bash
# Slower frame rate, narrower width
python scripts/generate_gif.py clip.mp4 --fps 10 --width 360

# Trim 5 seconds starting at 3 s
python scripts/generate_gif.py clip.mp4 --start 3 --duration 5

# Specify output path
python scripts/generate_gif.py clip.mp4 --output my_gif.gif
```

**Ruby wrapper — `gif_converter.rb` (inline snippet):**

```ruby
require 'open3'

def convert_to_gif(input:, output: 'output_ios.gif', fps: 12, width: 480)
  palette = '/tmp/palette.png'

  pass1 = [
    'ffmpeg', '-y', '-i', input,
    '-vf', "fps=#{fps},scale=#{width}:-1:flags=lanczos,palettegen",
    '-frames:v', '1', palette
  ]
  pass2 = [
    'ffmpeg', '-y', '-i', input, '-i', palette,
    '-lavfi', "fps=#{fps},scale=#{width}:-1:flags=lanczos [x]; [x][1:v] paletteuse",
    '-loop', '0', output
  ]

  [pass1, pass2].each do |cmd|
    stdout, stderr, status = Open3.capture3(*cmd)
    raise "FFmpeg error:\n#{stderr}" unless status.success?
  end

  size_mb = File.size(output) / (1024.0 * 1024)
  raise "GIF too large: #{size_mb.round(2)} MB (max 15 MB)" if size_mb > 15

  output
end
```

---

## 4. Step 2 — Add Metadata and Tags

### `scripts/add_tags.py`

Builds a GIPHY-compliant tag list, automatically expanding Cyrillic tags with
their Latin transliterations to maximise discoverability.

**GIPHY tag rules enforced by the script:**

| Rule | Value |
|---|---|
| Maximum tags | 10 |
| Maximum tag length | 30 characters |
| Allowed characters | Letters, digits, spaces, `_`, `-` |
| Cyrillic tags | Preserved + Latin transliteration added |

**Examples:**

```bash
# Cyrillic tags are automatically transliterated
python scripts/add_tags.py --tags "юрий клинский,gif,funny" --print
# → юрий клинский,yurij klinskij,gif,funny

# Write to file (used by the pipeline)
python scripts/add_tags.py --tags "animation,loop,ios" --output tags.txt

# Use environment variable (same as GitHub Actions)
GIF_TAGS="animation,loop" python scripts/add_tags.py --print
```

**Cyrillic → Latin transliteration table (excerpt):**

| Cyrillic | Latin |
|---|---|
| ю | yu |
| я | ya |
| ж | zh |
| ш | sh |
| щ | shch |
| ч | ch |
| ц | ts |

---

## 5. Step 3 — Upload to GIPHY

### `scripts/upload_to_giphy.rb`

Uploads the GIF to GIPHY via the [GIPHY Upload API](https://developers.giphy.com/docs/api/endpoint/#upload)
using a multipart POST request.

**Environment variables:**

| Variable | Required | Description |
|---|---|---|
| `GIPHY_API_KEY` | ✅ | Your GIPHY Developer API key |
| `GIF_PATH` | ✅ | Local path to the GIF file |
| `GIF_TAGS` | — | Comma-separated tags from `add_tags.py` |
| `GIF_SOURCE` | — | Attribution URL (e.g. your GitHub repo) |
| `GIF_TITLE` | — | Human-readable title |

**Local usage:**

```bash
export GIPHY_API_KEY="your_api_key_here"
export GIF_PATH="output_ios.gif"
export GIF_TAGS="animation,ios,loop"
export GIF_SOURCE="https://github.com/your-org/your-repo"

cd scripts && ruby upload_to_giphy.rb
# → [upload_to_giphy] Upload successful. GIF ID: abc123xyz
# → [upload_to_giphy] URL: https://giphy.com/gifs/abc123xyz
```

### `scripts/register_account.rb`

Validates your GIPHY API key is active and surfaces the key plus a channel
username as GitHub Actions step outputs for use by downstream jobs.

```bash
export GIPHY_API_KEY="your_api_key_here"
cd scripts && ruby register_account.rb
# → [register_account] API key is valid.
# → [register_account] Registration complete. Username: swift_pixel_a1b2c3
```

---

## 6. Step 4 — GitHub Actions Pipeline

### `.github/workflows/giphy-pipeline.yml`

A four-job pipeline that automates the entire flow:

```
register → create-gif → tag-gif → upload
```

| Job | Script | Purpose |
|---|---|---|
| `register` | `register_account.rb` | Validate API key; output credentials |
| `create-gif` | `generate_gif.py` | Convert video → iOS GIF |
| `tag-gif` | `add_tags.py` | Build & validate tag list |
| `upload` | `upload_to_giphy.rb` | POST GIF to GIPHY API |

### Setup

1. **Add your GIPHY API key as a secret:**
   - Go to **Settings → Secrets and variables → Actions → New repository secret**
   - Name: `GIPHY_API_KEY`
   - Value: your key from [developers.giphy.com](https://developers.giphy.com)

2. **Trigger the pipeline:**
   - **Manual:** Actions tab → *GIPHY Upload Pipeline* → *Run workflow*
     - Fill in `video_path`, `gif_tags`, `fps`, `width`, and optional `gif_title`.
   - **Automatic:** Push a video file under the `videos/` directory.

### Pipeline inputs (manual trigger)

| Input | Default | Description |
|---|---|---|
| `video_path` | `videos/input.mp4` | Path to source video in the repo |
| `gif_tags` | `gif,animation,ios` | Comma-separated tags |
| `gif_fps` | `12` | Frames per second |
| `gif_width` | `480` | Output width in pixels |
| `gif_title` | *(empty)* | Title shown on GIPHY |

### Pipeline skeleton (abbreviated)

```yaml
jobs:
  register:
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
      - run: bundle install
        working-directory: scripts
      - run: ruby register_account.rb
        id: register
        env:
          GIPHY_API_KEY: ${{ secrets.GIPHY_API_KEY }}

  create-gif:
    needs: register
    steps:
      - run: sudo apt-get install -y ffmpeg
      - run: python scripts/generate_gif.py "$INPUT_VIDEO" --fps 12 --width 480
        env:
          INPUT_VIDEO: ${{ github.event.inputs.video_path }}

  tag-gif:
    needs: create-gif
    steps:
      - run: python scripts/add_tags.py --tags "$GIF_TAGS"
        env:
          GIF_TAGS: ${{ github.event.inputs.gif_tags }}

  upload:
    needs: [register, create-gif, tag-gif]
    steps:
      - run: ruby upload_to_giphy.rb
        working-directory: scripts
        env:
          GIPHY_API_KEY: ${{ needs.register.outputs.giphy_api_key }}
          GIF_PATH:      ../output_ios.gif
          GIF_TAGS:      ${{ steps.read-tags.outputs.gif_tags }}
```

---

## 7. Step 5 — Use in Instagram

Once the GIF is live on GIPHY (may take up to 24 hours to index):

### Instagram Stories

1. Open a new Story → tap the **sticker** icon.
2. Search for your tag (e.g. `юрий клинский` or the Latin transliteration).
3. Tap the GIF to add it to your Story.

### Instagram DMs

1. Open a conversation → tap the **GIF** button.
2. Search for your tag.
3. Tap the GIF to send it.

> **Tip:** For a GIF to appear in Instagram's sticker search, the GIPHY channel
> that uploaded it must be **verified**.  Apply at
> [support.giphy.com/hc/en-us/articles/360020623532](https://support.giphy.com/hc/en-us/articles/360020623532).

---

## 8. Security and Anonymity Best Practices

| Topic | Recommendation |
|---|---|
| **API key storage** | Store in GitHub Actions secrets, never in code or logs |
| **Key rotation** | Rotate via [developers.giphy.com](https://developers.giphy.com) after any exposure |
| **Log masking** | GitHub Actions automatically masks secret values in logs |
| **Output scoping** | API key travels only between jobs as a masked step output |
| **HTTPS only** | All API calls in the scripts use HTTPS (`api.giphy.com`, `upload.giphy.com`) |
| **Minimal permissions** | Use a GIPHY key scoped to upload only; do not reuse a key across unrelated projects |
| **Credential lifetime** | Generate per-pipeline credentials where possible; revoke after use |
| **Repo access** | Set the repository to private while testing; make public only when ready |

### How secrets flow through the pipeline

```
GitHub Actions secret
  GIPHY_API_KEY
       │
       ▼
  register job
  └─ register_account.rb
     └─ writes to $GITHUB_OUTPUT (masked)
             │
             ▼
  upload job
  └─ GIPHY_API_KEY = ${{ needs.register.outputs.giphy_api_key }}
     └─ upload_to_giphy.rb → HTTPS POST → upload.giphy.com
```

The raw key is never printed to the Actions log.

---

## 9. Tool Reference

| Tool | Language | Role |
|---|---|---|
| `scripts/register_account.rb` | Ruby | Validate API key; output credentials to pipeline |
| `scripts/generate_gif.py` | Python | Convert video → iOS-optimised GIF via FFmpeg |
| `scripts/add_tags.py` | Python | Build & validate GIPHY tag list; expand Cyrillic |
| `scripts/upload_to_giphy.rb` | Ruby | Upload GIF to GIPHY via Upload API |
| `scripts/Gemfile` | Ruby | Declares `multipart-post` gem dependency |
| `.github/workflows/giphy-pipeline.yml` | YAML | Four-job GitHub Actions pipeline |
| FFmpeg | C (system) | Video decoding, palette generation, GIF encoding |

---

## 10. Troubleshooting

| Problem | Cause | Solution |
|---|---|---|
| `GIPHY_API_KEY is not set` | Missing secret | Add key in Settings → Secrets → Actions |
| `GIPHY API key validation failed (HTTP 401)` | Invalid or expired key | Regenerate key at developers.giphy.com |
| `GIF too large` | Clip too long / high fps | Add `--duration`, lower `--fps` or `--width` |
| `ffmpeg: command not found` | FFmpeg not installed | Run `sudo apt-get install ffmpeg` or install from ffmpeg.org |
| `No valid tags after processing` | All tags failed validation | Check tag length (≤ 30 chars) and allowed characters |
| GIF not appearing in Instagram search | Channel not verified | Apply for GIPHY channel verification |
| `bundle: command not found` | Bundler not installed | Run `gem install bundler` |
| Tags truncated to 10 | GIPHY limit | Provide at most 10 tags (script auto-truncates) |
