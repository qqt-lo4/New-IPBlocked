function New-TCPService {
    Param(
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [string]$name,
        [Parameter(Mandatory, Position = 1)]
        [ValidatePattern("^(([0-9]{1,5})|([0-9]{1,5}`-[0-9]{1,5}))$")]
        [string]$port,
        [switch]${set-if-exists},
        [switch]${match-for-any},
        [switch]${ignore-warnings},
        [Alias("description")]
        [string]$comments,
        [Parameter(ValueFromRemainingArguments)]
        $Remaining
    )
    Begin {
        $oMgmtInfo = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
        $body = Get-FunctionParameters -RemoveParam @("ManagementInfo", "Remaining")
    }
    Process {
        return $oMgmtInfo.CallAPI("add-service-tcp", $body)
    }
}