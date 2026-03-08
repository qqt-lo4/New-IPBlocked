function Invoke-CpridutilBash {
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory)]
        [object]$Firewall,
        [Parameter(Mandatory)]
        [string]$Script,
        [AllowNull()]
        [string]$WaitProgressMessage,
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Timeout = 60,
        [string]$Regex,
        [scriptblock]$FilterLines
    )
    $oCpridutilResult = Invoke-Cpridutil -ManagementInfo $ManagementInfo -Firewall $Firewall -Shell "bash" -Script $Script -WaitProgressMessage $WaitProgressMessage -Timeout $Timeout
    $sCaller = (Get-PSCallStack)[1].Command
    $oResult = $oCpridutilResult."task-result" | Remove-EmptyString -TrimOnly
    if ($FilterLines) {
        $oResult = $oResult | Where-Object $FilterLines
    }
    if ($oCpridutilResult.status -eq "succeeded") {
        $sResult = $oResult -join "`n"
        try {
            return $sResult | ConvertFrom-Json
        } catch {
            if ($Regex) {
                $oSS = Select-String -InputObject $sResult -Pattern $Regex -AllMatches
                return $oSS | Convert-MatchInfoToHashtable -ExcludeNumbers
            } else {
                return $sResult
            }
        }
    } else {
        $exception = if ($oResult -eq "(NULL BUF)") {
            New-Object System.Exception("$sCaller failed: SIC commmunication failed")
        } else {
            New-Object System.Exception("$sCaller failed: $($oCpridutilResult.'task-result')")
        }
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            '$sCaller',
            [System.Management.Automation.ErrorCategory]::OperationStopped,
            $oCpridutilResult
        )
        throw $errorRecord
    }
}
