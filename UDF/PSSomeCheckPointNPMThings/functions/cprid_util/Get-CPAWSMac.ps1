function Get-CPAWSMac {
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory)]
        [object]$Firewall,
        [AllowNull()]
        [string]$Token,
        [AllowNull()]
        [string]$WaitProgressMessage,
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Timeout = 60
    )
    return Get-CPAWSMetadata -ManagementInfo $ManagementInfo -Firewall $Firewall -Token $Token -MetadataURI "meta-data/mac" -WaitProgressMessage $WaitProgressMessage -Timeout $Timeout -SingleLineResult
}