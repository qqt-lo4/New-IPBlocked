function Invoke-SessionPublish {
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Position = 0)]
        [string]$uid,
        [switch]$WaitEnd,
        [int]$WaitTimeout = 60
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
    }
    Process {
        $hParam = if ($uid) {
            @{
                uid = $uid
            }
        } else {
            @{}
        }
        $apiResult = $oMgmtInfo.CallAPI("publish", $hParam)
        $oMgmtInfo.LatestTask = $apiResult.json."task-id"
        $sTaskId = $apiResult."task-id"
        if ($WaitEnd) {
            return Wait-Task -ManagementInfo $oMgmtInfo -task-id $sTaskId -Timeout $WaitTimeout
        } else {
            return $sTaskId
        }
    }
}
