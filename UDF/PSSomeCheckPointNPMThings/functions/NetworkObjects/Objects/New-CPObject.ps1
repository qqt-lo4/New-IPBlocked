function New-CPObject {
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Position = 0)]
        [string]$Name,
        [Parameter(Mandatory, Position = 1)]
        [string]$Value,
        [switch]$IgnoreExisting,
        [AllowNull()]
        [string]$Comment
    )
    $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
    $oIP = Test-StringIsIP $Value -Mask32AsHost
    $oDNS = Test-StringIsDNSName $Value
    if ($oIP) {
        switch ($oIP.Type) {
            "Address" {
                $sName = if ($Name) { $Name } else { "IP_$($oIP.ipv4.ToString())"}
                $sValue = $oIP.ipv4.ToString()
                $hParam = @{
                    ManagementInfo = $oMgmtInfo 
                    name = $sName 
                    "ipv4-address" = $sValue
                }
                if ($Comment) {
                    $hParam.comments = $Comment   
                }
                New-HostObject @hParam -ignore-warnings
            }
            "Network" {
                $sNetworkValue = $oIP.ipv4.ToString() + "/" + $oIP.masklengthv4
                $sName = if ($Name) { $Name } else { "Network_$($sNetworkValue -replace "/", "_")"}
                $hParam = @{
                    ManagementInfo = $oMgmtInfo 
                    name = $sName 
                    subnet = $oIP.ipv4.ToString()
                    "mask-length" = $oIP.masklengthv4
                }
                if ($Comment) {
                    $hParam.comments = $Comment   
                }
                New-NetworkObject @hParam -ignore-warnings
            }
            "Range" {
                $sName = if ($Name) { $Name } else { "Range_" + $oIP.ipv4range }
                $hParam = @{
                    ManagementInfo = $oMgmtInfo 
                    name = $sName 
                    "ip-address-first" = $oIP.ipstart
                    "ip-address-last" = $oIP.ipend
                }
                if ($Comment) {
                    $hParam.comments = $Comment   
                }
                New-AddressRange @hParam -ignore-warnings
            }
        }
    } elseif ($oDNS) {
        $sName = if ($Name) { $Name } else { "DNS_" + $oIP.ipv4range }
        New-DNSDomain -ManagementInfo $oMgmtInfo -name $Value -comments $Comment
    } else {
        throw "Invalid value format"
    }
}