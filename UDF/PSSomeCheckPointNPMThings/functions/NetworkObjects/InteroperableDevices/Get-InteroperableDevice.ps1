function Get-InteroperableDevice {
    [CmdLetBinding(DefaultParameterSetName = "name")]
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(ParameterSetName = "name", Position = 0)]
        [string]$name,
        [Parameter(ParameterSetName = "list")]
        [string]$filter,
        [Parameter(ParameterSetName = "list")]
        [int]$limit = 50,
        [Parameter(ParameterSetName = "list")]
        [int]$offset = 0,
        [Parameter(ParameterSetName = "list")]
        [switch]$All,
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard"
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "All")
    }
    Process {
        if ($PSCmdlet.ParameterSetName -eq "list") {
            if ($All) {
                return $oMgmtInfo.CallAllPagesAPI("show-interoperable-devices", $hAPIParameters, "packages")
            } else {
                return $oMgmtInfo.CallAPI("show-interoperable-devices", $hAPIParameters, "packages")
            }
        } else {
            return $oMgmtInfo.CallAPI("show-interoperable-device", $hAPIParameters)
        }
    }
}