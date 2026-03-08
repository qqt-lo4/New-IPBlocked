function Invoke-SessionDiscard {
    Param(
        [object]$ManagementInfo,
        [Parameter(Position = 0)]
        [string]$uid
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
    }
    Process {
        $hAPIParameters = if ($uid) {
            @{
                uid = $uid
            }
        } else {
            @{}
        } 
        return $oMgmtInfo.CallAPI("discard", $hAPIParameters)
    }
}
