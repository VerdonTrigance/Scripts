param(
    [Parameter(Mandatory = $true, Position = 0)]
    string $Source,

    [Parameter(Mandatory = $true, Position = 1)]
    string $Destination,

    [string]$LogPath = "~\.robocopy\log.txt",

    [Parameter(ValueFromRemainingArguments = $true)]
    string[] $ExcludePatterns
)

$ErrorActionPreference = "Continue"

function Expand-Path {
    param(
        [string]$Path
    )
    
    if ($Path -match '~') {
        $Path = $Path -replace '~', $env:USERPROFILE
    }
    
    return $Path
}

$sourcePath = Resolve-Path $Source
$destPath = if (Test-Path $Destination -PathType Container) { $Destination } else { New-Item -ItemType Directory -Path $Destination -Force }

$logPathExpanded = Expand-Path $LogPath
$logDirectory = Split-Path $logPathExpanded

if (-not (Test-Path $logDirectory)) {
    New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
}

$robocopyCmd = "robocopy `"$sourcePath`" `"$destPath`" /E /R:2 /W:15 /MT /V /TEE"

if ($ExcludePatterns.Count -gt 0) {
    foreach ($pattern in $ExcludePatterns) {
        $robocopyCmd += "/XF `"$pattern`" "
    }
}

$robocopyCmd += "/LOG+:`"$logPathExpanded`"" | Out-Null

Invoke-Expression $robocopyCmd

exit $LASTEXITCODE