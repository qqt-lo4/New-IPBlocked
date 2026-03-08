#region Includes
Import-Module $PSScriptRoot\UDF\PSSomeAPIThings
Import-Module $PSScriptRoot\UDF\PSSomeCheckPointNPMThings -WarningAction SilentlyContinue
Import-Module $PSScriptRoot\UDF\PSSomeCoreThings
Import-Module $PSScriptRoot\UDF\PSSomeDataThings
Import-Module $PSScriptRoot\UDF\PSSomeGUIThings
Import-Module $PSScriptRoot\UDF\PSSomeNetworkThings
#endregion Includes

#region script info
#scriptType=standard
#scriptVersion=2.0
#outputMode=multiple
#outputMultipleChoices=qqt
#endregion script info

function Test-IPAlreadyBlocked{
    Param(
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [string]$IP,
        [Parameter(Mandatory)]
        [string]$BlockGroupName
    )
    $oMgmtAPI = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
    $aObjects = (Get-Objects -ManagementInfo $oMgmtAPI -filter $IP -ip-only).objects
    $bResult = $false
    foreach ($o in $aObjects) {
        $oDetailedObject = Get-Object -uid $o.uid -ManagementInfo $oMgmtAPI -GetMemberOf
        if ($BlockGroupName -in $oDetailedObject.groups.name) {
            $bResult = $true
        }
    }
    return $bResult
}

function New-ObjectToBlockedList {
    Param(
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [string]$IP,
        [Parameter(Mandatory, Position = 1)]
        [string]$ITCaseNumber,
        [Parameter(Position = 2)]
        [AllowNull()]
        [string]$EDRCaseNumber,
        [string]$Actor,
        [Parameter(Mandatory)]
        [string]$BlockGroupName
    )
    $oMgmtAPI = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
    if (-not (Test-IPAlreadyBlocked -ManagementInfo $oMgmtAPI -IP $IP -BlockGroupName $BlockGroupName)) {
        Write-Host "New IP to block $IP"
        $oTest = Test-StringIsIP $IP
        $sDescription = "$ITCaseNumber - $Actor - $(Get-Date -Format "yyyy-MM-dd")"
        if ($EDRCaseNumber) {
            $sDescription += " - $EDRCaseNumber"
        }
        $oNewObject = switch ($oTest.Type) {
            "Network" {
                $sName = "Net_" + $oTest.ipv4 + "_" + $oTest.masklengthv4
                New-NetworkObject -ManagementInfo $oMgmtAPI -name $sName -subnet $oTest.ipv4 -mask-length $oTest.masklengthv4 -comments $sDescription -ignore-warnings
            }
            "Address" {
                $sName = "IP_" + $oTest.ipv4
                New-HostObject -ManagementInfo $oMgmtAPI -name $sName -ip-address $oTest.ipv4 -comments $sDescription -ignore-warnings
            }
            "Range" {
                $sName = "Range_" + $oTest.ipv4range
                New-AddressRange -ManagementInfo $oMgmtAPI -name $sName -ip-address-first $oTest.ipstart -ip-address-last $oTest.ip-address-last -comments $sDescription -ignore-warnings
            }
        }
        Write-Host "Adding $IP to blocklist"
        Update-NetworkGroup -ManagementInfo $oMgmtAPI -name $BlockGroupName -add -members $oNewObject.name
    } else {
        Write-Warning "IP already blocked $IP"
    }
}

function Get-ProdPolicyPackages {
    Param(
        [object]$ManagementInfo
    )
    $oMgmtAPI = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
    $oPackages = Get-PolicyPackages -ManagementInfo $oMgmtAPI -details-level full 
    if ($oPackages.Total -gt 0) {
        return $oPackages.packages | Where-Object { $_.name -like "Prod-*" }
    }
}

