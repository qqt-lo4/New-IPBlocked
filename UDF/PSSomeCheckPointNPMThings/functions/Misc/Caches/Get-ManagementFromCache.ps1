function Get-ManagementFromCache {
    Param(
        [AllowNull()]
        [Parameter(Position = 0)]
        [object]$Management
    )
    if ($Management -is [string]) {
        $oManagement = $Global:CPManagementHashtable[$Management]
        if ($oManagement) {
            return $oManagement
        } else {
            throw "management not found"
        }
    } elseif ($null -eq $Management) {
        if ($Global:MgmtAPI) {
            return @($Global:MgmtAPI)
        } elseif ($Global:CPManagement) {
            return $Global:CPManagement
        } else {
            throw "management not found"
        }
    } else {
        return $Management
    }
}