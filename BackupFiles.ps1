[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Source,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$Destination,

    [string]$LogPath = "~\.robocopy\log.txt",

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ExcludePatterns
)

$ErrorActionPreference = "Stop"

function Expand-Path {
    param(
        [string]$Path
    )
    
    if ($Path -match '~') {
        $Path = $Path -replace '~', $env:USERPROFILE
    }
    
    return $Path
}

$logPathExpanded = Expand-Path $LogPath
$logDirectory = Split-Path $logPathExpanded

if (-not (Test-Path $logDirectory)) {
    New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
}

# Build the robocopy arguments
$robocopyArgs = @(
    "`"$Source`"",
    "`"$Destination`""
)

# Check if we're in WhatIf mode
$whatIf = -not $PSCmdlet.ShouldProcess($Destination, "Robocopy from $Source")

if ($whatIf) {
    Write-Host "[WHAT-IF] Running robocopy in log-only mode (/L flag)" -ForegroundColor Yellow
    # In WhatIf mode, use minimal parameters that work with /L
    $robocopyArgs += @(
        "/L",
        "/E",
        "/R:1",
        "/W:5",
        "/V",
        "/TEE",
        "/SL",
        "/SJ"
    )
} else {
    Write-Host "Starting robocopy operation..." -ForegroundColor Green
    # Normal mode - all parameters
    $robocopyArgs += @(
        "/COPY:DATS",
        "/DCOPY:DATE",
        "/ZB",
        "/E",
        "/R:1",
        "/W:5",
        "/MT:8",
        "/SL",
        "/SJ",
        "/J",
        "/COMPRESS",
        "/M",
        "/V",
        "/NDL",
        "/TEE"
    )
}

# Add exclude patterns if any (work in both modes)
if ($ExcludePatterns.Count -gt 0) {
    foreach ($pattern in $ExcludePatterns) {
        $robocopyArgs += "/XF"
        $robocopyArgs += "`"$pattern`""
    }
}

# Add log file (works in both modes)
$robocopyArgs += "/UNILOG:`"$logPathExpanded`""

# Display the command
$commandString = "robocopy $($robocopyArgs -join ' ')"
if ($whatIf) {
    Write-Host "[WHAT-IF] Would execute: $commandString" -ForegroundColor Yellow
    # Still execute with /L to see what would be copied
    & "robocopy" $robocopyArgs
} else {
    Write-Host "Executing: $commandString" -ForegroundColor Green
    & "robocopy" $robocopyArgs
}

$exitCode = $LASTEXITCODE

# Robocopy exit codes: 0-7 are success (files copied), 8+ are errors
if ($exitCode -ge 8) {
    Write-Host "Robocopy failed with exit code: $exitCode" -ForegroundColor Red
} else {
    Write-Host "Robocopy completed with exit code: $exitCode" -ForegroundColor Green
}

exit $exitCode