function Get-CPAWSMetadataToken {
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
    $sScript = 'curl_cli -s --request PUT -H \"X-aws-ec2-metadata-token-ttl-seconds: 21600\" --url http://169.254.169.254/latest/api/token'  
    return Invoke-CpridutilBash -ManagementInfo $ManagementInfo -Firewall $Firewall -Script $sScript -WaitProgressMessage $WaitProgressMessage -Timeout $Timeout
}