function Update-AddressRange {
    [CmdletBinding(DefaultParameterSetName = 'name')]
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(Mandatory, ParameterSetName = "name", Position = 0)]
        [string]$name,
        [string]${ip-address-first},
        [switch]${ipv4-address-first},
        [switch]${ipv6-address-first},
        [string]${ip-address-last},
        [switch]${ipv4-address-last},
        [switch]${ipv6-address-last},
        [string]${new-name},
        [switch]${ignore-warnings},
        [Alias("description")]
        [string]$comments,
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
        return $oMgmtInfo.CallAPI("set-address-range", $hAPIParameters)
    }
}