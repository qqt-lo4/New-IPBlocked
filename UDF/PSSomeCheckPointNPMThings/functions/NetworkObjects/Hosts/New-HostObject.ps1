function New-HostObject {
    [CmdletBinding(DefaultParameterSetName = "ip-address")]
    Param(
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [string]$name,
        [Parameter(ParameterSetName = "ip-address", Position = 1)]
        [string]${ip-address},
        [Parameter(ParameterSetName = "ipv4-address")]
        [string]${ipv4-address},
        [Parameter(ParameterSetName = "ipv6-address")]
        [string]${ipv6-address},
        [Parameter(Position = 2)]
        [Alias("Description")]
        [AllowNull()]
        [string]$comments,
        [switch]${set-if-exists},
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
        return $oMgmtInfo.CallAPI("add-host", $hAPIParameters)
    }
}