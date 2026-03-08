function Get-RecursiveGroupMembers {
    Param(
        [object]$ManagementInfo,
        [Parameter(Mandatory)]
        [string]$Uid
    )
    $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
    $oDictionnary = Get-ObjectsDictionnary -ManagementInfo $oMgmtInfo

    $oObject = $oDictionnary.Get($Uid)
    if ($oObject -eq $null) {
        throw "Can't get objet with uid $Uid"
    } else {
        if ($oObject.type -eq "group") {
            $aResult = @()
            foreach ($oMember in $oObject.members) {
                $sUID = if ($oMember -is [string]) {
                    $oMember
                } else {
                    $oMember.uid
                }
                $aResult += Get-RecursiveGroupMembers -ManagementInfo $oMgmtInfo -uid $sUID
            }
            return $aResult
        } else {
            return $oObject
        }
    }
}