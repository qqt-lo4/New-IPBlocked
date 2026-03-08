function Invoke-VpnTu {
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory)]
        [object]$Firewall,
        [AllowNull()]
        [string]$WaitProgressMessage,
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Timeout = 60,
        [Parameter(ParameterSetName = "list ike")]
        [switch]$ListIKE,
        [Parameter(ParameterSetName = "list ipsec")]
        [switch]$ListIPSec,
        [Parameter(ParameterSetName = "list ike")]
        [Parameter(ParameterSetName = "list ipsec")]
        [ipaddress]$peer,
        [Parameter(ParameterSetName = "list tunnels")]
        [switch]$ListTunnels
    )
    $sCommand = switch ($PSCmdlet.ParameterSetName) {
        "list ike" {
            if ($peer) {
                "vpn tu list peer_ike $($peer.ToString())"
            } else {
                "vpn tu list ike"
            }
        }
        "list ipsec" {
            if ($peer) {
                "vpn tu list peer_ipsec $($peer.ToString())"
            } else {
                "vpn tu list ike"
            }
        }
        "list tunnels" {
            "vpn tu list tunnels"
        }
    }
    return Invoke-CpridutilBash -ManagementInfo $ManagementInfo -Firewall $Firewall -Script $sCommand -WaitProgressMessage $WaitProgressMessage -Timeout $Timeout
}
