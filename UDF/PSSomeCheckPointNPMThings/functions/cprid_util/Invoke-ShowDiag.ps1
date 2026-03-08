function Invoke-ShowDiag {
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory)]
        [object]$Firewall,
        [AllowNull()]
        [string]$WaitProgressMessage
    )
    $oCommandResult = Invoke-CpridutilClish -ManagementInfo $ManagementInfo -Firewall $Firewall -Script "show diag" -WaitProgressMessage $WaitProgressMessage
    $aCommandResultLines = $oCommandResult.Split("`r`n")
    $aProperties = Select-LineRange -InputArray $aCommandResultLines -StartRegex "^-+$" -IncludeStartLine $false -EndRegex "^-+$" -IncludeEndLine $false
    return $aProperties | Convert-StringArrayToHashtable
}