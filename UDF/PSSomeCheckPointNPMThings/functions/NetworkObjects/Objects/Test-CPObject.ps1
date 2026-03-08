function Test-CPObject {
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(ParameterSetName = "name")]
        [string]$Name,
        [Parameter(ParameterSetName = "value")]
        [string]$Value
    )
    $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo

    if ($PSCmdlet.ParameterSetName -eq "name") {
        $oResult = Get-Object -ManagementInfo $oMgmtInfo -name $Name
        if ($oResult) {
            return $oResult
        } else {
            return $null
        }
    } else {
        $oIP = Test-StringIsIP -string $Value -Mask32AsHost
        if ($oIP) {
            $sType = switch ($oIP.Type) {
                "Address" { "host" }
                "Range" { "address-range" }
                "Network" { "network" }
            }
            $aResult = Get-Objects -ManagementInfo $oMgmtInfo -filter $oIP.String -type $sType
            if ($sType -eq "Network") {
                return $aResult.objects | Where-Object { $_."mask-length4" -eq $oIP.masklengthv4 }
            } else {
                return $aResult.objects
            }
        }
    }
}