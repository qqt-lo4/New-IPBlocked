function Get-SimpleGateway {
    [CmdletBinding(DefaultParameterSetName = "list")]
    Param(
        [object]$ManagementInfo,
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard", 
        [Parameter(ParameterSetName = "name", Position = 0)]
        [string]$name,
        [Parameter(ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(ParameterSetName = "name")]
        [Parameter(ParameterSetName = "uid")]
        [switch]${show-portals-certificate},
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
        [switch]$All
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "All")
    }
    Process {
        if ($PSCmdlet.ParameterSetName -eq "list") {
            if ($All) {
                return $oMgmtInfo.CallAllPagesAPI("show-simple-gateways", $hAPIParameters)
            } else {
                return $oMgmtInfo.CallAPI("show-simple-gateways", $hAPIParameters)
            }
        } else {
            return $oMgmtInfo.CallAPI("show-simple-gateway", $hAPIParameters)
        }
    }
}