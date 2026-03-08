function Get-CPAWSMetadata {
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory)]
        [object]$Firewall,
        [AllowNull()]
        [string]$Token,
        [string]$MetadataURI,
        [AllowNull()]
        [string]$WaitProgressMessage,
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Timeout = 60,
        [switch]$SingleLineResult
    )
    $sToken = if ($Token) { $Token } else { Get-CPAWSMetadataToken -ManagementInfo $ManagementInfo -Firewall $Firewall -WaitProgressMessage $WaitProgressMessage -Timeout $Timeout }
    $sScript = 'curl_cli -s -H \"X-aws-ec2-metadata-token: ' + $sToken + '\" --url http://169.254.169.254/latest/' + $MetadataURI
    return Invoke-CpridutilBash -ManagementInfo $ManagementInfo -Firewall $Firewall -Script $sScript -WaitProgressMessage $WaitProgressMessage -Timeout $Timeout
}