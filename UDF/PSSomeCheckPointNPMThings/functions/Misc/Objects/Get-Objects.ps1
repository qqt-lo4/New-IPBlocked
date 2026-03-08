function Get-Objects {
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [string]$uids,
        [string]$filter,
        [object]$in,
        [object]$not,
        [switch]${ip-only},
        [ValidateRange(1, 500)]
        [int]$limit = 50,
        [int]$offset = 0,
        [object]$order,
        [string]${type},
        [switch]${show-membership},
        [switch]${dereference-group-members},
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard",
        [switch]$All,
        [AllowEmptyString()]
        [string]$WriteProgressMessage = ""
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "All", "WriteProgressMessage")
    }
    Process {
        if ($All) {
            return $oMgmtInfo.CallAllPagesAPI("show-objects", $hAPIParameters, @("objects"), $WriteProgressMessage)
        } else {
            return $oMgmtInfo.CallAPI("show-objects", $hAPIParameters)
        }        
    }
}