function Export-CPFirewallConfig {
    Param(
        [object[]]$Firewall,
        [Parameter(Mandatory)]
        [string]$FolderPath,
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Timeout = 60
    )
    $aFirewall = if ($Firewall) {
        $Firewall
    } else {
        $Global:CPGateway
    }
    if (-not (Test-Path $FolderPath -PathType Container)) {
        throw "Folder does not exists"
    }
    foreach ($oFirewall in $aFirewall) {
        $sFirewallName = if ($oFirewall -is [string]) { $oFirewall } else { $oFirewall.name }
        $sConfig = Get-CPGaiaConfiguration -Firewall $oFirewall -WaitProgressMessage "Export $sFirewallName config" -Timeout $Timeout
        $sConfig | Out-File -FilePath "$FolderPath\$sFirewallName`_config.txt"
    }
}