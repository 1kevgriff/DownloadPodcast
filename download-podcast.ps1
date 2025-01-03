param (
    [Parameter(Mandatory=$true)]
    [string]$rssFeedUrl,
    [int]$maxRetries = 3
)

function Test-Url {
    param (
        [string]$url
    )
    if ($url -match '^https?://') {
        return $true
    } else {
        return $false
    }
}

function Get-PodcastEpisodes {
    param (
        [Parameter(Mandatory=$true)]
        [string]$rssFeedUrl,
        [int]$maxRetries
    )

    if (-not (Test-Url -url $rssFeedUrl)) {
        Write-Host "Invalid URL: $rssFeedUrl"
        return
    }

    Write-Host "Loading RSS feed from $rssFeedUrl"
    # Load RSS feed
    [xml]$rssFeed = (Invoke-WebRequest -Uri $rssFeedUrl).Content

    # Get podcast title and remove invalid characters for Windows
    $podcastTitle = $rssFeed.rss.channel.title -replace '[\\/:*?"<>|]', ''
    Write-Host "Podcast title: $podcastTitle"

    # Create directory for podcast
    if (-not (Test-Path -Path $podcastTitle)) {
        Write-Host "Creating directory for podcast: $podcastTitle"
        New-Item -ItemType Directory -Path $podcastTitle
    } else {
        Write-Host "Directory already exists: $podcastTitle"
    }

    # Download episodes
    $rssFeed.rss.channel.item | ForEach-Object {
        # Remove invalid characters from episode title
        $episodeTitle = $_.title -replace '[\\/:*?"<>|]', ''
        $episodeUrl = $_.enclosure.url
        $outputFile = "$podcastTitle\$episodeTitle.mp3"

        if (-not (Test-Path -Path $outputFile)) {
            Write-Host "Downloading episode: $episodeTitle"
            $retryCount = 0
            $success = $false

            while (-not $success -and $retryCount -lt $maxRetries) {
                try {
                    Invoke-WebRequest -Uri $episodeUrl -OutFile $outputFile
                    Write-Host "Downloaded: $outputFile"
                    $success = $true
                } catch {
                    $retryCount++
                    Write-Host "Failed to download $episodeTitle. Attempt $retryCount of $maxRetries."
                    if ($retryCount -eq $maxRetries) {
                        Write-Host "Failed to download $episodeTitle after $maxRetries attempts."
                    }
                }
            }
        } else {
            Write-Host "Episode already downloaded: $outputFile"
        }
    }
}

Write-Host "Starting podcast download process..."
Get-PodcastEpisodes -rssFeedUrl $rssFeedUrl -maxRetries $maxRetries
Write-Host "Podcast download process completed."
