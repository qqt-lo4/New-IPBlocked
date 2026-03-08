function Invoke-Cpridutil {
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory)]
        [object]$Firewall,
        [Parameter(Mandatory, ParameterSetName = "shell")]
        [string]$Shell,
        [Parameter(Mandatory, ParameterSetName = "shell")]
        [Parameter(Mandatory, ParameterSetName = "long")]
        [string]$Script,
        [AllowNull()]
        [string]$WaitProgressMessage,
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Timeout = 60,
        [Parameter(ParameterSetName = "long")]
        [switch]$LongOutput
    )
    $oFirewall, $oMgmtInfo = Get-GatwayAndManagementFromCache -Firewall $Firewall -ManagementInfo $ManagementInfo
    if ($oFirewall) {
        $sFirewallIP = $oFirewall."ipv4-address"
        if ($LongOutput) {
            $sTaskName = "Invoke-CpridutilLongOutput $($ManagementInfo.Username)"
            $sFileName = "cprid_util_$(Get-Date -Format "yyy-MM-dd_HH-mm-ss")"
            $sScriptToRun = @"
echo '#!/bin/bash' > /tmp/$sFileName.sh
echo '$Script > /tmp/$sFileName.txt' >> /tmp/$sFileName.sh
cprid_util putfile -server $sFirewallIP -local_file /tmp/$sFileName.sh -remote_file /tmp/$sFileName.sh -perms 0755
cprid_util -server $sFirewallIP -verbose rexec -rcmd /tmp/$sFileName.sh
cprid_util getfile -server $sFirewallIP -local_file /tmp/$sFileName.txt -remote_file /tmp/$sFileName.txt
cat /tmp/$sFileName.txt
rm /tmp/$sFileName.txt
"@ 
            #Write-Host $sScriptToRun
            $oResult = Invoke-RunScript -ManagementInfo $oMgmtInfo -script-type 'one time' -script-name $sTaskName -script $sScriptToRun -WaitProgressMessage $WaitProgressMessage -timeout $Timeout
        } else {
            $sTaskName = "Invoke-Cpridutil$Shell $($ManagementInfo.Username)"
            $sCommand = if ($sFirewallIP -eq $oMgmtInfo.Object."ipv4-address") {
                if ($Shell -eq "clish") {
                    "clish -c ""$Script"""
                } else {
                    $Script
                }
            } else {
                "cprid_util -server $sFirewallIP -verbose rexec -rcmd $Shell -c ""$Script"""
            }
            $oResult = Invoke-RunScript -ManagementInfo $oMgmtInfo -script-type 'one time' -script-name $sTaskName -script $sCommand -WaitProgressMessage $WaitProgressMessage -timeout $Timeout
        }
        return $oResult            
    } else {
        throw "Gateway not found ($Firewall)"
    }
}