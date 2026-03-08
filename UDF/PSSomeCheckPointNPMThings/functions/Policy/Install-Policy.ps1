function Install-Policy {
    Param(
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [string]${policy-package},
        [string[]]$targets,
        [bool]$access,
        [bool]${desktop-policy},
        [bool]$qos,
        [bool]${threat-prevention},
        [bool]${install-on-all-cluster-members-or-fail} = $true,
        [bool]${prepare-only} = $false,
        [string]$revision,
        [bool]${ignore-warnings},
        [switch]$EndTask
    )
    Begin {
        $oMgmtInfo = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "EndTask")
    }
    Process {
        $apiResult = $oMgmtInfo.CallAPI("install-policy", $hAPIParameters)
        $oMgmtInfo.LatestTask = $apiResult."task-id"
        $sTaskId = $apiResult."task-id"
        if ($WaitEnd) {
            return Wait-Task -ManagementInfo $oMgmtInfo -task-id $sTaskId
        } else {
            return $sTaskId
        }
    }
}