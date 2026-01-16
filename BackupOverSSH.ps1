param (
    [string]$sourceFolderPath,
    [string]$destinationFolderPath,
    [string]$remoteHostName,
    [string]$privateKeyPath,
    [string]$remoteUserName
)

# Get client computer name
$clientComputerName = $env:COMPUTERNAME

# Check if the provided destination path is in Windows style
if ($destinationFolderPath -match '\\') {
    # Convert Windows-style path to Unix-style path
    $destinationFolderPath = $destinationFolderPath -replace '\\', '/'
}

# Append client computer name as a suffix to the destination folder path
$destinationFolderPath = Join-Path $destinationFolderPath $clientComputerName

# Define the SSH connection command
$sshCommand = "ssh"
if ($privateKeyPath) {
    $sshCommand += " -i `"$privateKeyPath`""
}
if ($remoteUserName) {
    $sshCommand += " `"$remoteUserName`@`"$remoteHostName`""
} else {
    $sshCommand += " `"$remoteHostName`""
}

Write-Host "Establishing SSH connection to $($sshCommand.Split(' ')[-1])..."

# Establish the SSH connection
$null = Invoke-Expression -Command $sshCommand

Write-Host "SSH connection established."

# Define the SCP command
$scpCommand = "scp"
if ($privateKeyPath) {
    $scpCommand += " -i `"$privateKeyPath`""
}

Write-Host "Getting a list of files to transfer from $sourceFolderPath..."

# Get a list of files to transfer
$filesToTransfer = Get-ChildItem -Path $sourceFolderPath -Recurse

Write-Host "Starting the backup process..."

# Loop through each file and transfer if needed
foreach ($file in $filesToTransfer) {
    $relativePath = $file.FullName.Substring($sourceFolderPath.Length + 1)
    $remoteFilePath = Join-Path $destinationFolderPath $relativePath

    # Check if the file exists on the remote server
    $remoteFileInfo = Invoke-Expression -Command "$sshCommand 'stat ""$remoteFilePath""' 2>$null"

    # Create the target destination folder if it doesn't exist
    $targetFolder = Join-Path $destinationFolderPath $relativePath | Split-Path -Parent
    Invoke-Expression -Command "$sshCommand 'mkdir -p ""$targetFolder""'"

    # Upload the file if it's new or modified
    if (-not $remoteFileInfo -or $file.LastWriteTime -gt $remoteFileInfo.LastWriteTime) {
        Write-Host "Uploading $($file.FullName) to $($remoteFilePath)..."
        Invoke-Expression -Command "$scpCommand `"$file.FullName`" $($sshCommand.Split(' ')[-1]):`"$remoteFilePath`""
        Write-Host "File uploaded successfully."
    } else {
        Write-Host "File $($file.FullName) is up to date. Skipping..."
    }
}

Write-Host "Backup process completed."

# Close the SSH connection
Invoke-Expression -Command "$sshCommand 'exit'"

Write-Host "SSH connection closed."

Write-Host "Backup completed."
