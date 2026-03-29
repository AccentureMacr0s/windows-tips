# How To: Add a GIF to Instagram Using AI (Giphy)

This guide walks you through creating a custom GIF with AI tools and uploading it to Instagram via Giphy. It also covers Ruby-based automation and iOS-specific workflows for integrating GIFs into iPhone apps.

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

## Ruby Automation for GIF Creation and iOS Optimization

Ruby is well-suited for scripting GIF pipelines and integrating with iOS toolchains (Fastlane, CocoaPods). The scripts below use the `mini_magick` gem (wraps ImageMagick/FFmpeg) and standard Ruby to automate conversion, optimization, and uploading.

### Prerequisites

```bash
# Install required gems
gem install mini_magick
gem install giphy      # unofficial Giphy API client
```

> **Note:** `mini_magick` requires [ImageMagick](https://imagemagick.org/) and [FFmpeg](https://ffmpeg.org/) to be installed on your system.

---

### Convert MP4 to iOS-Compatible GIF (Ruby + FFmpeg)

iOS devices display GIFs best at ≤ 15 fps, ≤ 480 px wide, and under 15 MB. The script below wraps the FFmpeg call with Ruby to enforce these constraints automatically.

```ruby
# gif_converter.rb — Convert an MP4 to an iOS-compatible GIF
require 'open3'
require 'fileutils'

MAX_SIZE_MB   = 15
TARGET_FPS    = 12   # conservative for smooth iOS playback
TARGET_WIDTH  = 480  # minimum recommended by Giphy; safe for all iPhones

def convert_to_gif(input_path, output_path, fps: TARGET_FPS, width: TARGET_WIDTH)
  # iOS-specific FFmpeg flags:
  #   -vf fps=N           — lock frame rate to N (12–15 recommended for iOS)
  #   scale=W:-1          — scale to W px wide, preserve aspect ratio
  #   flags=lanczos       — high-quality downscaling filter
  #   -loop 0             — loop forever (required for GIF sticker behaviour)
  cmd = [
    'ffmpeg', '-y', '-i', input_path,
    '-vf', "fps=#{fps},scale=#{width}:-1:flags=lanczos",
    '-loop', '0',
    output_path
  ]

  stdout, stderr, status = Open3.capture3(*cmd)
  raise "FFmpeg error:\n#{stderr}" unless status.success?

  size_mb = File.size(output_path) / (1024.0 * 1024.0)
  puts "Output: #{output_path} (#{size_mb.round(2)} MB)"

  if size_mb > MAX_SIZE_MB
    warn "WARNING: File is #{size_mb.round(2)} MB — exceeds #{MAX_SIZE_MB} MB limit."
    warn "Try reducing fps or width. Example: convert_to_gif(..., fps: 10, width: 360)"
  end

  output_path
end

# Usage
convert_to_gif('input.mp4', 'output.gif')
```

**Run:**
```bash
ruby gif_converter.rb
```

---

### iOS-Specific FFmpeg One-Liner

For quick conversion optimised for iPhone screens (use in Terminal or CI scripts):

```bash
# iOS-safe GIF: 12 fps, 480 px wide, high-quality Lanczos scale, loops forever
ffmpeg -i input.mp4 \
  -vf "fps=12,scale=480:-1:flags=lanczos" \
  -loop 0 \
  output_ios.gif
```

Key differences from the general command:
- `fps=12` — lower than the 15–24 desktop recommendation; avoids frame-drop jitter on older iPhones
- `scale=480:-1` — matches Giphy's minimum and the native sticker picker resolution
- No `-b:v` flag — GIF encoding is palette-based, not bitrate-based

---

### Optimize an Existing GIF for iOS (Ruby + ImageMagick)

```ruby
# gif_optimizer.rb — Reduce GIF file size while keeping iOS compatibility
require 'mini_magick'

MAX_FRAMES    = 60   # cap total frames (5 s × 12 fps)
TARGET_COLORS = 128  # reduce colour palette to shrink file size

def optimize_gif(input_path, output_path)
  image = MiniMagick::Image.open(input_path)

  image.combine_options do |c|
    c.coalesce                          # flatten all layers
    c.layers 'Optimize'                 # remove redundant pixels between frames
    c.colors TARGET_COLORS.to_s        # reduce palette depth
    c.depth '8'                         # 8-bit colour
    c.loop '0'                          # loop forever
  end

  # Trim to MAX_FRAMES if GIF is too long
  frames = MiniMagick::Image.open(input_path).frames
  if frames.length > MAX_FRAMES
    puts "Trimming from #{frames.length} to #{MAX_FRAMES} frames..."
    image.combine_options { |c| c.delete "#{MAX_FRAMES}--1" }
  end

  image.write(output_path)

  size_mb = File.size(output_path) / (1024.0 * 1024.0)
  puts "Optimized: #{output_path} (#{size_mb.round(2)} MB)"
end

# Usage
optimize_gif('output.gif', 'output_optimized.gif')
```

**Run:**
```bash
ruby gif_optimizer.rb
```

---

### Upload GIF to Giphy via Ruby

```ruby
# giphy_upload.rb — Upload a GIF to Giphy with iOS-friendly tags
require 'net/http'
require 'uri'
require 'json'

GIPHY_UPLOAD_URL = 'https://upload.giphy.com/v1/gifs'

def upload_to_giphy(gif_path, api_key:, tags:, source_url: '')
  uri  = URI.parse(GIPHY_UPLOAD_URL)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  # Build multipart form data
  boundary = "GiphyRubyUpload#{Time.now.to_i}"
  body = build_multipart(gif_path, api_key, tags, source_url, boundary)

  request = Net::HTTP::Post.new(uri.path)
  request['Content-Type'] = "multipart/form-data; boundary=#{boundary}"
  request.body = body

  response = http.request(request)
  result   = JSON.parse(response.body)

  if result.dig('data', 'id')
    gif_id = result['data']['id']
    puts "Upload successful!"
    puts "GIF ID : #{gif_id}"
    puts "URL    : https://giphy.com/gifs/#{gif_id}"
    gif_id
  else
    raise "Upload failed: #{response.body}"
  end
end

def build_multipart(gif_path, api_key, tags, source_url, boundary)
  fields = {
    'api_key' => api_key,
    'tags'    => tags,
    'source'  => source_url
  }

  parts = fields.map do |name, value|
    "--#{boundary}\r\nContent-Disposition: form-data; name=\"#{name}\"\r\n\r\n#{value}\r\n"
  end

  gif_data = File.binread(gif_path)
  parts << "--#{boundary}\r\n" \
           "Content-Disposition: form-data; name=\"file\"; filename=\"#{File.basename(gif_path)}\"\r\n" \
           "Content-Type: image/gif\r\n\r\n"
  parts << gif_data
  parts << "\r\n--#{boundary}--\r\n"
  parts.join
end

# Usage — replace with your Giphy API key
upload_to_giphy(
  'output_optimized.gif',
  api_key:    ENV['GIPHY_API_KEY'],
  tags:       'юрий клинский, yuriy klinsky, motivation, ios, iphone',
  source_url: 'https://www.instagram.com/yourhandle'
)
```

**Run:**
```bash
GIPHY_API_KEY="your_key_here" ruby giphy_upload.rb
```

---

## iOS Tools Integration: Fastlane and CocoaPods

Ruby powers both [Fastlane](https://fastlane.tools/) and [CocoaPods](https://cocoapods.org/), making it a natural fit for iOS GIF workflows.

### Fastlane — Automate GIF Processing in CI/CD

Add a custom Fastlane lane to your `Fastfile` to convert and upload GIFs as part of your app's build pipeline:

```ruby
# Fastfile (add to your existing Fastfile)
require_relative '../scripts/gif_converter'   # path to gif_converter.rb above
require_relative '../scripts/giphy_upload'    # path to giphy_upload.rb above

lane :process_and_upload_gifs do
  # Convert raw assets in the project to iOS-optimised GIFs
  Dir.glob('assets/raw/*.mp4').each do |mp4|
    gif_out = mp4.sub('raw', 'gifs').sub('.mp4', '.gif')
    FileUtils.mkdir_p(File.dirname(gif_out))
    convert_to_gif(mp4, gif_out, fps: 12, width: 480)
    optimize_gif(gif_out, gif_out)   # optimize in place
    upload_to_giphy(
      gif_out,
      api_key:    ENV['GIPHY_API_KEY'],
      tags:       'yourapp, ios, iphone',
      source_url: 'https://apps.apple.com/app/yourapp/id000000000'
    )
  end
  UI.success "All GIFs processed and uploaded!"
end
```

**Run:**
```bash
bundle exec fastlane process_and_upload_gifs
```

### CocoaPods — Add GIF Support to Your iOS App

Add a GIF rendering library to your `Podfile`:

```ruby
# Podfile
platform :ios, '13.0'
use_frameworks!

target 'YourApp' do
  # Render GIFs natively in UIKit / SwiftUI
  pod 'SDWebImage',           '~> 5.0'   # UIImageView category + GIF support
  pod 'SDWebImageWebPCoder',  '~> 0.14'  # optional: WebP support alongside GIF

  # Alternative: Gifu (pure Swift, lightweight)
  # pod 'Gifu', '~> 3.4'
end
```

**Install:**
```bash
pod install
open YourApp.xcworkspace
```

---

## Integrating GIFs into iOS Applications

### Swift — Display a Giphy GIF with SDWebImage

```swift
import UIKit
import SDWebImage

class GifViewController: UIViewController {

    @IBOutlet weak var gifImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadGiphyGif()
    }

    func loadGiphyGif() {
        // Use the direct media URL from Giphy (replace GIPHY_ID with your GIF's ID)
        let gifURL = URL(string: "https://media.giphy.com/media/GIPHY_ID/giphy.gif")!

        // SDWebImage handles download, caching, and looped playback automatically
        gifImageView.sd_setImage(with: gifURL, placeholderImage: UIImage(named: "placeholder"))
    }
}
```

### Swift — Display a Local GIF with Gifu

```swift
import UIKit
import Gifu

class LocalGifViewController: UIViewController {

    @IBOutlet weak var gifView: GIFImageView!   // use GIFImageView instead of UIImageView

    override func viewDidLoad() {
        super.viewDidLoad()

        // Load a bundled GIF from the app's Assets catalog or Bundle
        if let gifURL = Bundle.main.url(forResource: "output_ios", withExtension: "gif") {
            gifView.prepareForAnimation(withGIFURL: gifURL, loopCount: 0)  // 0 = infinite
            gifView.startAnimating()
        }
    }
}
```

### Objective-C — Display a Giphy GIF with SDWebImage

```objc
#import <UIKit/UIKit.h>
#import <SDWebImage/SDWebImage.h>

@interface GifViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *gifImageView;
@end

@implementation GifViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSURL *gifURL = [NSURL URLWithString:@"https://media.giphy.com/media/GIPHY_ID/giphy.gif"];
    [self.gifImageView sd_setImageWithURL:gifURL
                         placeholderImage:[UIImage imageNamed:@"placeholder"]];
}

@end
```

### SwiftUI — Display a GIF with SDWebImageSwiftUI

```ruby
# Add to Podfile
pod 'SDWebImageSwiftUI', '~> 3.0'
```

```swift
import SwiftUI
import SDWebImageSwiftUI

struct GifView: View {
    var body: some View {
        WebImage(url: URL(string: "https://media.giphy.com/media/GIPHY_ID/giphy.gif"))
            .resizable()
            .placeholder { ProgressView() }
            .indicator(.activity)
            .transition(.fade(duration: 0.3))
            .scaledToFit()
            .frame(width: 300)
    }
}
```

### GIF Asset Best Practices for iOS

| Concern           | Recommendation                                                        |
|-------------------|-----------------------------------------------------------------------|
| Frame rate        | 10–12 fps for smooth playback on older iPhones (A12 and below)        |
| Max width         | 480 px — matches Retina display at 1× and Giphy sticker resolution    |
| File size         | ≤ 5 MB for in-app assets; ≤ 15 MB for Giphy uploads                  |
| Looping           | Always set `loopCount: 0` (infinite) for sticker-style animations     |
| Memory            | Prefer remote URLs (SDWebImage caches automatically) over bundling    |
| Accessibility     | Set `accessibilityLabel` on the image view; pause animation on Reduce Motion |

---

## Ruby's Role in the GIF-to-iOS Pipeline

Ruby ties all stages of the pipeline together:

| Stage                  | Tool / Language      | Ruby's role                                      |
|------------------------|----------------------|--------------------------------------------------|
| GIF conversion         | FFmpeg (via Ruby)    | `Open3` wraps the FFmpeg subprocess              |
| GIF optimization       | ImageMagick (via Ruby) | `mini_magick` gem provides a Ruby API           |
| Giphy upload           | Giphy REST API       | `Net::HTTP` handles multipart upload             |
| iOS CI/CD automation   | Fastlane (Ruby DSL)  | `Fastfile` lanes automate the full pipeline      |
| iOS dependency mgmt    | CocoaPods (Ruby)     | `Podfile` DSL installs GIF rendering libraries   |
| Tag validation         | PowerShell / Ruby    | Both languages can call the Giphy Search API     |

Ruby is not the only option — the same FFmpeg commands and Giphy API calls work from Python, Node.js, or PowerShell. Ruby's advantage here is the native integration with Fastlane and CocoaPods, which are already part of most iOS development workflows.

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

| Tool                 | Purpose                          | Link                                                         |
|----------------------|----------------------------------|--------------------------------------------------------------|
| Giphy                | Host & distribute GIFs           | [giphy.com](https://giphy.com)                               |
| Giphy Developers     | API keys & documentation         | [developers.giphy.com](https://developers.giphy.com)         |
| Ezgif                | Convert video → GIF              | [ezgif.com](https://ezgif.com)                               |
| Runway ML            | AI video generation              | [runwayml.com](https://runwayml.com)                         |
| Pika Labs            | AI video generation              | [pika.art](https://pika.art)                                 |
| FFmpeg               | CLI video/GIF conversion         | [ffmpeg.org](https://ffmpeg.org)                             |
| Midjourney           | AI image generation              | [midjourney.com](https://midjourney.com)                     |
| mini_magick          | Ruby ImageMagick wrapper         | [github.com/minimagick/minimagick](https://github.com/minimagick/minimagick) |
| Fastlane             | iOS CI/CD automation (Ruby DSL)  | [fastlane.tools](https://fastlane.tools)                     |
| CocoaPods            | iOS dependency manager (Ruby)    | [cocoapods.org](https://cocoapods.org)                       |
| SDWebImage           | iOS GIF rendering (UIKit/SwiftUI)| [github.com/SDWebImage/SDWebImage](https://github.com/SDWebImage/SDWebImage) |
| Gifu                 | iOS GIF rendering (pure Swift)   | [github.com/kaishin/Gifu](https://github.com/kaishin/Gifu)   |

---

## Troubleshooting

| Problem                                     | Solution                                                                 |
|---------------------------------------------|--------------------------------------------------------------------------|
| GIF not showing in Instagram search         | Ensure your Giphy channel is verified; newly uploaded GIFs may take 24h  |
| GIF too large to upload                     | Reduce resolution to 480 px wide or lower frame rate to 10–12 fps        |
| Tags not returning results in Instagram     | Use simpler, shorter tags; avoid special characters                       |
| Giphy upload rejected                       | Check that the GIF is original content and meets Giphy community guidelines |
| GIF stutters on older iPhones              | Lower fps to 10 in `gif_converter.rb` and re-export                      |
| `mini_magick` gem not found                 | Run `gem install mini_magick` and ensure ImageMagick is installed         |
| Fastlane lane not found                     | Run `bundle exec fastlane lanes` to list available lanes                  |
| CocoaPods install fails                     | Run `sudo gem install cocoapods` then `pod repo update`                   |
| SDWebImage GIF not animating in SwiftUI     | Use `SDWebImageSwiftUI` pod and `WebImage` component, not `AsyncImage`    |
