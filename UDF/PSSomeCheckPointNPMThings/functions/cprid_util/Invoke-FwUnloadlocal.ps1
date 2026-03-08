function Invoke-FwUnloadlocal {
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
    return Invoke-CpridutilBash -ManagementInfo $ManagementInfo -Firewall $Firewall -Script "fw unloadlocal" -WaitProgressMessage $WaitProgressMessage -Timeout $Timeout
}
