function Invoke-ShowAssetAll {
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory)]
        [object]$Firewall,
        [AllowNull()]
        [string]$WaitProgressMessage
    )
    $oCommandResult = Invoke-CpridutilClish -ManagementInfo $ManagementInfo -Firewall $Firewall -Script "show asset all" -WaitProgressMessage $WaitProgressMessage
    $aCommandResultLines = ($oCommandResult.Split("`r`n"))
    return $aCommandResultLines | Convert-StringArrayToHashtable
}