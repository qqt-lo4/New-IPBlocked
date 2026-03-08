function Update-NetworkGroup {
    Param(
        [AllowNull()]
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
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "Remaining", "add", "remove")
        if ($members -and $add) {
            # $aAdd = if (($hAPIParameters["members"] -is [array]) -and ($hAPIParameters["members"].Count -eq 1)) {
            #     ($hAPIParameters["members"])[0]
            # } else {
            #     $hAPIParameters["members"]
            # }
            $aAdd = $hAPIParameters["members"]
            $hAPIParameters["members"] = @{
                "add" = $aAdd
            }
        }
        if ($members -and $remove) {
            $hAPIParameters["members"] = @{
                "remove" = $hAPIParameters["members"]
            }
        }
    }
    Process {
        return $oMgmtInfo.CallAPI("set-group", $hAPIParameters)
    }
}