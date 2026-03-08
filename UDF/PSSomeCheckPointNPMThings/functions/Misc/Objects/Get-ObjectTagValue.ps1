function Get-ObjectTagValue {
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [object]$Object,
        [string]$TagName
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $oObject = if ($Object -is [string]) {
            $hObjectID = (Resolve-CPObjectIdentifier -Identifier $Object)
            Get-Object @hObjectID -ManagementInfo $oMgmtInfo
        } else {
            $Object
        }
    }
    Process {
        $oTag = $oObject.tags | Where-Object { $_.name -like "$TagName`:*" }
        if ($oTag) {
            return $oTag.name.SubString($TagName.Length + 1)
        } else {
            return $null
        }
    }
}