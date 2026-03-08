function Get-Task {
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Position = 0)]
        [string[]]${task-id},
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard"
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $tID = if (${task-id}) {
            ${task-id}
        } else {
            $oMgmtInfo.LatestTask
        }
        $hAPIParameters = @{
            "task-id" = $tID
            "details-level" = ${details-level}
        }
    }
    Process {
        return $oMgmtInfo.CallAPI("show-task", $hAPIParameters)
    }
}