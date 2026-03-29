# How To: Add a GIF to Instagram Using AI (Giphy)

This guide walks you through creating a custom GIF with AI tools and uploading it to Instagram via Giphy.

---

## Overview

[Giphy](https://giphy.com) is the most widely used GIF platform and is natively integrated into Instagram Stories, DMs, and Reels stickers. By uploading your own GIF to Giphy as a **verified artist or brand**, it becomes searchable directly inside Instagram.

---

## Step 1 — Create or Generate Your GIF Using AI

### Option A: AI Video-to-GIF (recommended)

1. Use an AI video generator (e.g. **Runway ML**, **Pika Labs**, or **Kling AI**) to create a short clip (2–6 seconds).
2. Export the clip as `.mp4` or `.mov`.
3. Convert it to GIF using one of:
   - [Ezgif.com](https://ezgif.com/video-to-gif) — free, browser-based
   - [FFmpeg](https://ffmpeg.org/) (Windows / PowerShell):
     ```powershell
     ffmpeg -i input.mp4 -vf "fps=15,scale=480:-1:flags=lanczos" -loop 0 output.gif
     ```

### Option B: AI Image Animation

1. Generate a still image with an AI tool (e.g. **Midjourney**, **DALL·E**, **Stable Diffusion**).
2. Animate it using **Viggle AI**, **Leiapix**, or **Animated Drawings**.
3. Export as GIF or convert from video (see Option A, step 3).

### Recommended GIF specs for Giphy / Instagram

| Setting     | Value                    |
|-------------|--------------------------|
| Width       | 480 px (minimum)         |
| Frame rate  | 15–24 fps                |
| Duration    | 2–6 seconds              |
| File size   | ≤ 15 MB                  |
| Format      | `.gif`                   |

---

## Step 2 — Upload Your GIF to Giphy

1. Go to [giphy.com](https://giphy.com) and sign in (or create a free account).
2. Click **Upload** (top-right corner).
3. Drag and drop your `.gif` file or paste a URL.
4. Add:
   - **Source URL** — link to your website or social profile.
   - **Tags** — include your name/brand so people can find it (e.g. `юрий клинский`, `yuriy klinsky`, your niche keywords).
5. Click **Upload to GIPHY**.

> **Note:** Newly uploaded GIFs from regular accounts are **private by default**. To make them searchable in Instagram, you need a verified Giphy artist or brand channel (see Step 3).

---

## Step 3 — Get a Verified Giphy Artist Channel

A verified Giphy channel makes your GIFs publicly searchable inside Instagram, TikTok, WhatsApp, and other platforms.

1. Apply at: [giphy.com/submit](https://giphy.com/submit)
2. Fill in your **channel name**, **description**, **website**, and **social links**.
3. Upload at least **5 original GIFs** to your channel before applying.
4. Wait for Giphy review (usually 1–7 business days).

Once approved, all GIFs you upload to your channel will appear in the Instagram GIF sticker search.

---

## Step 4 — Use Your GIF in Instagram

### In Instagram Stories

1. Open Instagram and tap **+** → **Story**.
2. Take or upload a photo/video.
3. Tap the **sticker icon** (😊) at the top.
4. Tap **GIF**.
5. Search for your Giphy channel name or tags (e.g. `юрий клинский`).
6. Tap your GIF to add it to the story.
7. Resize, rotate, and place it anywhere.
8. Tap **Your Story** to post.

### In Instagram DMs

1. Open a conversation.
2. Tap the **GIF** button in the message bar.
3. Search for your tag or channel name.
4. Tap to send.

---

## Tips for Discoverability

- Use **consistent tags** across all your GIFs (brand name, niche keywords, your name).
- Add **transliterated versions** of your name as tags (e.g. both `юрий клинский` and `yuriy klinsky`).
- Upload GIFs in **series** (5–10 at a time) — Giphy favors active channels.
- Share your Giphy channel link in your Instagram bio to drive traffic.

---

## Additional Guides

| File | Description |
|------|-------------|
| [`phone-browser-guide.md`](phone-browser-guide.md) | Complete workflow from a phone browser — no desktop or Instagram app needed |
| [`update-existing-gif.md`](update-existing-gif.md) | Edit tags, reassign, or bulk-retag existing Giphy GIFs |
| [`validate-gif.ps1`](validate-gif.ps1) | PowerShell script — validates a tag or GIF ID is live and searchable via the Giphy API |

---

## Quick Reference

| Tool            | Purpose                        | Link                                      |
|-----------------|--------------------------------|-------------------------------------------|
| Giphy           | Host & distribute GIFs         | [giphy.com](https://giphy.com)            |
| Giphy Developers| API keys & documentation       | [developers.giphy.com](https://developers.giphy.com) |
| Ezgif           | Convert video → GIF            | [ezgif.com](https://ezgif.com)            |
| Runway ML       | AI video generation            | [runwayml.com](https://runwayml.com)      |
| Pika Labs       | AI video generation            | [pika.art](https://pika.art)              |
| FFmpeg          | CLI video/GIF conversion       | [ffmpeg.org](https://ffmpeg.org)          |
| Midjourney      | AI image generation            | [midjourney.com](https://midjourney.com)  |

---

## Troubleshooting

| Problem                                     | Solution                                                                 |
|---------------------------------------------|--------------------------------------------------------------------------|
| GIF not showing in Instagram search         | Ensure your Giphy channel is verified; newly uploaded GIFs may take 24h  |
| GIF too large to upload                     | Reduce resolution to 480 px wide or lower frame rate to 10–12 fps        |
| Tags not returning results in Instagram     | Use simpler, shorter tags; avoid special characters                       |
| Giphy upload rejected                       | Check that the GIF is original content and meets Giphy community guidelines |
