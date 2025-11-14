# create-symlinks.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$SourceDirectory,
    
    [Parameter(Mandatory=$true)]
    [string]$TargetDirectory,
    
    [string[]]$FileExtensions = @("*.pdf", "*.txt", "*.md", "*.doc", "*.docx", "*.py", "*.js", "*.java", "*.cpp", "*.cs", "*.html", "*.css"),
    
    [switch]$Recursive
)

# Create target directory if it doesn't exist
if (!(Test-Path $TargetDirectory)) {
    New-Item -ItemType Directory -Path $TargetDirectory -Force
    Write-Host "Created target directory: $TargetDirectory" -ForegroundColor Green
}

# Function to create symbolic links
function Create-SymbolicLinks {
    param($SourcePath, $TargetPath, $Patterns)
    
    $linkCount = 0
    
    foreach ($pattern in $Patterns) {
        Write-Host "Processing pattern: $pattern" -ForegroundColor Yellow
        
        if ($Recursive) {
            $files = Get-ChildItem -Path $SourcePath -Filter $pattern -Recurse -File
        } else {
            $files = Get-ChildItem -Path $SourcePath -Filter $pattern -File
        }
        
        foreach ($file in $files) {
            $relativePath = if ($Recursive) {
                # Maintain directory structure
                $relative = $file.FullName.Replace($SourcePath, "").TrimStart('\', '/')
                if ($relative -eq $file.Name) {
                    # File is in root source directory
                    $file.Name
                } else {
                    $relative
                }
            } else {
                $file.Name
            }
            
            $linkPath = Join-Path $TargetPath $relativePath
            
            # Create directory structure if needed
            $linkDir = Split-Path $linkPath -Parent
            if (!(Test-Path $linkDir)) {
                New-Item -ItemType Directory -Path $linkDir -Force
            }
            
            # Create symbolic link if it doesn't exist
            if (!(Test-Path $linkPath)) {
                try {
                    New-Item -ItemType SymbolicLink -Path $linkPath -Target $file.FullName -Force
                    Write-Host "Created link: $relativePath" -ForegroundColor Green
                    $linkCount++
                }
                catch {
                    Write-Host "Failed to create link for: $($file.FullName) - $($_.Exception.Message)" -ForegroundColor Red
                }
            } else {
                Write-Host "Link already exists: $relativePath" -ForegroundColor Gray
            }
        }
    }
    
    return $linkCount
}

# Check if source directory exists
if (!(Test-Path $SourceDirectory)) {
    Write-Host "Source directory does not exist: $SourceDirectory" -ForegroundColor Red
    exit 1
}

Write-Host "Creating symbolic links from $SourceDirectory to $TargetDirectory" -ForegroundColor Cyan
Write-Host "File extensions: $($FileExtensions -join ', ')" -ForegroundColor Cyan
Write-Host "Recursive: $Recursive" -ForegroundColor Cyan
Write-Host "-" * 50

$totalLinks = Create-SymbolicLinks -SourcePath $SourceDirectory -TargetPath $TargetDirectory -Patterns $FileExtensions

Write-Host "-" * 50
Write-Host "Successfully created $totalLinks symbolic links" -ForegroundColor Green