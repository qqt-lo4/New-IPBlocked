function Update-ServiceGroup {
    Param(
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0, ParameterSetName = "name")]
        [string]$name,
        [Parameter(Mandatory, ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(Mandatory, Position = 1)]
        [string[]]$members,
        [switch]$add,
        [switch]$remove,
        [string]$comments,
        [string]${new-name},
        [switch]${details-level},
        [switch]${ignore-warnings},
        [Parameter(ValueFromRemainingArguments)]
        $Remaining
    )
    Begin {
        if ($remove.IsPresent -and $add.IsPresent) {
            throw [System.ArgumentException] "Can't remove and add members at the same time"
        }
        if ((-not $members) -and (($remove.IsPresent) -or ($add.IsPresent))) {
            throw [System.ArgumentException] "Can't add or remove 0 elements"
        }
        $oMgmtInfo = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "Remaining", "add", "remove")
        if ($members -and $add.IsPresent) {
            $hAPIParameters["members"] = @{
                "add" = $hAPIParameters["members"]
            }
        }
        if ($members -and $remove.IsPresent) {
            $hAPIParameters["members"] = @{
                "remove" = $hAPIParameters["members"]
            }
        }
    }
    Process {
        $body = $hAPIParameters | ConvertTo-Json
        return $oMgmtInfo.CallAPI($oMgmtInfo.BaseURL + "set-service-group", $body)
    }
}