function Test-AccessRulebaseContainsObject {
    Param(
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [string]$AccessRulebaseName,
        [Parameter(Mandatory, Position = 1)]
        [string]$ObjectName
    )
    $oMgmtAPI = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
    $pol = Get-AccessRulebase -name $AccessRulebaseName -All -ManagementInfo $oMgmtAPI
    return $ObjectName -in $pol."objects-dictionary".name
}

function Test-PolicyPackageContainsObject {
    Param(
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [string]$PolicyPackageName,
        [Parameter(Mandatory, Position = 1)]
        [string]$ObjectName
    )
    $oMgmtAPI = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
    $bResult = $false
    $oPolicyPackage = Get-PolicyPackage -ManagementInfo $oMgmtAPI -name $PolicyPackageName
    foreach ($accesslayer in $oPolicyPackage."access-layers".name) {
        $bResult = $bResult -or (Test-AccessRulebaseContainsObject -ManagementInfo $oMgmtAPI -AccessRulebaseName $accesslayer -ObjectName $ObjectName)
    }
    return $bResult
}

function Test-PolicyPackageNeedsPush {
    Param(
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [string]$PolicyPackageName
    )
    $oMgmtAPI = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
    return Test-PolicyPackageContainsObject -ManagementInfo $oMgmtAPI -PolicyPackageName $PolicyPackageName -ObjectName "External_Blocked_Addresses"
}

function Install-NewBlockedIPPolicy {
    Param(
        [object]$ManagementInfo
    )
    $oMgmtAPI = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
    Write-Host "Getting list of policy packages"
    $aPolicyPackages = Get-ProdPolicyPackages -ManagementInfo $oMgmtAPI
    foreach ($oPolicyPackage in $aPolicyPackages) {
        $bInstallNeeded = Test-PolicyPackageNeedsPush -ManagementInfo $oMgmtAPI -PolicyPackageName $oPolicyPackage.name
        if ($bInstallNeeded) {
            Write-Host "Policy package $($oPolicyPackage.name) needs to be installed"
            Write-Host "Installing policy package"
            $aTargets = Get-PublicFirewallsOfPolicyPackage -ManagementInfo $oMgmtAPI -PolicyPackage $oPolicyPackage 
            Install-Policy -ManagementInfo $oMgmtAPI -policy-package $oPolicyPackage.name -targets $aTargets.name
            Write-Host "Installion of policy package $($oPolicyPackage.name) finished"
        } else {
            Write-Host "No need to install policy package $($oPolicyPackage.name)"
        }
    }
}

function Get-PublicFirewallsOfPolicyPackage {
    Param(
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [object]$PolicyPackage
    )
    $oMgmtAPI = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
    $aResult = @()
    foreach($oFirewall in $PolicyPackage.'installation-targets') {
        if (Test-GatewayHasPublicInterface -ManagementInfo $oMgmtAPI -uid $oFirewall.uid -UseCache) {
            $aResult += $oFirewall
        }
    }
    return $aResult
}

function Split-StringToIP {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$InputString
    )
    $sRegex = Get-NetworkObjectRegex -IP -Range -Network 
    $hResult = Select-StringMatchingGroup -InputString $InputString -Regex $sRegex -ExludeNumbers
    $aResult = @()
    if ($hResult.ipv4_network) {
        $aResult += $hResult.ipv4_network
    }
    if ($hResult.ipv6_network) {
        $aResult += $hResult.ipv6_network
    }
    if ($hResult.ipv4_range) {
        $aResult += $hResult.ipv4_range
    }
    if ($hResult.ipv6_range) {
        $aResult += $hResult.ipv6_range
    }
    if ($hResult.ipv4) {
        $aResult += $hResult.ipv4
    }
    if ($hResult.ipv6) {
        $aResult += $hResult.ipv6
    }
    return $aResult
}

