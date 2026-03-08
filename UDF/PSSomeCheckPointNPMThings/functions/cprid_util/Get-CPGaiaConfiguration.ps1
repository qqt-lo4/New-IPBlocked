function Get-CPGaiaConfiguration {
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory)]
        [object]$Firewall,
        [AllowNull()]
        [string]$WaitProgressMessage,
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Timeout = 60
    )
    $oFirewall, $oMgmtInfo = Get-GatwayAndManagementFromCache -ManagementInfo $ManagementInfo -Firewall $Firewall
    $oResult = Invoke-Cpridutil -ManagementInfo $oMgmtInfo -Firewall $oFirewall -Script "clish -c ""show configuration""" -LongOutput -WaitProgressMessage $WaitProgressMessage -Timeout $Timeout
    return $oResult."task-result"
}
