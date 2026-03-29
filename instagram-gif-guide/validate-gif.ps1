# =============================================================================
# validate-gif.ps1 — Giphy GIF & Tag Validator
# =============================================================================
# Searches the Giphy API to verify that a tag or a specific GIF ID is
# publicly accessible and would appear in Instagram's GIF sticker search.
#
# Usage:
#   .\validate-gif.ps1 -ApiKey "YOUR_KEY" -Tag "yuriy klinsky"
#   .\validate-gif.ps1 -ApiKey "YOUR_KEY" -GifId "abc123xyz"
#   .\validate-gif.ps1 -ApiKey "YOUR_KEY" -Tag "yuriy klinsky" -GifId "abc123xyz"
#
# Non-ASCII tags (e.g. Cyrillic) are supported, but ensure your PowerShell
# console uses UTF-8 encoding first:
#   [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
#   $OutputEncoding            = [System.Text.Encoding]::UTF8
#
# Get a free Giphy API key at: https://developers.giphy.com
#
# Security: API keys are passed as query-string parameters per the Giphy API
# spec. Do NOT log or share the full request URIs, as they contain your key.
# =============================================================================
#Requires -Version 5.1

param(
    [Parameter(Mandatory)]
    [string]$ApiKey,

    [string]$Tag,

    [string]$GifId,

    [int]$Limit = 10,

    [switch]$Silent
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Write-Status {
    param([string]$Message, [string]$Color = "White")
    if (-not $Silent) { Write-Host $Message -ForegroundColor $Color }
}

function Invoke-GiphySearch {
    param(
        [string]$ApiKey,
        [string]$Query,
        [int]$Limit
    )
    $encoded = [Uri]::EscapeDataString($Query)
    # NOTE: The URI contains your API key — do not log or share it.
    $uri     = "https://api.giphy.com/v1/gifs/search?api_key=$ApiKey&q=$encoded&limit=$Limit&rating=g"
    try {
        $resp = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
        return $resp
    } catch {
        throw "Giphy search request failed: $_"
    }
}

function Invoke-GiphyGetById {
    param(
        [string]$ApiKey,
        [string]$GifId
    )
    $uri = "https://api.giphy.com/v1/gifs/$GifId`?api_key=$ApiKey"
    try {
        $resp = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
        return $resp
    } catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            return $null
        }
        throw "Giphy lookup request failed: $_"
    }
}

# ---------------------------------------------------------------------------
# Validation logic
# ---------------------------------------------------------------------------

