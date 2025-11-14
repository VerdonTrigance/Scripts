[CmdletBinding()]
param(
    [string]$FileExtension = ".jpg"  # File extension to filter (default is ".jpg")
)

# Define the folder path where the files are located
$folderPath = "."

# Get all image files (assuming they have .jpg extension) in the folder
$imageFiles = Get-ChildItem -Path $folderPath -Filter "*$FileExtension" -File

# Create a list to store relevant text files
$relevantTextFiles = @()

# Iterate through each image file
foreach ($imageFile in $imageFiles) {
    # Construct the expected text file name based on the image file name
    $expectedTextFileName = $imageFile.BaseName + ".txt"

    # Check if the corresponding text file exists
    if (Test-Path (Join-Path -Path $folderPath -ChildPath $expectedTextFileName)) {
        $relevantTextFiles += $expectedTextFileName
    }
}

# Get all text files in the folder
$textFiles = Get-ChildItem -Path $folderPath -Filter *.txt -File

# Move irrelevant text files to the parent folder
foreach ($textFile in $textFiles) {
    if (-not ($relevantTextFiles -contains $textFile.Name)) {
        Move-Item -Path $textFile.FullName -Destination ".."
    }
}
