[CmdletBinding()]
param(
    [string]$FileExtension = ".jpg",  # File extension to filter (default is ".jpg")
	[string]$Folder = ".",  # Folder
	[int]$Start = 0  # Folder
)

# Get all files with the specified extension in the current folder
$fileList = Get-ChildItem -Filter "*$FileExtension" -Path $Folder

# Check if any files are found
if ($fileList.Count -eq 0) {
    Write-Output "No files with the extension '$FileExtension' found in the current folder."
    exit
}

# Display a message indicating the number of files found, if -Verbose flag is used
if ($VerbosePreference -eq "Continue") {
    Write-Verbose "Found $($fileList.Count) files with the extension '$FileExtension'."
}

# Iterate through each file
foreach ($file in $fileList) {
    # Construct new filename with leading zeros using counter
    $newName = '{0:D4}{1}' -f $Start++, $file.Extension

    # Rename the file
    Rename-Item $file.FullName -NewName $newName -Verbose:$VerbosePreference
}

Write-Output "Renaming process completed."
