function New-NetworkObject {
    [CmdletBinding(DefaultParameterSetName = "Subnet")]
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [string]$name,
        [Parameter(ParameterSetName = "Subnet", Position = 1)]
        [string]$subnet,
        [Parameter(ParameterSetName = "Subnet4")]
        [string]$subnet4,
        [Parameter(ParameterSetName = "Subnet6")]
        [string]$subnet6,
        [Parameter(ParameterSetName = "Subnet", Position = 2)]
        [int]${mask-length},
        [Parameter(ParameterSetName = "Subnet4")]
        [int]${mask-length4},
        [Parameter(ParameterSetName = "Subnet6")]
        [int]${mask-length6},
        [Alias("description")]
        [AllowNull()]
        [string]$comments,
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard", 
        [switch]${ignore-warnings},
        [Parameter(ValueFromRemainingArguments)]
        $Remaining
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "Remaining")
    }
    Process {
        return $oMgmtInfo.CallAPI("add-network", $hAPIParameters)
    }
}
