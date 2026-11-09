# How To: Update Tags and Reassign an Existing Giphy GIF

Use this guide when your GIF is already uploaded to Giphy and you need to edit its tags, change its channel assignment, or update its source URL.

---

## Edit Tags on an Existing GIF

### From a Browser (Desktop or Phone Desktop Site)

1. Go to [giphy.com](https://giphy.com) and sign in.
2. Click your avatar → **My GIFs** (or go directly to `https://giphy.com/channel/YOUR_USERNAME`).
3. Find the GIF you want to edit and click the **pencil (✏️) icon** that appears on hover.
4. In the edit panel, update:
   - **Tags** — add, remove, or rename tags. Separate with commas.
   - **Source URL** — update to a new profile or post link.
5. Click **Save**.

> **Note:** Tag changes can take up to **24 hours** to reflect in Instagram's GIF sticker search.

---

## Reassign a GIF to a Different Giphy Channel

Giphy does not offer a direct "move to another channel" button for GIFs uploaded under a personal account. Use one of the following approaches:

### Option A: Re-upload Under the Target Channel

1. Download the original GIF (open it on Giphy → right-click / long-press → **Save as**).
2. Sign in to the target Giphy channel account.
3. Upload the GIF again under the new channel with the updated tags.
4. Delete the old version from your original account (GIF page → **Delete** button).

### Option B: Use the Giphy API to Update Metadata

If you have a **Giphy API key** and the GIF was uploaded via the API, you can update its metadata programmatically.

Get your API key at: [developers.giphy.com](https://developers.giphy.com)

#### Update via PowerShell (Windows)

> **Security:** API keys appear in request URIs per the Giphy API spec. Do not log or share these URIs.

```powershell
$apiKey = "YOUR_GIPHY_API_KEY"
$gifId  = "EXISTING_GIF_ID"

# The Giphy REST API does not expose a public PATCH endpoint for tag editing on free keys.
# Use the Upload API to re-upload with updated tags, then delete the old GIF.
$newTags = "юрий клинский,yuriy klinsky,motivation"
$gifPath = "C:\path\to\your.gif"

$form = @{
    file   = Get-Item $gifPath
    api_key = $apiKey
    tags   = $newTags
    source = "https://www.instagram.com/yourhandle"
}
$response = Invoke-RestMethod -Uri "https://upload.giphy.com/v1/gifs" -Method Post -Form $form
Write-Host "New GIF ID: $($response.data.id)"
Write-Host "URL: https://giphy.com/gifs/$($response.data.id)"
```

After re-uploading with the correct tags, delete the old GIF via:

```powershell
Invoke-RestMethod -Uri "https://api.giphy.com/v1/gifs/$gifId`?api_key=$apiKey" -Method Delete
```

> **Note:** The delete endpoint requires that the GIF was uploaded with the same API key.

---

## Bulk Tag Update via PowerShell

Use this script when you have multiple existing GIFs and want to ensure all of them include a consistent set of tags. Because the Giphy REST API does not expose a direct tag-edit endpoint, the script re-uploads each GIF with updated tags and optionally deletes the originals.

```powershell
# bulk-retag.ps1
# Re-uploads GIFs from a local folder with new tags and optionally removes originals.

param(
    [Parameter(Mandatory)][string]$ApiKey,
    [Parameter(Mandatory)][string]$GifFolder,
    [Parameter(Mandatory)][string]$Tags,
    [string]$SourceUrl = "",
    [switch]$DeleteOld,
    [string[]]$OldGifIds = @(),
    [switch]$WhatIf
)

$gifs = Get-ChildItem -Path $GifFolder -Filter "*.gif"
if ($gifs.Count -eq 0) {
    Write-Warning "No .gif files found in: $GifFolder"
    exit 1
}

foreach ($gif in $gifs) {
    if ($WhatIf) {
        Write-Host "[WhatIf] Would upload: $($gif.Name) with tags: $Tags" -ForegroundColor Cyan
        continue
    }
    Write-Host "Uploading: $($gif.Name)" -ForegroundColor Cyan
    $form = @{
        file    = Get-Item $gif.FullName
        api_key = $ApiKey
        tags    = $Tags
        source  = $SourceUrl
    }
    try {
        $resp = Invoke-RestMethod -Uri "https://upload.giphy.com/v1/gifs" -Method Post -Form $form
        Write-Host "  New ID : $($resp.data.id)" -ForegroundColor Green
        Write-Host "  URL    : https://giphy.com/gifs/$($resp.data.id)" -ForegroundColor Green
    } catch {
        Write-Warning "  Failed to upload $($gif.Name): $_"
    }
}

if ($DeleteOld -and $OldGifIds.Count -gt 0) {
    foreach ($oldId in $OldGifIds) {
        if ($WhatIf) {
            Write-Host "[WhatIf] Would delete GIF: $oldId" -ForegroundColor Yellow
            continue
        }
        Write-Host "Deleting old GIF: $oldId" -ForegroundColor Yellow
        try {
            Invoke-RestMethod -Uri "https://api.giphy.com/v1/gifs/$oldId`?api_key=$ApiKey" -Method Delete
            Write-Host "  Deleted." -ForegroundColor Green
        } catch {
            Write-Warning "  Could not delete $oldId`: $_"
        }
    }
}
```

**Usage:**
```powershell
# Dry run — preview what would be uploaded and deleted (no changes made)
.\bulk-retag.ps1 `
    -ApiKey "YOUR_GIPHY_API_KEY" `
    -GifFolder "C:\MyGIFs" `
    -Tags "юрий клинский,yuriy klinsky,fitness" `
    -SourceUrl "https://www.instagram.com/yourhandle" `
    -DeleteOld `
    -OldGifIds @("abc123", "def456") `
    -WhatIf

# Apply changes for real (omit -WhatIf)
.\bulk-retag.ps1 `
    -ApiKey "YOUR_GIPHY_API_KEY" `
    -GifFolder "C:\MyGIFs" `
    -Tags "юрий клинский,yuriy klinsky,fitness" `
    -SourceUrl "https://www.instagram.com/yourhandle" `
    -DeleteOld `
    -OldGifIds @("abc123", "def456")
```

---

## Verify Changes Are Live

After editing or re-uploading, run `validate-gif.ps1` (in this folder) to confirm your tag is searchable:

```powershell
.\validate-gif.ps1 -ApiKey "YOUR_KEY" -Tag "юрий клинский"
```

See [`validate-gif.ps1`](validate-gif.ps1) for full usage.
