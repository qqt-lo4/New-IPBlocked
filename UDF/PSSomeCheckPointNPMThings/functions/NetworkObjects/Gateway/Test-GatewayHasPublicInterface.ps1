function Test-GatewayHasPublicInterface {
    Param(
        [object]$ManagementInfo,
        [Parameter(ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(ParameterSetName = "name")]
        [string]$name,
        [Parameter(ParameterSetName = "gateway")]
        [object]$gateway,
        [switch]$UseCache
    )
    Begin {
        $oMgmtInfo = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
        $sParam = $($PSCmdlet.ParameterSetName)
        $sParamValue = $PSBoundParameters[$PSCmdlet.ParameterSetName]
        $hParam = @{
            $sParam = $sParamValue
        }
        if ($UseCache -and ($Global:GatewayCache -eq $null)) {
            $Global:GatewayCache = Get-Gateway -ManagementInfo $oMgmtInfo -details-level full -All
        }
    }
    Process {
        $oGateway = if($gateway) {
            $gateway
        } else {
            if ($UseCache) {
                $Global:GatewayCache.objects | Where-Object { $_.$sParam -eq $sParamValue }
            } else {
                Get-Gateway @hParam -ManagementInfo $oMgmtInfo -details-level full
            }
        }
        if ((Test-IsRFC1918 -IPAddress $oGateway."ipv4-address") -eq "Yes") {
            foreach ($ip in $oGateway.interfaces."ipv4-address") {
                if ((Test-IsRFC1918 $ip) -eq "No") {
                    return $true
                }
            }
            return $false
        } else {
            return $true
        }
    }
}