# Script PowerShell pour créer une interface graphique WPF avec thème adaptatif
$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Check Point - New-IPBlocked"
    Height="750"
    Width="600"
    Background="{ThemeColor:WindowBackground}">

    <Window.Resources></Window.Resources>

    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Cadres Serveurs + Authentification côte à côte -->
        <Grid Grid.Row="0" Margin="0,0,0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <!-- Cadre Serveurs -->
            <GroupBox Grid.Column="0" Header="Serveurs" Margin="0,0,5,0"
                      Foreground="{ThemeColor:TextPrimary}"
                      BorderBrush="{ThemeColor:BorderColor}">
                <Grid Margin="5">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <ListBox Grid.Row="0"
                             Name="lstServers"
                             MinHeight="80"
                             Style="{StaticResource ListBoxStyleSquareBottom}"
                             BorderThickness="1,1,1,0"
                             Background="{ThemeColor:CardBackground}"
                             Foreground="{ThemeColor:TextPrimary}"
                             BorderBrush="{ThemeColor:BorderColor}">
                        <ListBox.ItemContainerStyle>
                            <Style TargetType="ListBoxItem">
                                <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
                                <Setter Property="Background" Value="Transparent"/>
                                <Setter Property="Foreground" Value="{ThemeColor:TextPrimary}"/>
                                <Setter Property="Padding" Value="5,3"/>
                                <Setter Property="Template">
                                    <Setter.Value>
                                        <ControlTemplate TargetType="ListBoxItem">
                                            <Border x:Name="Border"
                                                    Background="{TemplateBinding Background}"
                                                    Padding="{TemplateBinding Padding}"
                                                    CornerRadius="3"
                                                    Margin="2">
                                                <ContentPresenter/>
                                            </Border>
                                            <ControlTemplate.Triggers>
                                                <Trigger Property="IsMouseOver" Value="True">
                                                    <Setter TargetName="Border" Property="Background" Value="{ThemeColor:TileHover}"/>
                                                </Trigger>
                                                <Trigger Property="IsSelected" Value="True">
                                                    <Setter TargetName="Border" Property="Background" Value="{ThemeColor:AccentColor}"/>
                                                    <Setter Property="Foreground" Value="White"/>
                                                </Trigger>
                                            </ControlTemplate.Triggers>
                                        </ControlTemplate>
                                    </Setter.Value>
                                </Setter>
                            </Style>
                        </ListBox.ItemContainerStyle>
                        <ListBox.ItemTemplate>
                            <DataTemplate>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="Auto"/>
                                    </Grid.ColumnDefinitions>
                                    <TextBlock Grid.Column="0"
                                               Text="{Binding}"
                                               VerticalAlignment="Center"/>
                                    <Button Grid.Column="1"
                                            x:Name="btnDeleteServer"
                                            Content="✕"
                                            Visibility="Hidden"
                                            Width="18" Height="18"
                                            Padding="0"
                                            BorderThickness="0"
                                            Background="Transparent"
                                            Foreground="{ThemeColor:IconError}"
                                            FontSize="10"
                                            Cursor="Hand">
                                        <Button.Template>
                                            <ControlTemplate TargetType="Button">
                                                <Border x:Name="bd"
                                                        Background="{TemplateBinding Background}"
                                                        CornerRadius="3">
                                                    <ContentPresenter HorizontalAlignment="Center"
                                                                      VerticalAlignment="Center"/>
                                                </Border>
                                                <ControlTemplate.Triggers>
                                                    <Trigger Property="IsMouseOver" Value="True">
                                                        <Setter TargetName="bd" Property="Background" Value="{ThemeColor:TileHover}"/>
                                                    </Trigger>
                                                </ControlTemplate.Triggers>
                                            </ControlTemplate>
                                        </Button.Template>
                                    </Button>
                                </Grid>
                                <DataTemplate.Triggers>
                                    <DataTrigger Binding="{Binding RelativeSource={RelativeSource AncestorType=ListBoxItem}, Path=IsMouseOver}" Value="True">
                                        <Setter TargetName="btnDeleteServer" Property="Visibility" Value="Visible"/>
                                    </DataTrigger>
                                </DataTemplate.Triggers>
                            </DataTemplate>
                        </ListBox.ItemTemplate>
                    </ListBox>

                    <!-- TextBox d'ajout inline avec placeholder et bouton + intégré -->
                    <Grid Grid.Row="1" Margin="0">
                        <TextBox Name="txtAddServer"
                                 Style="{StaticResource TextBoxStyleSquareTop}"
                                 Padding="5,4,30,4"
                                 Background="{ThemeColor:CardBackground}"
                                 Foreground="{ThemeColor:TextPrimary}"
                                 BorderBrush="{ThemeColor:BorderColor}"/>
                        <TextBlock Text="Ajouter un serveur..."
                                   Foreground="{ThemeColor:TextSecondary}"
                                   FontStyle="Italic"
                                   IsHitTestVisible="False"
                                   VerticalAlignment="Center"
                                   Margin="8,0,30,0">
                            <TextBlock.Style>
                                <Style TargetType="TextBlock">
                                    <Setter Property="Visibility" Value="Collapsed"/>
                                    <Style.Triggers>
                                        <DataTrigger Binding="{Binding Text, ElementName=txtAddServer}" Value="">
                                            <Setter Property="Visibility" Value="Visible"/>
                                        </DataTrigger>
                                    </Style.Triggers>
                                </Style>
                            </TextBlock.Style>
                        </TextBlock>
                        <Button Name="btnAddServer"
                                Content="+"
                                HorizontalAlignment="Right"
                                VerticalAlignment="Center"
                                Width="18" Height="18"
                                Margin="0,0,10,0"
                                Padding="0"
                                BorderThickness="0"
                                Background="Transparent"
                                Foreground="{ThemeColor:IconSuccess}"
                                FontSize="12"
                                FontWeight="Bold"
                                Cursor="Hand">
                            <Button.Template>
                                <ControlTemplate TargetType="Button">
                                    <Border x:Name="bd"
                                            Background="{TemplateBinding Background}"
                                            CornerRadius="3">
                                        <ContentPresenter HorizontalAlignment="Center"
                                                          VerticalAlignment="Center"/>
                                    </Border>
                                    <ControlTemplate.Triggers>
                                        <Trigger Property="IsMouseOver" Value="True">
                                            <Setter TargetName="bd" Property="Background" Value="{ThemeColor:TileHover}"/>
                                        </Trigger>
                                    </ControlTemplate.Triggers>
                                </ControlTemplate>
                            </Button.Template>
                        </Button>
                    </Grid>
                </Grid>
            </GroupBox>

            <!-- Cadre Authentification -->
            <GroupBox Grid.Column="1" Header="Authentification" Margin="5,0,0,0"
                      Foreground="{ThemeColor:TextPrimary}"
                      BorderBrush="{ThemeColor:BorderColor}">
                <Grid Margin="5">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>

                    <Label Grid.Row="0" Grid.Column="0"
                           Content="Identifiant :"
                           VerticalAlignment="Center"
                           Foreground="{ThemeColor:TextPrimary}"/>
                    <TextBox Grid.Row="0" Grid.Column="1"
                             Name="txtUsername"
                             Margin="5"
                             Background="{ThemeColor:CardBackground}"
                             Foreground="{ThemeColor:TextPrimary}"
                             BorderBrush="{ThemeColor:BorderColor}"/>

                    <Label Grid.Row="1" Grid.Column="0"
                           Content="Mot de passe :"
                           VerticalAlignment="Center"
                           Foreground="{ThemeColor:TextPrimary}"/>
                    <PasswordBox Grid.Row="1" Grid.Column="1"
                                 Name="pwdPassword"
                                 Margin="5"
                                 Background="{ThemeColor:CardBackground}"
                                 Foreground="{ThemeColor:TextPrimary}"
                                 BorderBrush="{ThemeColor:BorderColor}"/>
                </Grid>
            </GroupBox>
        </Grid>

        <!-- Paramètres -->
        <GroupBox Grid.Row="1" Header="Paramètres" Margin="0,0,0,10"
                  Foreground="{ThemeColor:TextPrimary}"
                  BorderBrush="{ThemeColor:BorderColor}">
            <Grid Margin="5">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Label Grid.Column="0"
                       Content="Groupe de blocage :"
                       VerticalAlignment="Center"
                       Foreground="{ThemeColor:TextPrimary}"/>
                <TextBox Grid.Column="1"
                         Name="txtBlockGroup"
                         Margin="5,0,5,0"
                         Background="{ThemeColor:CardBackground}"
                         Foreground="{ThemeColor:TextPrimary}"
                         BorderBrush="{ThemeColor:BorderColor}"/>
            </Grid>
        </GroupBox>

        <!-- Zone pour la liste d'IP -->
        <GroupBox Grid.Row="2" Header="Liste d'adresses IP" Margin="0,0,0,10"
                  Foreground="{ThemeColor:TextPrimary}"
                  BorderBrush="{ThemeColor:BorderColor}">
            <Grid Margin="10">
                <TextBox Name="txtIpList"
                         AcceptsReturn="True"
                         TextWrapping="Wrap"
                         VerticalScrollBarVisibility="Auto"
                         Background="{ThemeColor:CardBackground}"
                         Foreground="{ThemeColor:TextPrimary}"
                         BorderBrush="{ThemeColor:BorderColor}"/>
            </Grid>
        </GroupBox>

        <!-- Tickets -->
        <GroupBox Grid.Row="3" Header="Références" Margin="0,0,0,20"
                  Foreground="{ThemeColor:TextPrimary}"
                  BorderBrush="{ThemeColor:BorderColor}">
            <Grid Margin="5">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="150"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <Label Grid.Row="0" Grid.Column="0"
                       Content="Ticket ITSM :"
                       VerticalAlignment="Center"
                       Foreground="{ThemeColor:TextPrimary}"/>
                <TextBox Grid.Row="0" Grid.Column="1"
                         Name="txtITSM"
                         Margin="5"
                         Background="{ThemeColor:CardBackground}"
                         Foreground="{ThemeColor:TextPrimary}"
                         BorderBrush="{ThemeColor:BorderColor}"/>

                <Label Grid.Row="1" Grid.Column="0"
                       Content="Numéro d'incident XDR :"
                       VerticalAlignment="Center"
                       Foreground="{ThemeColor:TextPrimary}"/>
                <TextBox Grid.Row="1" Grid.Column="1"
                         Name="txtEDR"
                         Margin="5"
                         Background="{ThemeColor:CardBackground}"
                         Foreground="{ThemeColor:TextPrimary}"
                         BorderBrush="{ThemeColor:BorderColor}"/>
            </Grid>
        </GroupBox>

        <!-- Boutons d'action -->
        <Grid Grid.Row="4">
            <Button Name="btnSave"
                    Content="Sauvegarder la configuration"
                    Width="200"
                    HorizontalAlignment="Left"
                    Style="{StaticResource PrimaryButtonSmallStyle}"/>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                <Button Name="btnExecute"
                        Content="Exécuter"
                        Width="120"
                        Margin="0,0,10,0"
                        Style="{StaticResource PrimaryButtonSmallStyle}"/>
                <Button Name="btnClear"
                        Content="Effacer"
                        Width="120"
                        Style="{StaticResource PrimaryButtonSmallStyle}"/>
            </StackPanel>
        </Grid>
    </Grid>
