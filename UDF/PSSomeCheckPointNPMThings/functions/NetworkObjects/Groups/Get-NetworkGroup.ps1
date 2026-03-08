function Get-NetworkGroup {
    [CmdletBinding(DefaultParameterSetName = 'list')]
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(ParameterSetName = "name", Position = 0)]
        [string]$name,
        [Parameter(ParameterSetName = "group")]
        [string]$group,
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard",
        [Parameter(ParameterSetName = "uid")]
        [Parameter(ParameterSetName = "name")]
        [switch]${show-as-ranges},
        [Parameter(ParameterSetName = "list")]
        [int]$limit = 50,
        [Parameter(ParameterSetName = "list")]
        [int]$offset = 0,
        [Parameter(ParameterSetName = "list")]
        [string]$filter,
        [Parameter(ParameterSetName = "list")]
        [object]$order,
        [Parameter(ParameterSetName = "list")]
        [switch]${show-membership},
        [Parameter(ParameterSetName = "list")]
        [switch]$All,
        [switch]$Recurse
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "All", "Recurse")
        $oResult = $null
    }
    Process {
        if ($PSCmdlet.ParameterSetName -eq "list") {
            if ($All) {
                $oResult = $oMgmtInfo.CallAllPagesAPI("show-groups", $hAPIParameters)
            } else {
                $oResult = $oMgmtInfo.CallAPI("show-groups", $hAPIParameters)
            }
        } else {
            $oResult = $oMgmtInfo.CallAPI("show-group", $hAPIParameters)
        }
        
        if ((-not ${show-as-ranges}.IsPresent) -and ($Recurse.IsPresent)) {
            if ($PSCmdlet.ParameterSetName -eq "list") {
                foreach ($oGroup in $oResult.objects) {
                    Expand-Group -ManagementInfo $oMgmtInfo -ServiceGroup $oGroup
                }
            } else {
                Expand-Group -ManagementInfo $oMgmtInfo -ServiceGroup $oResult
            }
        }
        return $oResult
    }
}
