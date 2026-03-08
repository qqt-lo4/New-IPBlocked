function New-AddressRange {
    [CmdletBinding(DefaultParameterSetName = 'ip')]
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [string]$name,
        [Parameter(Mandatory, ParameterSetName = "ip", Position = 1)]
        [string]${ip-address-first},
        [Parameter(Mandatory, ParameterSetName = "ipv4", Position = 1)]
        [string]${ipv4-address-first},
        [Parameter(Mandatory, ParameterSetName = "ipv6", Position = 1)]
        [string]${ipv6-address-first},
        [Parameter(Mandatory, ParameterSetName = "ip", Position = 2)]
        [string]${ip-address-last},
        [Parameter(Mandatory, ParameterSetName = "ipv4", Position = 2)]
        [string]${ipv4-address-last},
        [Parameter(Mandatory, ParameterSetName = "ipv6", Position = 2)]
        [string]${ipv6-address-last},
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
        return $oMgmtInfo.CallAPI("add-address-range", $hAPIParameters)
    }
}