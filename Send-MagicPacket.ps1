[CmdletBinding()]
param
(
    [string]$Mac,
	[string]$Destination = "192.168.0.11",
    [int]$Port = 9
)
function Send-MagicPacket {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Mac,
		[Parameter(Mandatory)]
		[string]$Destination,
        [Parameter(Mandatory)]
		[int]$Port
    )
    $MacByteArray = $Mac -split "[:-]" | ForEach-Object { [Byte] "0x$_"}
	[Byte[]] $MagicPacket = (,0xFF * 6) + ($MacByteArray  * 16)
    Write-Output "Magic byte array is:"
    $MagicPacket | Format-Hex
    $UdpClient = New-Object System.Net.Sockets.UdpClient
	$IPAddress = [System.Net.IPAddress]::Parse($Destination)
    Write-Output $IPAddress | fl
	$UdpClient.Connect($IPAddress,$Port)
    $pSize = $UdpClient.Send($MagicPacket,$MagicPacket.Length)
	Write-Output "Package size: $pSize"
	$UdpClient.Close()
}
Send-MagicPacket -Mac $Mac -Destination $Destination -Port $Port