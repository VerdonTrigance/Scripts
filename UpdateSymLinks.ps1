param (
    [Parameter(Mandatory=$true)]
    [string]$SourceFolderPath
)

function Get-RelativePath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FromPath,
        
        [Parameter(Mandatory = $true)]
        [string]$ToPath
    )

    $FromPath = $FromPath.TrimEnd('\')
    $ToPath = $ToPath.TrimEnd('\')

    $fromPathParts = $FromPath -split '\\'
    $toPathParts = $ToPath -split '\\'

    $commonLength = 0
    while ($commonLength -lt $fromPathParts.Length -and $commonLength -lt $toPathParts.Length -and $fromPathParts[$commonLength] -eq $toPathParts[$commonLength]) {
        $commonLength++
    }

    $relativePathParts = @()
    for ($i = $commonLength; $i -lt $fromPathParts.Length; $i++) {
        $relativePathParts += '..'
    }

    for ($i = $commonLength; $i -lt $toPathParts.Length; $i++) {
        $relativePathParts += $toPathParts[$i]
    }

    $relativePath = $relativePathParts -join '\'
    return $relativePath
}


function Update-SymLinks {
    param (
        [string]$Source
    )

    # Get all items in the current folder
    $items = Get-ChildItem -Path $Source -Recurse -Force | ?{$_.LinkType}

    foreach ($item in $items) {
        $linkTarget = $item | select Target
        $linkRelativePath = Get-RelativePath -FromPath $item.FullName -ToPath $linkTarget
        Write-Verbose "New link path for '$($item.FullName)': $linkRelativePath"
    }
}

Update-SymLinks -Source $SourceFolderPath

Write-Output "Done."
