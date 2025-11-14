param(
    [string]$folderPath
)

# Check if the folder path is provided
if (-not $folderPath) {
    Write-Host "Please provide a folder path as an input."
    exit
}

# Get all .cs files in the specified folder and its subfolders
$csFiles = Get-ChildItem -Path $folderPath -Filter *.cs -File -Recurse

# Initialize total lines count
$totalLines = 0

# Create an array to store file information
$fileInfoArray = @()

# Iterate through each .cs file
foreach ($file in $csFiles) {
    # Get lines count for the current file
    $linesCount = Get-Content $file.FullName | Measure-Object -Line | Select-Object -ExpandProperty Lines

    # Update total lines count
    $totalLines += $linesCount

    # Add file information to the array
    $fileInfoArray += [PSCustomObject]@{
        FileName    = $file.Name
        LinesCount  = $linesCount
    }
}

# Display filename and lines count using Format-Table
$fileInfoArray | Format-Table -Property @{Label="File Name"; Expression={$_.FileName.PadRight(30)}}, @{Label="Lines Count"; Expression={$_.LinesCount}}

# Display total lines count
"`nTotal Lines Count: $totalLines"