function Invoke-GifValidation {
    param(
        [string]$ApiKey,
        [string]$Tag,
        [string]$GifId,
        [int]$Limit
    )

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    $overallPass = $true

    # --- Validate by Tag ---
    if ($Tag) {
        Write-Status "`n=== Tag Search: '$Tag' ===" -Color Cyan
        try {
            $search = Invoke-GiphySearch -ApiKey $ApiKey -Query $Tag -Limit $Limit
            $count  = $search.data.Count
            $total  = $search.pagination.total_count

            if ($count -gt 0) {
                Write-Status "  [PASS] Found $count result(s) (total in Giphy: $total)" -Color Green
                foreach ($gif in $search.data) {
                    Write-Status ("  - [{0}]  {1}" -f $gif.id, $gif.title) -Color Gray
                    Write-Status ("    URL  : {0}" -f $gif.url) -Color DarkGray

                    # Check if GifId is among the search results
                    if ($GifId -and $gif.id -eq $GifId) {
                        Write-Status "    *** This is your target GIF — found in search results ***" -Color Yellow
                    }
                }
                $results.Add([PSCustomObject]@{
                    Check   = "Tag search"
                    Tag     = $Tag
                    Status  = "PASS"
                    Count   = $count
                    Total   = $total
                })
            } else {
                Write-Status "  [FAIL] No GIFs found for tag '$Tag'." -Color Red
                Write-Status "  - Ensure your Giphy channel is verified." -Color Yellow
                Write-Status "  - Tags may take up to 24h to index after upload." -Color Yellow
                $overallPass = $false
                $results.Add([PSCustomObject]@{
                    Check   = "Tag search"
                    Tag     = $Tag
                    Status  = "FAIL"
                    Count   = 0
                    Total   = 0
                })
            }
        } catch {
            Write-Status "  [ERROR] $_" -Color Red
            $overallPass = $false
            $results.Add([PSCustomObject]@{
                Check   = "Tag search"
                Tag     = $Tag
                Status  = "ERROR"
                Count   = 0
                Total   = 0
            })
        }
    }

    # --- Validate by GIF ID ---
    if ($GifId) {
        Write-Status "`n=== GIF ID Lookup: '$GifId' ===" -Color Cyan
        try {
            $lookup = Invoke-GiphyGetById -ApiKey $ApiKey -GifId $GifId
            if ($null -ne $lookup -and $null -ne $lookup.data -and $lookup.data.id) {
                $gif = $lookup.data
                Write-Status "  [PASS] GIF exists and is accessible." -Color Green
                Write-Status ("  Title    : {0}" -f $gif.title) -Color Gray
                Write-Status ("  Tags     : {0}" -f ($gif.tags -join ", ")) -Color Gray
                Write-Status ("  URL      : {0}" -f $gif.url) -Color DarkGray
                Write-Status ("  Embed URL: {0}" -f $gif.embed_url) -Color DarkGray
                Write-Status ("  Rating   : {0}" -f $gif.rating) -Color Gray
                Write-Status ("  Created  : {0}" -f $gif.import_datetime) -Color Gray

                $isPublic = ($gif.is_hidden -eq $false -or $null -eq $gif.is_hidden)
                if ($isPublic) {
                    Write-Status "  Visibility: Public (searchable in Instagram)" -Color Green
                } else {
                    Write-Status "  Visibility: Hidden — not searchable until your channel is verified." -Color Yellow
                    $overallPass = $false
                }

                $results.Add([PSCustomObject]@{
                    Check     = "GIF ID lookup"
                    GifId     = $GifId
                    Title     = $gif.title
                    Status    = if ($isPublic) { "PASS" } else { "WARN" }
                    IsPublic  = $isPublic
                    Tags      = ($gif.tags -join ", ")
                    Url       = $gif.url
                })
            } else {
                Write-Status "  [FAIL] GIF ID '$GifId' not found or is private." -Color Red
                $overallPass = $false
                $results.Add([PSCustomObject]@{
                    Check   = "GIF ID lookup"
                    GifId   = $GifId
                    Status  = "FAIL"
                })
            }
        } catch {
            Write-Status "  [ERROR] $_" -Color Red
            $overallPass = $false
            $results.Add([PSCustomObject]@{
                Check   = "GIF ID lookup"
                GifId   = $GifId
                Status  = "ERROR"
            })
        }
    }

    # --- Summary ---
    Write-Status "`n=== Validation Summary ===" -Color Cyan
    $results | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Status $_ }

    if ($overallPass) {
        Write-Status "Result: ALL CHECKS PASSED — your GIF/tag is live on Giphy." -Color Green
    } else {
        Write-Status "Result: ONE OR MORE CHECKS FAILED — see details above." -Color Red
    }

    return [PSCustomObject]@{
        Pass    = $overallPass
        Checks  = $results
    }
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if (-not $Tag -and -not $GifId) {
    Write-Host "Usage: .\validate-gif.ps1 -ApiKey KEY [-Tag TAG] [-GifId ID] [-Limit N] [-Silent]" -ForegroundColor Yellow
    Write-Host "  At least one of -Tag or -GifId is required." -ForegroundColor Yellow
    exit 2
}

$validation = Invoke-GifValidation -ApiKey $ApiKey -Tag $Tag -GifId $GifId -Limit $Limit
exit $(if ($validation.Pass) { 0 } else { 1 })
