function Invoke-RunScript {
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0, ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(Mandatory, Position = 0, ParameterSetName = "script-name")]
        [string]${script-name},
        [string[]]$targets,
        [ValidateSet("repository", "one time")]
        [string]${script-type} = "one time",
        [string]$script,
        [string]${script-base64},
        [string]${arguments},
        [string]$comments,
        [ValidateRange(0, [int]::MaxValue)]
        [int]$timeout = 60,
        [AllowNull()]
        [string]$WaitProgressMessage
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hParam = Get-FunctionParameters -RemoveParam @("ManagementInfo", "WaitProgressMessage") -RenameParam @{"arguments" = "args"}
    }
    Process {
        if ($null -eq $hParam.targets) {
            $hParam.targets = $oMgmtInfo.Object.name
        }
        $oTask = $oMgmtInfo.CallAPI($oMgmtInfo.BaseURL + "run-script", $hParam)
        $sTaskId = $oTask.tasks."task-id"
        Wait-Task -task-id $sTaskId -Timeout $timeout -ManagementInfo $oMgmtInfo -WaitProgressMessage $WaitProgressMessage | Out-Null
        $oTaskResult = Get-Task -ManagementInfo $oMgmtInfo -task-id $sTaskId -details-level full
        $oResult = $oTaskResult.tasks
        $sTaskResponse = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($oResult.'task-details'.responseMessage))
        $oResult | Add-Member -NotePropertyName "task-result" -NotePropertyValue $sTaskResponse
    }
    End {
        return $oResult
    }
}