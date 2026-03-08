function Get-CPJumboHotfix {
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
    $sCPInfoResult = Invoke-CPInfo -ManagementInfo $ManagementInfo -Firewall $Firewall -Arguments "-y fw1"
    return ($sCPInfoResult.Split("`r`n") | Where-Object { $_ -like "*Take*" }).Split(":")[1].Trim()
}