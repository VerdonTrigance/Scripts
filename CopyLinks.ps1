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

# Function to resolve the correct absolute path for a relative link target
function Resolve-RelativePathForLink {
    param (
        [string]$RelativeTargetPath,
        [string]$ItemDestination
    )

    $destinationFolder = Split-Path -Path $ItemDestination
    $newTargetAbsolutePath = Join-Path -Path $destinationFolder -ChildPath $RelativeTargetPath

    return $newTargetAbsolutePath
}

# Function to copy symbolic links
function Copy-LinkItems {
    param (
        [string]$Source,
        [string]$Destination
    )

    # Get all items in the current folder
    $items = Get-ChildItem -Path $Source -Force

    foreach ($item in $items) {
        $attributes = Get-Item $item.FullName -Force | Select-Object -ExpandProperty Attributes
        $itemDestination = Join-Path -Path $Destination -ChildPath $item.Name
        Write-Verbose "Item destination: $itemDestination"

        if ($attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            # Handle symbolic link
            try {
                $linkTarget = (Get-Item $item.FullName -Force).Target
                Write-Verbose "Link target: $linkTarget"
                # Ensure the linkTarget is not null or empty
                if (-not [string]::IsNullOrEmpty($linkTarget)) {
                    # Resolve relative path if necessary
                    if ([System.IO.Path]::IsPathRooted($linkTarget)) {
                        $resolvedTarget = $linkTarget
                    } else {
                        # Resolve the link target relative to the file's location and the new root
                        $resolvedTarget = Resolve-RelativePathForLink -RelativeTargetPath $linkTarget -ItemDestination $itemDestination
                    }

                    New-Item -ItemType SymbolicLink -Path $itemDestination -Target $resolvedTarget -Force
                    Write-Output "Symbolic link '$item.FullName' copied to '$itemDestination'."
                } else {
                    Write-Warning "Could not retrieve the target for symbolic link: $($item.FullName)"
                }
            } catch {
                Write-Error "Failed to copy symbolic link: $($item.FullName). Error: $_"
            }
        } elseif (Test-Path $item.FullName -PathType Container) {
            # Create the destination folder
            if (-not (Test-Path $itemDestination)) {
                New-Item -Path $itemDestination -ItemType Directory
            }

            # Recursively copy the folder content
            Copy-LinkItems -Source $item.FullName -Destination $itemDestination
        }
    }
}

# Call the function to copy the link content from source to target
Copy-LinkItems -Source $SourceFolderPath -Destination $TargetFolderPath

Write-Output "Link content copied from '$SourceFolderPath' to '$TargetFolderPath' successfully."
