param (
    [Parameter(Mandatory=$true)]
    [string]$SourceFolderPath,

    [Parameter(Mandatory=$true)]
    [string]$TargetFolderPath
)

# Ensure the source folder exists
if (-not (Test-Path -Path $SourceFolderPath -PathType Container)) {
    Write-Error "The source folder path '$SourceFolderPath' does not exist or is not a directory."
    exit
}

# Create the target folder if it doesn't exist
if (-not (Test-Path -Path $TargetFolderPath -PathType Container)) {
    New-Item -Path $TargetFolderPath -ItemType Directory
}

# Function to copy non-link items (files and directories)
function Copy-NonLinkItems {
    param (
        [string]$Source,
        [string]$Destination
    )

    # Get all items in the current folder
    $items = Get-ChildItem -Path $Source -Force

    foreach ($item in $items) {
        $attributes = Get-Item $item.FullName -Force | Select-Object -ExpandProperty Attributes
        $itemDestination = Join-Path -Path $Destination -ChildPath $item.Name

        if (-not ($attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
            if (Test-Path $item.FullName -PathType Container) {
                # Create the destination folder
                if (-not (Test-Path $itemDestination)) {
                    New-Item -Path $itemDestination -ItemType Directory
                }

                # Recursively copy the folder content
                Copy-NonLinkItems -Source $item.FullName -Destination $itemDestination
            } else {
                # Copy files
                Copy-Item -Path $item.FullName -Destination $itemDestination
            }
        }
    }
}

# Call the function to copy the non-link content from source to target
Copy-NonLinkItems -Source $SourceFolderPath -Destination $TargetFolderPath

Write-Output "Non-link content copied from '$SourceFolderPath' to '$TargetFolderPath' successfully."
