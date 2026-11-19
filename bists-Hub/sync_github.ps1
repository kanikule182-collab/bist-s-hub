param(
    [string]$FilePath,
    [string]$CommitMessage = "Update via Antigravity"
)

$token = "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"
$owner = "kanikule182-collab"
$repo  = "bist-s-hub"
$baseDir = "D:\bists-Hub"

function Sync-FileToGitHub([string]$relPath, [string]$msg, [bool]$atRoot = $false) {
    $fullPath = Join-Path $baseDir $relPath
    if (-not (Test-Path $fullPath)) {
        Write-Host "File not found: $fullPath"
        return
    }

    $ghPath = if ($atRoot) { ($relPath -replace '\\', '/') } else { "bists-Hub/" + ($relPath -replace '\\', '/') }
    $apiUrl = "https://api.github.com/repos/$owner/$repo/contents/$ghPath"

    $headers = @{
        "Authorization" = "token $token"
        "User-Agent"    = "Antigravity-Sync"
        "Accept"        = "application/vnd.github.v3+json"
    }

    $sha = $null
    try {
        $existing = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get -ErrorAction Stop
        $sha = $existing.sha
    } catch {
        # File doesn't exist yet on GitHub
    }

    $bytes = [System.IO.File]::ReadAllBytes($fullPath)
    $b64 = [Convert]::ToBase64String($bytes)

    $bodyObj = @{
        message = $msg
        content = $b64
    }
    if ($sha) {
        $bodyObj["sha"] = $sha
    }

    $jsonBody = $bodyObj | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Put -Body $jsonBody -ContentType "application/json" -ErrorAction Stop
        Write-Host "Synced $ghPath successfully (commit: $($response.commit.sha.Substring(0,7)))"
    } catch {
        Write-Host "Failed to sync $ghPath : $($_.Exception.Message)"
    }
}

if ($FilePath) {
    Sync-FileToGitHub $FilePath $CommitMessage
} else {
    # Sync all core files
    $files = @(
        "Loader.luau",
        "Games\Doors\Main.luau",
        "Games\Doors\Loader.luau",
        "Games\Doors\Lobby.luau",
        "Games\PetSimulator99\Main.luau",
        "Games\PetSimulator99\Loader.luau",
        "Games\Universal\Loader.luau",
        "Games\Universal\Main.luau",
        "Components\InfoTab.luau",
        "Components\SettingsTab.luau",
        "Components\Environment.luau",
        "Components\Interface.luau",
        "Components\ESP.luau",
        "Components\STX.luau",
        "Components\Analytics.luau",
        "Components\AdonisBypass.luau",
        "Presets\Immortal_God.json",
        "Presets\Legit_Helper.json",
        "Presets\Speedrun_Pro.json",
        "Scripts\DeathFarm.luau"
    )
    foreach ($f in $files) {
        Sync-FileToGitHub $f "Sync $f to latest version"
    }
    Sync-FileToGitHub "README.md" "Update root README" $true
    Sync-FileToGitHub "README.md" "Update subfolder README" $false
}
