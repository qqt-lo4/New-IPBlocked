function Get-GatwayAndManagementFromCache {
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory)]
        [object]$Firewall
    )
    $oFirewall = if ($Firewall -is [string]) {
        $oFoundFW = $Global:CPGatewayHashtable[$Firewall]
        if ($null -eq $oFoundFW) {
            $oMgmtInfo = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
            if ($oMgmtInfo) {
                Get-Gateway -ManagementInfo $oMgmtInfo -gateway $Firewall -details-level full
            } else {
                throw "No management found or provided"
            }
        } else {
            $oFoundFW
        }
    } else {
        $Firewall
    }
    $oMgmtInfo = if ($oFirewall) {
        $oFirewall.Management
    } else {
        $null
    }
    if (($null -ne $oFirewall) -and ($null -ne $oMgmtInfo)) {
        return $oFirewall, $oMgmtInfo
    } else {
        throw "gateway not found"
    }
}