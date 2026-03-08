function Get-GatewayPlatform {
    Param(
        [object]$ManagementInfo,
        [Parameter(ParameterSetName = "name", Position = 0)]
        [string]$name,
        [Parameter(ParameterSetName = "uid")]
        [string]$uid
    )
    Begin {
        $oMgmtInfo = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
        $hParam = @{
            $($PSCmdlet.ParameterSetName) = $PSBoundParameters[$PSCmdlet.ParameterSetName]
        }
    }
    Process {
        return $oMgmtInfo.CallAPI("get-platform", $hParam)
    }
}