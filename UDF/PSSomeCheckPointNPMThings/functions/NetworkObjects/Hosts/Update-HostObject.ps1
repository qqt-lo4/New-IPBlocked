function Update-HostObject {
    Param(
        [object]$ManagementInfo,
        [Parameter(ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(Mandatory, ParameterSetName = "name", Position = 0)]
        [string]$name,
        [string]${new-name},
        [string]${ip-address},
        [string]${ipv4-address},
        [string]${ipv6-address},
        [Alias("Description")]
        [string]$comments,
        [switch]${ignore-warnings},
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard",
        [Parameter(ValueFromRemainingArguments)]
        $Remaining
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "Remaining")
    }
    Process {
        return $oMgmtInfo.CallAPI("set-host", $hAPIParameters)
    }
}