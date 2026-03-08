function Get-Object {
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0, ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(Mandatory, Position = 0, ParameterSetName = "name")]
        [string]$name,
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard",
        [switch]$GetMemberOf
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
    }
    Process {
        if ($uid) {
            $body = @{
                uid = $uid
                "details-level" = ${details-level}
            }
            $oByUid = $oMgmtInfo.CallAPI("show-object", $body)
            $oResult = ($oByUid).object
            if ($GetMemberOf) {
                $hArgs = @{
                    ManagementInfo = $oMgmtInfo
                    uid = $oResult.uid
                    "details-level" = "full"
                }
                switch ($oResult.type) {
                    "host" {
                        return Get-HostObject @hArgs
                    }
                    "address-range" {
                        return Get-AddressRange @hArgs
                    }
                    "group" {
                        return Get-NetworkGroup @hArgs
                    }
                    "network" {
                        return Get-NetworkObject @hArgs
                    }
                    default {
                        return $oResult
                    }
                }
            } else {
                return $oResult
            }    
        } else {
            #name was provided
            $aObjects = Get-Objects -ManagementInfo $oMgmtInfo -filter $name -details-level full
            if ($aObjects.total -gt 0) {
                $oResult = $aObjects.objects | Where-Object { $_.name -eq $name }
                if ($oResult) {
                    return Get-Object -ManagementInfo $oMgmtInfo -uid $oResult.uid -details-level full
                } else {
                    return $null
                }
            } else {
                return $null
            }
        }
    }
}