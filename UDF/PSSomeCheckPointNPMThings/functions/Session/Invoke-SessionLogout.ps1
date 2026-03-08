function Invoke-SessionLogout {
    Param(
        [object]$ManagementInfo
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
    }
    Process {
        return $oMgmtInfo.CallAPI("logout", @{})
    }
}
