function Get-CPAzureMetadata {
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
    $sScript = 'curl_cli -s -H Metadata:true --max-time 2 ""http://169.254.169.254/metadata/instance?api-version=2025-04-07""'
    return Invoke-CpridutilBash -ManagementInfo $ManagementInfo -Firewall $Firewall -Script $sScript -WaitProgressMessage $WaitProgressMessage -Timeout $Timeout
}