</Window>
"@

# Créer la fenêtre avec thème automatique
$window = New-ThemedWPFWindow -XAML $xaml

# Extraire les contrôles nommés pour y accéder plus facilement
$txtAddServer = $window.FindName("txtAddServer")
$btnAddServer = $window.FindName("btnAddServer")
$txtBlockGroup = $window.FindName("txtBlockGroup")
$txtUsername = $window.FindName("txtUsername")
$pwdPassword = $window.FindName("pwdPassword")
$lstServers = $window.FindName("lstServers")
$txtIpList = $window.FindName("txtIpList")
$txtITSM = $window.FindName("txtITSM")
$txtEDR = $window.FindName("txtEDR")
$btnSave = $window.FindName("btnSave")
$btnExecute = $window.FindName("btnExecute")
$btnClear = $window.FindName("btnClear")

# Liste des serveurs
$servers = New-Object System.Collections.ObjectModel.ObservableCollection[string]
$lstServers.ItemsSource = $servers

# Fonction pour charger la configuration
function Load-Configuration {
    try {
        # Récupérer le nom d'utilisateur Windows
        $windowsUsername = $env:USERNAME
        
        # Définir les chemins des fichiers
        $serverFilePath = Join-Path -Path (Get-ScriptDir -InputDir) -ChildPath "New-IPBlocked.json"
        $userFilePath = Join-Path -Path (Get-ScriptDir -InputDir) -ChildPath "New-IPBlocked_$windowsUsername.json"
        
        # Charger la configuration des serveurs si le fichier existe
        if (Test-Path -Path $serverFilePath) {
            $serverConfig = Get-Content -Path $serverFilePath -Raw | ConvertFrom-Json
            if ($serverConfig.Servers) {
                foreach ($server in $serverConfig.Servers) {
                    if (-not [string]::IsNullOrWhiteSpace($server) -and -not $servers.Contains($server)) {
                        $servers.Add($server)
                    }
                }
            }
            if ($serverConfig.BlockGroup) {
                $txtBlockGroup.Text = $serverConfig.BlockGroup
            }
        }
        
        # Charger la configuration de l'utilisateur si le fichier existe
        if (Test-Path -Path $userFilePath) {
            $userConfig = Get-Content -Path $userFilePath -Raw | ConvertFrom-Json
            if ($userConfig.Username) {
                $txtUsername.Text = $userConfig.Username
            }
        }
    }
    catch {
        New-WPFMessageBox -Content "Erreur lors du chargement de la configuration: $_" `
                          -Title "Avertissement" `
                          -ButtonType "OK" `
                          -Icon "Warning"
    }
}

# Charger la configuration au démarrage
Load-Configuration

# Ajouter un serveur via la touche Entrée ou le bouton +
$addServer = {
    $server = $txtAddServer.Text.Trim()
    if ($server -ne "" -and -not $servers.Contains($server)) {
        $servers.Add($server)
        $txtAddServer.Text = ""
    }
}

$txtAddServer.Add_KeyDown({
    param($s, $e)
    if ($e.Key -eq [System.Windows.Input.Key]::Enter) {
        & $addServer
        $e.Handled = $true
    }
})

$btnAddServer.Add_Click({ & $addServer })

# Supprimer un serveur via le bouton ✕ dans la liste
$lstServers.AddHandler(
    [System.Windows.Controls.Button]::ClickEvent,
    [System.Windows.RoutedEventHandler]{
        param($s, $e)
        if ($e.OriginalSource -is [System.Windows.Controls.Button]) {
            $item = $e.OriginalSource.DataContext
            if ($null -ne $item) { $servers.Remove($item) }
        }
    }
)

# Exécuter l'action principale
$btnExecute.Add_Click({
    # Récupérer les valeurs
    $serverList = $servers
    $username = $txtUsername.Text
    $password = $pwdPassword.Password
    $ipList = Split-StringToIP $txtIpList.Text
    $ITSMTicket = $txtITSM.Text
    $EDRIncident = $txtEDR.Text
    $blockGroup = $txtBlockGroup.Text.Trim()

    if ($password -ne "") {
        if ($ipList.Count -eq 0) {
            New-WPFMessageBox -Content "Aucune adresse IP valide trouvée dans la liste." `
                              -Title "Avertissement" `
                              -ButtonType "OK" `
                              -Icon "Warning"
            return
        }

        $confirmation = Show-WPFButtonDialog `
            -Title "Confirmation" `
            -Message "Les $($ipList.Count) adresse(s) IP suivante(s) vont être bloquées :" `
            -TextBoxContent ($ipList -join "`n") `
            -Buttons @(
                @{text="Confirmer"; value="confirm"},
                @{text="Annuler";   value="cancel"}
            ) `
            -Icon "Warning"

        if ($confirmation -ne "confirm") { return }

        foreach ($server in $serverList) {
            # Connexion à Check Point et exécution des commandes
            Write-Host "----------------- Connecting to Management $server -----------------" -ForegroundColor "Blue"
            $oMgmt = Connect-ManagementAPI -Address $server -Port 4434 -Username $username -Password (ConvertTo-SecureString -String $password -AsPlainText -Force) -ignoreSSLError
            foreach ($ip in $ipList) {
                Write-Host "IP to be blocked = ($ip)"
                New-ObjectToBlockedList -ManagementInfo $oMgmt -IP $ip -ITCaseNumber $ITSMTicket -EDRCaseNumber $EDRIncident -Actor $username -BlockGroupName $blockGroup
            }
            Write-Host "Session publishing in progress"
            Invoke-SessionPublish -ManagementInfo $oMgmt    
            Write-Host "Session published"
            Install-NewBlockedIPPolicy -ManagementInfo $oMgmt
            Write-Host "Disconnecting API session $username from $server"
            Invoke-SessionLogout
        }
        # Afficher un message pour confirmer l'exécution
        New-WPFMessageBox -Content "Action exécutée avec succès !" `
                          -Title "Information" `
                          -ButtonType "OK" `
                          -Icon "Information"
    } else {
        # Afficher un message pour confirmer l'exécution
        New-WPFMessageBox -Content "Mot de passe vide !" `
                          -Title "Erreur" `
                          -ButtonType "OK" `
                          -Icon "Error"
    }
})

# Enregistrer la configuration
$btnSave.Add_Click({
    try {
        # Récupérer le nom d'utilisateur Windows
        $windowsUsername = $env:USERNAME
        
        # Créer l'objet pour la configuration des serveurs
        $serverConfig = @{
            Servers    = @($servers)
            BlockGroup = $txtBlockGroup.Text
        }
        
        # Créer l'objet pour la configuration de l'utilisateur
        $userConfig = @{
            Username = $txtUsername.Text
        }
        
        # Convertir en JSON
        $serverConfigJson = $serverConfig | ConvertTo-Json
        $userConfigJson = $userConfig | ConvertTo-Json
        
        # Définir les chemins des fichiers
        $serverFilePath = Join-Path -Path (Get-ScriptDir -InputDir -FullPath) -ChildPath "New-IPBlocked.json"
        $userFilePath = Join-Path -Path (Get-ScriptDir -InputDir -FullPath) -ChildPath "New-IPBlocked_$windowsUsername.json"
        
        # Enregistrer les fichiers
        $serverConfigJson | Out-File -FilePath $serverFilePath -Encoding utf8
        $userConfigJson | Out-File -FilePath $userFilePath -Encoding utf8
        
        New-WPFMessageBox -Content "Configuration enregistrée avec succès dans :`n$serverFilePath`n$userFilePath" `
                          -Title "Succès" `
                          -ButtonType "OK" `
                          -Icon "Information"
    } catch {
        New-WPFMessageBox -Content "Erreur lors de l'enregistrement de la configuration: $_" `
                          -Title "Erreur" `
                          -ButtonType "OK" `
                          -Icon "Error"
    }
})

# Effacer les champs
$btnClear.Add_Click({
    $txtIpList.Text = ""
    $txtITSM.Text = ""
    $txtEDR.Text = ""
})

# Afficher la fenêtre
$window.ShowDialog() | Out-Null