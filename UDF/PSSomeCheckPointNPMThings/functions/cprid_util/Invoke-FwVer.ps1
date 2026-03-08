function Invoke-FwVer {
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
    $sRegexFwVer = "^This is Check Point's (?<model>.+)(?<version>R[0-9][0-9](\.[0-9][0-9])+).+Build (?<build>[0-9]+)$"
    return Invoke-CpridutilBash -ManagementInfo $ManagementInfo -Firewall $Firewall -Script "fw ver" -WaitProgressMessage $WaitProgressMessage -Timeout $Timeout -Regex $sRegexFwVer
}
