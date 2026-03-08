function Test-IPInGroup{
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [string]$IP,
        [Parameter(Mandatory, Position = 1)]
        [object]$Group
    )
    $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
    $aObjects = (Get-Objects -ManagementInfo $oMgmtInfo -filter $IP -ip-only).objects
    $oGroup = if ($Group -is [string]) { Get-NetworkGroup -group $Group } else { $Group }
    $sGroupInto = $oGroup.name
    $bResult = $false
    foreach ($o in $aObjects) {
        $oDetailedObject = Get-Object -uid $o.uid -ManagementInfo $oMgmtInfo -GetMemberOf
        if ($sGroupInto -in $oDetailedObject.groups.name) {
            $bResult = $true
        }
    }
    return $bResult
}