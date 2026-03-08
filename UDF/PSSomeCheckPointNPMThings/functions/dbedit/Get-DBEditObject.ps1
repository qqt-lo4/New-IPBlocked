function Get-DBEditObject {
    [CmdletBinding()]
    Param(
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [string]$Table_name,
        [Parameter(Mandatory, Position = 1)]
        [string]$Object_name,
        [AllowNull()]
        [string]$WaitProgressMessage = "dbedit> printxml $Table_name $Object_name"
    )
    Begin {
        $oMgmtInfo = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
    }
    Process {
        return [xml](Invoke-DBedit -ManagementInfo $oMgmtInfo -Commands "printxml $Table_name $Object_name")
    }
}