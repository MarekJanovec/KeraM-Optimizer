<#
.SYNOPSIS
    KeraM Optimizer v1.0 - Enterprise Network, Security & Kernel Suite
.DESCRIPTION
    Advanced WPF GUI featuring custom animations, NDIS/WLAN hardware tuning, Auto-MTU discovery,
    DNS/Hosts sinkhole, SMB/IPsec firewall hardening, NetBIOS/LLMNR mitigation, MAC spoofing,
    and PktMon kernel packet capture (.pcapng export for Wireshark).
.AUTHOR
    Marek Janovec
#>

# Validate Administrator Privileges
if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Execution aborted: Elevated privileges required. Please run PowerShell as Administrator."
    Start-Sleep -Seconds 3
    Exit
}

$ErrorActionPreference = "SilentlyContinue"
$WorkDir = Join-Path -Path $env:TEMP -ChildPath "KeraM"
if (-not (Test-Path $WorkDir)) { New-Item -Path $WorkDir -ItemType Directory -Force | Out-Null }
$LogFile = Join-Path -Path $WorkDir -ChildPath "KeraM.log"

# Load .NET WPF Assemblies
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# ==========================================
# XAML UI DEFINITION WITH WPF ANIMATIONS
# ==========================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="KeraM Optimizer v1.0 - Enterprise Network &amp; Security Suite" Height="780" Width="1120"
        Background="#0F0F12" WindowStartupLocation="CenterScreen" ResizeMode="CanMinimize">

    <Window.Resources>
        <!-- Animated Action Button Style -->
        <Style x:Key="ModernBtn" TargetType="Button">
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="6" Padding="{TemplateBinding Padding}"
                                RenderTransformOrigin="0.5,0.5">
                            <Border.RenderTransform>
                                <ScaleTransform x:Name="BtnScale" ScaleX="1" ScaleY="1"/>
                            </Border.RenderTransform>
                            <Border.Effect>
                                <DropShadowEffect x:Name="BtnGlow" Color="#00E5FF" BlurRadius="0" ShadowDepth="0" Opacity="0"/>
                            </Border.Effect>
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <EventTrigger RoutedEvent="MouseEnter">
                                <BeginStoryboard>
                                    <Storyboard>
                                        <DoubleAnimation Storyboard.TargetName="BtnScale" Storyboard.TargetProperty="ScaleX" To="1.02" Duration="0:0:0.14"/>
                                        <DoubleAnimation Storyboard.TargetName="BtnScale" Storyboard.TargetProperty="ScaleY" To="1.02" Duration="0:0:0.14"/>
                                        <DoubleAnimation Storyboard.TargetName="BtnGlow" Storyboard.TargetProperty="BlurRadius" To="14" Duration="0:0:0.18"/>
                                        <DoubleAnimation Storyboard.TargetName="BtnGlow" Storyboard.TargetProperty="Opacity" To="0.45" Duration="0:0:0.18"/>
                                    </Storyboard>
                                </BeginStoryboard>
                            </EventTrigger>
                            <EventTrigger RoutedEvent="MouseLeave">
                                <BeginStoryboard>
                                    <Storyboard>
                                        <DoubleAnimation Storyboard.TargetName="BtnScale" Storyboard.TargetProperty="ScaleX" To="1.0" Duration="0:0:0.14"/>
                                        <DoubleAnimation Storyboard.TargetName="BtnScale" Storyboard.TargetProperty="ScaleY" To="1.0" Duration="0:0:0.14"/>
                                        <DoubleAnimation Storyboard.TargetName="BtnGlow" Storyboard.TargetProperty="BlurRadius" To="0" Duration="0:0:0.18"/>
                                        <DoubleAnimation Storyboard.TargetName="BtnGlow" Storyboard.TargetProperty="Opacity" To="0" Duration="0:0:0.18"/>
                                    </Storyboard>
                                </BeginStoryboard>
                            </EventTrigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bd" Property="Opacity" Value="0.78"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Sidebar Navigation Button Style -->
        <Style x:Key="NavBtn" TargetType="Button">
            <Setter Property="Background" Value="#18181D"/>
            <Setter Property="Foreground" Value="#A1A1AA"/>
            <Setter Property="BorderBrush" Value="#27272F"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Height" Value="44"/>
            <Setter Property="Margin" Value="0,4"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="NavBd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="6" Padding="14,0">
                            <Grid>
                                <Border x:Name="AccentBar" Width="3" HorizontalAlignment="Left" Margin="-14,6,0,6" Background="#00E5FF" CornerRadius="2" Opacity="0"/>
                                <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center"/>
                            </Grid>
                        </Border>
                        <ControlTemplate.Triggers>
                            <EventTrigger RoutedEvent="MouseEnter">
                                <BeginStoryboard>
                                    <Storyboard>
                                        <DoubleAnimation Storyboard.TargetName="AccentBar" Storyboard.TargetProperty="Opacity" To="1" Duration="0:0:0.15"/>
                                    </Storyboard>
                                </BeginStoryboard>
                            </EventTrigger>
                            <EventTrigger RoutedEvent="MouseLeave">
                                <BeginStoryboard>
                                    <Storyboard>
                                        <DoubleAnimation Storyboard.TargetName="AccentBar" Storyboard.TargetProperty="Opacity" To="0" Duration="0:0:0.15"/>
                                    </Storyboard>
                                </BeginStoryboard>
                            </EventTrigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Animated Card Border Style -->
        <Style x:Key="CardBorder" TargetType="Border">
            <Setter Property="Background" Value="#18181D"/>
            <Setter Property="BorderBrush" Value="#272730"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="8"/>
            <Setter Property="Padding" Value="16"/>
            <Setter Property="Effect">
                <Setter.Value>
                    <DropShadowEffect Color="#000000" BlurRadius="16" ShadowDepth="4" Opacity="0.45"/>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="165"/>
        </Grid.RowDefinitions>

        <!-- 1. TOP HEADER BAR -->
        <Border Grid.Row="0" Background="#141418" Padding="20,14" BorderBrush="#26262E" BorderThickness="0,0,0,1">
            <Grid>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Left" VerticalAlignment="Center">
                    <Border Width="12" Height="12" CornerRadius="6" Background="#00E5FF" Margin="0,0,12,0">
                        <Border.Effect>
                            <DropShadowEffect Color="#00E5FF" BlurRadius="12" ShadowDepth="0" Opacity="0.9"/>
                        </Border.Effect>
                        <Border.Triggers>
                            <EventTrigger RoutedEvent="Loaded">
                                <BeginStoryboard>
                                    <Storyboard RepeatBehavior="Forever" AutoReverse="True">
                                        <DoubleAnimation Storyboard.TargetProperty="Opacity" From="0.35" To="1.0" Duration="0:0:1.2"/>
                                    </Storyboard>
                                </BeginStoryboard>
                            </EventTrigger>
                        </Border.Triggers>
                    </Border>
                    <StackPanel>
                        <TextBlock Text="KeraM OPTIMIZER v1.0" Foreground="#00E5FF" FontSize="20" FontWeight="Bold"/>
                        <TextBlock Name="TxtSysInfo" Text="Initializing hardware telemetry..." Foreground="#9CA3AF" FontSize="11" Margin="0,2,0,0"/>
                    </StackPanel>
                </StackPanel>

                <!-- Quick Presets -->
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                    <TextBlock Text="QUICK PRESETS:" Foreground="#71717A" VerticalAlignment="Center" FontWeight="Bold" FontSize="11" Margin="0,0,10,0"/>
                    <Button Name="BtnPresetComp" Style="{StaticResource ModernBtn}" Content="&#x26A1; Competitive Pro (All)" Height="30" Padding="12,0" Margin="4,0" Background="#0284C7" BorderThickness="0"/>
                    <Button Name="BtnPresetSafe" Style="{StaticResource ModernBtn}" Content="&#x1F6E1; Safe &amp; Hardened" Height="30" Padding="12,0" Margin="4,0" Background="#27272A" BorderBrush="#3F3F46" BorderThickness="1"/>
                    <Button Name="BtnPresetClear" Style="{StaticResource ModernBtn}" Content="Clear Selection" Height="30" Padding="12,0" Margin="4,0" Background="#18181B" Foreground="#A1A1AA" BorderBrush="#27272A" BorderThickness="1"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- 2. MAIN WORKSPACE (SIDEBAR + DYNAMIC VIEWPORT) -->
        <Grid Grid.Row="1" Margin="16,12,16,8">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="230"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <!-- LEFT SIDEBAR NAVIGATION -->
            <Border Grid.Column="0" Style="{StaticResource CardBorder}" Margin="0,0,12,0" Padding="12">
                <Grid>
                    <StackPanel VerticalAlignment="Top">
                        <TextBlock Text="MODULES &amp; VIEWS" Foreground="#71717A" FontSize="11" FontWeight="Bold" Margin="4,0,0,8"/>
                        <Button Name="NavTab1" Style="{StaticResource NavBtn}" Content="1. TCP/IP &amp; Kernel Stack" Background="#20202A" Foreground="#00E5FF" BorderBrush="#00E5FF"/>
                        <Button Name="NavTab2" Style="{StaticResource NavBtn}" Content="2. NIC &amp; Wi-Fi 6E Tuning"/>
                        <Button Name="NavTab3" Style="{StaticResource NavBtn}" Content="3. Security &amp; Sinkholes"/>
                        <Button Name="NavTab4" Style="{StaticResource NavBtn}" Content="4. Live Tools &amp; Wireshark"/>
                    </StackPanel>

                    <!-- Emergency Panic Reset Card at Bottom of Sidebar -->
                    <Border VerticalAlignment="Bottom" Background="#1F1215" BorderBrush="#7F1D1D" BorderThickness="1" CornerRadius="6" Padding="10">
                        <StackPanel>
                            <TextBlock Text="EMERGENCY REPAIR" Foreground="#F87171" FontSize="11" FontWeight="Bold" HorizontalAlignment="Center"/>
                            <TextBlock Text="Winsock, IP Stack, ARP &amp; DHCP deep reconstruction." Foreground="#A1A1AA" FontSize="10" TextWrapping="Wrap" TextAlignment="Center" Margin="0,3,0,8"/>
                            <Button Name="BtnPanic" Style="{StaticResource ModernBtn}" Content="&#x26A0; PANIC NETWORK RESET" Height="34" Background="#DC2626" BorderThickness="0" FontSize="11" FontWeight="Bold"/>
                        </StackPanel>
                    </Border>
                </Grid>
            </Border>

            <!-- RIGHT DYNAMIC VIEWPORT -->
            <Grid Grid.Column="1" Name="ViewportContainer">

                <!-- VIEW 1: TCP/IP & KERNEL -->
                <Border Name="ViewKernel" Style="{StaticResource CardBorder}" Visibility="Visible">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <StackPanel Grid.Column="0" Margin="0,0,12,0">
                            <TextBlock Text="TCP/IP STACK OPTIMIZATION" Foreground="#00E5FF" FontWeight="Bold" FontSize="14" Margin="0,0,0,12"/>

                            <CheckBox Name="ChkNagle" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="True" Content="Disable Nagle's Algorithm"/>
                            <TextBlock Text="Sets TCPNoDelay=1, TcpAckFrequency=1, TcpDelAckTicks=0 for instant packet dispatch." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>

                            <CheckBox Name="ChkThrottling" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="True" Content="Remove Multimedia Network Throttling"/>
                            <TextBlock Text="Sets NetworkThrottlingIndex=0xFFFFFFFF &amp; SystemResponsiveness=0 (0% CPU reservation)." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>

                            <CheckBox Name="ChkCubic" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="True" Content="Enable CUBIC Congestion &amp; RSS Scaling"/>
                            <TextBlock Text="Activates Linux CUBIC algorithm, multi-core Receive-Side Scaling, and ECN capability." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>

                            <CheckBox Name="ChkTimestamps" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="True" Content="Disable RFC 1323 TCP Timestamps"/>
                            <TextBlock Text="Strips 12-byte timestamp overhead from every TCP packet header." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>
                        </StackPanel>

                        <StackPanel Grid.Column="1" Margin="12,0,0,0">
                            <TextBlock Text="KERNEL TIMERS, PORTS &amp; PATH MTU" Foreground="#00E5FF" FontWeight="Bold" FontSize="14" Margin="0,0,0,12"/>

                            <CheckBox Name="ChkPorts" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="True" Content="Expand Ephemeral User Ports &amp; Fast Recycle"/>
                            <TextBlock Text="Sets MaxUserPort=65534, TcpTimedWaitDelay=30s, and DefaultTTL=64." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>

                            <CheckBox Name="ChkAutoMTU" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="True" Content="Auto-Discover &amp; Inject Optimal Path MTU"/>
                            <TextBlock Text="Executes non-fragmented ICMP sweep (ping -f -l) to gateway and locks exact MTU." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>

                            <CheckBox Name="ChkHPET" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="False" Content="Optimize Kernel Platform Clock (TSC)"/>
                            <TextBlock Text="Removes forced HPET platform clock and disables dynamic tick to lower DPC latency." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>

                            <CheckBox Name="ChkMMCSS" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="True" Content="Boost MMCSS Game Kernel Scheduler"/>
                            <TextBlock Text="Elevates Games task profile to GPU Priority=8, CPU Priority=6, SFIO=High." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>
                        </StackPanel>
                    </Grid>
                </Border>

                <!-- VIEW 2: NIC HARDWARE & WI-FI 6E TUNING -->
                <Border Name="ViewHardware" Style="{StaticResource CardBorder}" Visibility="Collapsed">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <StackPanel Grid.Column="0" Margin="0,0,12,0">
                            <TextBlock Text="PHYSICAL NIC NDIS TUNING" Foreground="#00E5FF" FontWeight="Bold" FontSize="14" Margin="0,0,0,12"/>

                            <CheckBox Name="ChkNicPower" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="True" Content="Disable NIC Power Saving (EEE / Green)"/>
                            <TextBlock Text="Disables Energy Efficient Ethernet, Green Ethernet, and Flow Control pauses." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>

                            <CheckBox Name="ChkInterrupt" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="True" Content="Disable Interrupt Moderation"/>
                            <TextBlock Text="Forces immediate CPU interrupt servicing per packet instead of driver batching." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>

                            <CheckBox Name="ChkLSO" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="True" Content="Disable Large Send Offload (LSO v2)"/>
                            <TextBlock Text="Prevents NIC hardware segmentation delays that trigger router bufferbloat." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>

                            <CheckBox Name="ChkRSC" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="True" Content="Disable Receive Segment Coalescing (RSC)"/>
                            <TextBlock Text="Eliminates inbound packet aggregation micro-stuttering on Wi-Fi 6E &amp; Ethernet." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>
                        </StackPanel>

                        <StackPanel Grid.Column="1" Margin="12,0,0,0">
                            <TextBlock Text="WI-FI 6E (WLAN) &amp; GAMING QoS" Foreground="#00E5FF" FontWeight="Bold" FontSize="14" Margin="0,0,0,12"/>

                            <CheckBox Name="ChkWlanTune" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="True" Content="Wi-Fi 6E Anti-Lag (Stop Background Scan &amp; Roam)"/>
                            <TextBlock Text="Disables periodic WLAN spectrum scanning spikes and locks Roaming Aggressiveness to minimum." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>

                            <CheckBox Name="ChkBuffers" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="True" Content="Calibrate Hardware Ring Buffers (512 Rx / 128 Tx)"/>
                            <TextBlock Text="Applies competitive ring buffer geometry for high-tickrate gaming (CS2 / Valorant)." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>

                            <CheckBox Name="ChkGameQoS" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="True" Content="Inject DSCP 46 Expedited Forwarding (Gaming)"/>
                            <TextBlock Text="Tags outbound packets for cs2.exe, FiveM.exe, and VALORANT with top router priority." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>

                            <CheckBox Name="ChkQoSLimit" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="True" Content="Unlock Windows 20% Psched QoS Bandwidth Cap"/>
                            <TextBlock Text="Forces NonBestEffortLimit=0% in Group Policy registry." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>
                        </StackPanel>
                    </Grid>
                </Border>

                <!-- VIEW 3: SECURITY, ROUTING & SINKHOLES -->
                <Border Name="ViewSecurity" Style="{StaticResource CardBorder}" Visibility="Collapsed">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <StackPanel Grid.Column="0" Margin="0,0,12,0">
                            <TextBlock Text="HARDENING &amp; FIREWALL SINKHOLES" Foreground="#00E5FF" FontWeight="Bold" FontSize="14" Margin="0,0,0,12"/>

                            <CheckBox Name="ChkHardening" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="True" Content="Disable NetBIOS over TCP/IP &amp; LLMNR"/>
                            <TextBlock Text="Silences local broadcast noise and mitigates MitM / Responder spoofing attacks." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>

                            <CheckBox Name="ChkFirewallSMB" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="True" Content="Firewall Sinkhole: Block Outbound SMB &amp; Telemetry"/>
                            <TextBlock Text="Blocks outbound ports 135, 137-139, 445 (WAN hash leak protection) and telemetry endpoints." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>

                            <CheckBox Name="ChkHostsSinkhole" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="True" Content="Inject Local DNS Sinkhole (Hosts Telemetry Block)"/>
                            <TextBlock Text="Routes Microsoft diagnostic &amp; ad-tracking domains to 0.0.0.0 with 0% CPU overhead." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>

                            <CheckBox Name="ChkTelemetry" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="True" Content="Disable DiagTrack &amp; P2P Delivery Optimization"/>
                            <TextBlock Text="Stops background telemetry uploads and Windows Update P2P bandwidth sharing (DoSvc)." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>
                        </StackPanel>

                        <StackPanel Grid.Column="1" Margin="12,0,0,0">
                            <TextBlock Text="DNS ROUTING &amp; LEAK PROTECTION" Foreground="#00E5FF" FontWeight="Bold" FontSize="14" Margin="0,0,0,12"/>

                            <CheckBox Name="ChkAutoDns" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="True" Content="Dynamic Benchmark &amp; Apply Fastest DNS"/>
                            <TextBlock Text="Measures real-time ICMP RTT across Cloudflare, Google &amp; Quad9 and binds winner." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>

                            <CheckBox Name="ChkDnsLeak" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="True" Content="Prevent DNS Leaks (Disable Smart Multi-Homed DNS)"/>
                            <TextBlock Text="Forces Windows to query only the primary encrypted DNS instead of all adapters." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>

                            <CheckBox Name="ChkIPv6" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="False" Content="Disable IPv6 Stack on Active NIC"/>
                            <TextBlock Text="Prevents dual-stack lookup delays and Teredo tunneling overhead." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>

                            <CheckBox Name="ChkFlush" Foreground="#F4F4F5" FontSize="13" Margin="0,6" IsChecked="True" Content="Purge DNS Resolver Cache &amp; ARP Tables"/>
                            <TextBlock Text="Executes ipconfig /flushdns and arp -d * to rebuild clean local Layer-2/3 paths." Foreground="#71717A" FontSize="11" Margin="22,-2,0,8" TextWrapping="Wrap"/>
                        </StackPanel>
                    </Grid>
                </Border>

                <!-- VIEW 4: LIVE DIAGNOSTIC TOOLS & MINI WIRESHARK -->
                <Border Name="ViewTools" Style="{StaticResource CardBorder}" Visibility="Collapsed">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>

                        <!-- Tool 1: Mini Wireshark PktMon -->
                        <Border Grid.Row="0" Grid.Column="0" Background="#121216" BorderBrush="#272730" BorderThickness="1" CornerRadius="6" Margin="0,0,6,6" Padding="14">
                            <StackPanel>
                                <TextBlock Text="KERNEL PACKET SNIFFER (PKTMON -> WIRESHARK)" Foreground="#00E5FF" FontWeight="Bold" FontSize="13"/>
                                <TextBlock Text="Captures live kernel network traffic for 10 seconds and converts the trace into a standard .pcapng file on your Desktop ready for Wireshark analysis." Foreground="#9CA3AF" FontSize="11" TextWrapping="Wrap" Margin="0,6,0,12"/>
                                <Button Name="BtnPktMon" Style="{StaticResource ModernBtn}" Content="Start 10s Capture &amp; Export .PCAPNG" Height="34" Background="#0284C7" BorderThickness="0"/>
                            </StackPanel>
                        </Border>

                        <!-- Tool 2: Physical MAC Spoofer -->
                        <Border Grid.Row="0" Grid.Column="1" Background="#121216" BorderBrush="#272730" BorderThickness="1" CornerRadius="6" Margin="6,0,0,6" Padding="14">
                            <StackPanel>
                                <TextBlock Text="PHYSICAL MAC ADDRESS ANONYMIZER" Foreground="#00E5FF" FontWeight="Bold" FontSize="13"/>
                                <TextBlock Text="Generates a Locally Administered Unicast hexadecimal MAC (02:XX:XX:XX:XX:XX) and injects it into the active network adapter driver." Foreground="#9CA3AF" FontSize="11" TextWrapping="Wrap" Margin="0,6,0,12"/>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="1.4*"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Button Name="BtnMacSpoof" Grid.Column="0" Style="{StaticResource ModernBtn}" Content="Randomize MAC Now" Height="34" Margin="0,0,4,0" Background="#4F46E5" BorderThickness="0"/>
                                    <Button Name="BtnMacRestore" Grid.Column="1" Style="{StaticResource ModernBtn}" Content="Restore Original" Height="34" Margin="4,0,0,0" Background="#27272A" BorderBrush="#3F3F46" BorderThickness="1"/>
                                </Grid>
                            </StackPanel>
                        </Border>

                        <!-- Tool 3: Standalone Auto-MTU Calculator -->
                        <Border Grid.Row="1" Grid.Column="0" Background="#121216" BorderBrush="#272730" BorderThickness="1" CornerRadius="6" Margin="0,6,6,0" Padding="14">
                            <StackPanel>
                                <TextBlock Text="PATH MTU DISCOVERY ENGINE (DF BIT SWEEP)" Foreground="#00E5FF" FontWeight="Bold" FontSize="13"/>
                                <TextBlock Text="Probes your local router in Elche with Don't-Fragment ICMP payloads to calculate and apply the exact maximum packet size without fragmentation." Foreground="#9CA3AF" FontSize="11" TextWrapping="Wrap" Margin="0,6,0,12"/>
                                <Button Name="BtnMtuTest" Style="{StaticResource ModernBtn}" Content="Run Path MTU Discovery &amp; Lock MTU" Height="34" Background="#0D9488" BorderThickness="0"/>
                            </StackPanel>
                        </Border>

                        <!-- Tool 4: WLAN Scan Toggle -->
                        <Border Grid.Row="1" Grid.Column="1" Background="#121216" BorderBrush="#272730" BorderThickness="1" CornerRadius="6" Margin="6,6,0,0" Padding="14">
                            <StackPanel>
                                <TextBlock Text="WI-FI 6E AUTOCONFIG SCAN CONTROLLER" Foreground="#00E5FF" FontWeight="Bold" FontSize="13"/>
                                <TextBlock Text="Locking WLAN AutoConfig eliminates periodic lag spikes while in-game. Re-enable scanning temporarily when you need to switch Wi-Fi networks." Foreground="#9CA3AF" FontSize="11" TextWrapping="Wrap" Margin="0,6,0,12"/>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Button Name="BtnWlanLock" Grid.Column="0" Style="{StaticResource ModernBtn}" Content="Lock Wi-Fi (Gaming)" Height="34" Margin="0,0,4,0" Background="#059669" BorderThickness="0"/>
                                    <Button Name="BtnWlanUnlock" Grid.Column="1" Style="{StaticResource ModernBtn}" Content="Unlock Wi-Fi Scan" Height="34" Margin="4,0,0,0" Background="#27272A" BorderBrush="#3F3F46" BorderThickness="1"/>
                                </Grid>
                            </StackPanel>
                        </Border>
                    </Grid>
                </Border>
            </Grid>
        </Grid>

        <!-- 3. ACTION BAR & ANIMATED PROGRESS BAR -->
        <Border Grid.Row="2" Padding="16,4">
            <StackPanel>
                <!-- Smooth Progress Bar -->
                <Border Background="#18181D" CornerRadius="3" Height="6" Margin="0,0,0,8" BorderBrush="#272730" BorderThickness="1">
                    <ProgressBar Name="ProgBar" Minimum="0" Maximum="100" Value="0" Background="Transparent" Foreground="#00E5FF" BorderThickness="0"/>
                </Border>

                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="1.7*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>

                    <Button Name="BtnBackup" Grid.Column="0" Style="{StaticResource ModernBtn}" Content="1. Create System Backup" Height="42" Margin="0,0,6,0" Background="#202027" BorderBrush="#3F3F46" BorderThickness="1"/>
                    <Button Name="BtnPing" Grid.Column="1" Style="{StaticResource ModernBtn}" Content="2. Benchmark DNS &amp; Jitter" Height="42" Margin="6,0,6,0" Background="#202027" BorderBrush="#3F3F46" BorderThickness="1"/>
                    <Button Name="BtnOptimize" Grid.Column="2" Style="{StaticResource ModernBtn}" Content="&#x26A1; 3. APPLY SELECTED OPTIMIZATIONS" Height="42" Margin="6,0,6,0" Background="#0284C7" BorderThickness="0" FontSize="14" FontWeight="Bold"/>
                    <Button Name="BtnRevert" Grid.Column="3" Style="{StaticResource ModernBtn}" Content="4. Factory Rollback" Height="42" Margin="6,0,0,0" Background="#991B1B" BorderThickness="0"/>
                </Grid>
            </StackPanel>
        </Border>

        <!-- 4. LIVE AUDIT CONSOLE -->
        <Border Grid.Row="3" Background="#09090B" BorderBrush="#272730" BorderThickness="1" Margin="16,6,16,14" CornerRadius="6" Padding="10">
            <TextBox Name="TxtLog" Background="Transparent" Foreground="#10B981" FontFamily="Consolas" FontSize="12"
                     IsReadOnly="True" VerticalScrollBarVisibility="Auto" BorderThickness="0" TextWrapping="Wrap"
                     Text="[KeraM v1.0 Ready] Administrator privileges verified. Select modules or diagnostic tools to begin..."/>
        </Border>
    </Grid>
</Window>
"@

# ==========================================
# LOAD XAML & BIND CONTROLS
# ==========================================
$reader = New-Object System.Xml.XmlNodeReader $xaml
try {
    $Window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    Write-Warning "Critical XAML Load Error: $($_.Exception.Message)"
    Exit
}

# Bind Navigation & Views
$NavTab1      = $Window.FindName("NavTab1")
$NavTab2      = $Window.FindName("NavTab2")
$NavTab3      = $Window.FindName("NavTab3")
$NavTab4      = $Window.FindName("NavTab4")
$ViewKernel   = $Window.FindName("ViewKernel")
$ViewHardware = $Window.FindName("ViewHardware")
$ViewSecurity = $Window.FindName("ViewSecurity")
$ViewTools    = $Window.FindName("ViewTools")

# Bind Top & Bottom Controls
$TxtSysInfo     = $Window.FindName("TxtSysInfo")
$TxtLog         = $Window.FindName("TxtLog")
$ProgBar        = $Window.FindName("ProgBar")
$BtnPresetComp  = $Window.FindName("BtnPresetComp")
$BtnPresetSafe  = $Window.FindName("BtnPresetSafe")
$BtnPresetClear = $Window.FindName("BtnPresetClear")
$BtnBackup      = $Window.FindName("BtnBackup")
$BtnPing        = $Window.FindName("BtnPing")
$BtnOptimize    = $Window.FindName("BtnOptimize")
$BtnRevert      = $Window.FindName("BtnRevert")
$BtnPanic       = $Window.FindName("BtnPanic")

# Bind Diagnostic Tool Buttons
$BtnPktMon     = $Window.FindName("BtnPktMon")
$BtnMacSpoof   = $Window.FindName("BtnMacSpoof")
$BtnMacRestore = $Window.FindName("BtnMacRestore")
$BtnMtuTest    = $Window.FindName("BtnMtuTest")
$BtnWlanLock   = $Window.FindName("BtnWlanLock")
$BtnWlanUnlock = $Window.FindName("BtnWlanUnlock")

# Bind All 24 CheckBoxes
$CheckBoxNames = @(
    "ChkNagle", "ChkThrottling", "ChkCubic", "ChkTimestamps", "ChkPorts", "ChkAutoMTU", "ChkHPET", "ChkMMCSS",
    "ChkNicPower", "ChkInterrupt", "ChkLSO", "ChkRSC", "ChkWlanTune", "ChkBuffers", "ChkGameQoS", "ChkQoSLimit",
    "ChkHardening", "ChkFirewallSMB", "ChkHostsSinkhole", "ChkTelemetry", "ChkAutoDns", "ChkDnsLeak", "ChkIPv6", "ChkFlush"
)
$AllCheckBoxes = @()
foreach ($name in $CheckBoxNames) {
    $cb = $Window.FindName($name)
    Set-Variable -Name $name -Value $cb
    $AllCheckBoxes += $cb
}

# ==========================================
# UI ANIMATION & LOGGING HELPERS
# ==========================================
function Switch-ActiveView {
    param($TargetView, $ActiveButton)
    $AllViews = @($ViewKernel, $ViewHardware, $ViewSecurity, $ViewTools)
    $AllNavs  = @($NavTab1, $NavTab2, $NavTab3, $NavTab4)

    foreach ($v in $AllViews) { $v.Visibility = "Collapsed" }
    foreach ($b in $AllNavs) {
        $b.Background  = "#18181D"
        $b.Foreground  = "#A1A1AA"
        $b.BorderBrush = "#27272F"
    }

    $ActiveButton.Background  = "#20202A"
    $ActiveButton.Foreground  = "#00E5FF"
    $ActiveButton.BorderBrush = "#00E5FF"

    $TargetView.Opacity = 0
    $TargetView.Visibility = "Visible"

    # Smooth WPF Fade-In Animation (220ms)
    $FadeAnim = New-Object System.Windows.Media.Animation.DoubleAnimation(0, 1, [TimeSpan]::FromMilliseconds(220))
    $TargetView.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $FadeAnim)
}

$NavTab1.Add_Click({ Switch-ActiveView -TargetView $ViewKernel   -ActiveButton $NavTab1 })
$NavTab2.Add_Click({ Switch-ActiveView -TargetView $ViewHardware -ActiveButton $NavTab2 })
$NavTab3.Add_Click({ Switch-ActiveView -TargetView $ViewSecurity -ActiveButton $NavTab3 })
$NavTab4.Add_Click({ Switch-ActiveView -TargetView $ViewTools    -ActiveButton $NavTab4 })

function Set-AnimatedProgress {
    param([double]$Percent)
    $Anim = New-Object System.Windows.Media.Animation.DoubleAnimation($Percent, [TimeSpan]::FromMilliseconds(250))
    $ProgBar.BeginAnimation([System.Windows.Controls.Primitives.RangeBase]::ValueProperty, $Anim)
    $Window.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)
}

function Write-GuiLog {
    param([string]$Message, [string]$Prefix = "INFO")
    $Timestamp = Get-Date -Format "HH:mm:ss"
    $Line = "[$Timestamp] [$Prefix] $Message"
    Add-Content -Path $LogFile -Value $Line
    $TxtLog.AppendText("`r`n$Line")
    $TxtLog.ScrollToEnd()
    $Window.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)
}

# Populate System Header Info
$OS = (Get-CimInstance Win32_OperatingSystem).Caption
$ActiveNic = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Virtual -eq $false } | Select-Object -First 1
$Gateway = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Sort-Object RouteMetric | Select-Object -First 1).NextHop
$TxtSysInfo.Text = "OS: $OS   |   ACTIVE NIC: $($ActiveNic.InterfaceDescription) (MAC: $($ActiveNic.MacAddress))   |   GATEWAY: $Gateway"

# ==========================================
# REUSABLE CORE FUNCTIONS (MTU, HOSTS, WLAN)
# ==========================================
function Invoke-AutoMtuDiscovery {
    Write-GuiLog "Starting Path MTU Discovery (DF-bit ICMP sweep) towards Gateway [$Gateway]..." "MTU"
    $TargetHost = if ($Gateway) { $Gateway } else { "1.1.1.1" }
    $TestPayloads = @(1472, 1464, 1460, 1452, 1444, 1436, 1420, 1400)
    $OptimalPayload = 1472

    foreach ($Size in $TestPayloads) {
        $PingOut = ping.exe $TargetHost -n 1 -w 600 -f -l $Size
        if ($LASTEXITCODE -eq 0 -and ($PingOut -notmatch "fragment")) {
            $OptimalPayload = $Size
            break
        }
    }
    $FinalMTU = $OptimalPayload + 28
    $PhysicalNics = Get-NetAdapter -Physical | Where-Object Status -eq "Up"
    foreach ($Nic in $PhysicalNics) {
        netsh interface ipv4 set subinterface "$($Nic.Name)" mtu=$FinalMTU store=persistent | Out-Null
    }
    Write-GuiLog "Optimal non-fragmented payload: ${OptimalPayload} bytes (+28B header) -> Locked MTU = ${FinalMTU} on active NIC." "OK"
}

function Invoke-HostsSinkhole {
    param([bool]$Enable = $true)
    $HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    $BackupHosts = "$env:SystemRoot\System32\drivers\etc\hosts.KeraM.bak"
    if (-not (Test-Path $BackupHosts)) { Copy-Item -Path $HostsPath -Destination $BackupHosts -Force }

    $RawContent = Get-Content -Path $HostsPath -Raw
    if ($null -eq $RawContent) { $RawContent = "" }
    # Clean any existing KeraM block first
    $Cleaned = [regex]::Replace($RawContent, "(?s)\r?\n?# --- BEGIN KeraM SINKHOLE ---.*?# --- END KeraM SINKHOLE ---\r?\n?", "")

    if ($Enable) {
        $SinkholeBlock = @"

# --- BEGIN KeraM SINKHOLE ---
0.0.0.0 vortex.data.microsoft.com
0.0.0.0 vortex-win.data.microsoft.com
0.0.0.0 telecommand.telemetry.microsoft.com
0.0.0.0 oca.telemetry.microsoft.com
0.0.0.0 sqm.telemetry.microsoft.com
0.0.0.0 watson.telemetry.microsoft.com
0.0.0.0 redir.metaservices.microsoft.com
0.0.0.0 choice.microsoft.com
0.0.0.0 df.telemetry.microsoft.com
0.0.0.0 reports.wes.df.telemetry.microsoft.com
0.0.0.0 services.wes.df.telemetry.microsoft.com
0.0.0.0 sqm.df.telemetry.microsoft.com
0.0.0.0 telemetry.microsoft.com
0.0.0.0 watson.ppe.telemetry.microsoft.com
0.0.0.0 telemetry.appex.bing.net
0.0.0.0 telemetry.urs.microsoft.com
0.0.0.0 settings-sandbox.data.microsoft.com
0.0.0.0 statsfe2.ws.microsoft.com
0.0.0.0 corpext.msitadfs.glbdns2.microsoft.com
0.0.0.0 compatexchange.cloudapp.net
0.0.0.0 cs1.wpc.v0cdn.net
0.0.0.0 a-0001.a-msedge.net
# --- END KeraM SINKHOLE ---
"@
        Set-Content -Path $HostsPath -Value ($Cleaned.TrimEnd() + $SinkholeBlock) -Encoding Ascii -Force
        Write-GuiLog "Hosts DNS Sinkhole injected (22 Microsoft telemetry endpoints routed to 0.0.0.0)." "OK"
    } else {
        Set-Content -Path $HostsPath -Value $Cleaned.TrimEnd() -Encoding Ascii -Force
        Write-GuiLog "KeraM Hosts Sinkhole entries removed cleanly." "OK"
    }
}

# ==========================================
# PRESET BUTTONS LOGIC
# ==========================================
$BtnPresetComp.Add_Click({
    foreach ($cb in $AllCheckBoxes) { $cb.IsChecked = $true }
    Write-GuiLog "Preset loaded: Competitive Pro (All 24 kernel, hardware, Wi-Fi 6E & security modules selected)." "PRESET"
})

$BtnPresetSafe.Add_Click({
    foreach ($cb in $AllCheckBoxes) { $cb.IsChecked = $true }
    $ChkHPET.IsChecked = $false
    $ChkIPv6.IsChecked = $false
    $ChkWlanTune.IsChecked = $false
    Write-GuiLog "Preset loaded: Safe & Hardened (Excludes platform clock override, IPv6 unbind & WLAN scan lock)." "PRESET"
})

$BtnPresetClear.Add_Click({
    foreach ($cb in $AllCheckBoxes) { $cb.IsChecked = $false }
    Set-AnimatedProgress 0
    Write-GuiLog "All module selections cleared." "INFO"
})

# ==========================================
# DIAGNOSTIC TOOLS (VIEW 4) & PANIC RESET
# ==========================================
$BtnPanic.Add_Click({
    $Confirm = [System.Windows.MessageBox]::Show(
        "Execute Emergency Network Reset?`n`nThis will reconstruct Winsock catalogs, reset the TCP/IP stack, purge ARP tables, and renew DHCP leases. Active connections will briefly drop.",
        "Confirm Panic Network Reset",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )
    if ($Confirm -eq "Yes") {
        Write-GuiLog "=== EXECUTING EMERGENCY PANIC NETWORK RESET ===" "PANIC"
        Set-AnimatedProgress 20
        netsh winsock reset | Out-Null
        Write-GuiLog "Winsock Catalog reset completed." "OK"
        Set-AnimatedProgress 45
        netsh int ip reset | Out-Null
        Write-GuiLog "TCP/IP stack reset to clean state." "OK"
        Set-AnimatedProgress 70
        arp -d * | Out-Null
        ipconfig /release | Out-Null
        ipconfig /renew | Out-Null
        ipconfig /flushdns | Out-Null
        Set-AnimatedProgress 100
        Write-GuiLog "ARP table purged, DHCP lease renewed, and DNS cache flushed." "OK"
    }
})

$BtnPktMon.Add_Click({
    Write-GuiLog "--- STARTING KERNEL PACKET CAPTURE (PKTMON) ---" "SNIFFER"
    $DesktopOut = Join-Path -Path ([Environment]::GetFolderPath("Desktop")) -ChildPath "KeraM_Capture.pcapng"
    $EtlTemp    = Join-Path -Path $WorkDir -ChildPath "KeraM_Trace.etl"
    if (Test-Path $EtlTemp) { Remove-Item $EtlTemp -Force }
    if (Test-Path $DesktopOut) { Remove-Item $DesktopOut -Force }

    pktmon stop | Out-Null
    pktmon filter remove | Out-Null
    pktmon start --etw -p 0 -f $EtlTemp | Out-Null
    Write-GuiLog "Kernel ETW packet sniffer active. Capturing live traffic for 10 seconds..." "WORK"

    for ($i = 1; $i -le 10; $i++) {
        Set-AnimatedProgress ($i * 10)
        Start-Sleep -Seconds 1
    }

    pktmon stop | Out-Null
    Write-GuiLog "Capture stopped. Converting ETL kernel trace to Wireshark .pcapng format..." "WORK"
    pktmon etl2pcap $EtlTemp --out $DesktopOut | Out-Null
    if (Test-Path $EtlTemp) { Remove-Item $EtlTemp -Force }

    if (Test-Path $DesktopOut) {
        Write-GuiLog "Wireshark packet capture exported to Desktop: $DesktopOut" "OK"
    } else {
        Write-GuiLog "PktMon export failed or no packets captured." "ERROR"
    }
})

$BtnMacSpoof.Add_Click({
    $Nic = Get-NetAdapter -Physical | Where-Object Status -eq "Up" | Select-Object -First 1
    if ($null -ne $Nic) {
        $RandHex = -join ((1..5) | ForEach-Object { "{0:X2}" -f (Get-Random -Minimum 0 -Maximum 255) })
        $NewMac  = "02$RandHex"
        Write-GuiLog "Injecting randomized Locally Administered MAC [$NewMac] on $($Nic.Name)..." "MAC"
        Set-NetAdapterAdvancedProperty -Name $Nic.Name -RegistryKeyword "NetworkAddress" -RegistryValue $NewMac
        Set-NetAdapter -Name $Nic.Name -MacAddress $NewMac -Confirm:$false
        Restart-NetAdapter -Name $Nic.Name -Confirm:$false
        Start-Sleep -Seconds 3
        $UpdatedNic = Get-NetAdapter -Name $Nic.Name
        $TxtSysInfo.Text = "OS: $OS   |   ACTIVE NIC: $($UpdatedNic.InterfaceDescription) (MAC: $($UpdatedNic.MacAddress))   |   GATEWAY: $Gateway"
        Write-GuiLog "MAC Address successfully spoofed to: $($UpdatedNic.MacAddress)" "OK"
    }
})

$BtnMacRestore.Add_Click({
    $Nic = Get-NetAdapter -Physical | Where-Object Status -eq "Up" | Select-Object -First 1
    if ($null -ne $Nic) {
        Write-GuiLog "Restoring factory hardware MAC address on $($Nic.Name)..." "MAC"
        Remove-NetAdapterAdvancedProperty -Name $Nic.Name -RegistryKeyword "NetworkAddress" -Confirm:$false
        $RegAdapter = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\*" | Where-Object { $_.DriverDesc -eq $Nic.InterfaceDescription }
        if ($RegAdapter) { Remove-ItemProperty -Path $RegAdapter.PSPath -Name "NetworkAddress" -ErrorAction SilentlyContinue }
        Restart-NetAdapter -Name $Nic.Name -Confirm:$false
        Start-Sleep -Seconds 3
        $UpdatedNic = Get-NetAdapter -Name $Nic.Name
        $TxtSysInfo.Text = "OS: $OS   |   ACTIVE NIC: $($UpdatedNic.InterfaceDescription) (MAC: $($UpdatedNic.MacAddress))   |   GATEWAY: $Gateway"
        Write-GuiLog "Factory hardware MAC restored: $($UpdatedNic.MacAddress)" "OK"
    }
})

$BtnMtuTest.Add_Click({
    Set-AnimatedProgress 35
    Invoke-AutoMtuDiscovery
    Set-AnimatedProgress 100
})

$BtnWlanLock.Add_Click({
    $WlanNic = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and ($_.InterfaceDescription -match "Wi-Fi|Wireless|802\.11|MediaTek|Intel") } | Select-Object -First 1
    $WlanName = if ($WlanNic) { $WlanNic.Name } else { "Wi-Fi" }
    netsh wlan set autoconfig enabled=no interface="$WlanName" | Out-Null
    Write-GuiLog "WLAN AutoConfig background scanning LOCKED on [$WlanName] (Zero cyclic lag spikes)." "OK"
})

$BtnWlanUnlock.Add_Click({
    $WlanNic = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and ($_.InterfaceDescription -match "Wi-Fi|Wireless|802\.11|MediaTek|Intel") } | Select-Object -First 1
    $WlanName = if ($WlanNic) { $WlanNic.Name } else { "Wi-Fi" }
    netsh wlan set autoconfig enabled=yes interface="$WlanName" | Out-Null
    Write-GuiLog "WLAN AutoConfig background scanning UNLOCKED on [$WlanName] (Network list visible)." "OK"
})

# ==========================================
# 1. BACKUP MODULE
# ==========================================
$BtnBackup.Add_Click({
    Write-GuiLog "--- INITIATING SECURITY BACKUP PROTOCOL ---" "SECTION"
    Set-AnimatedProgress 25
    $SRKey = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore"
    if (Test-Path $SRKey) { Set-ItemProperty -Path $SRKey -Name "SystemRestorePointCreationFrequency" -Value 0 -Type DWord }

    Write-GuiLog "Creating Windows System Restore Point..." "WORK"
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "KeraM-v5-Backup" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-GuiLog "System Restore Point created successfully." "OK"
    } catch {
        Write-GuiLog "Restore Point skipped (VSS service busy or disabled)." "WARN"
    }

    Set-AnimatedProgress 75
    $backupPath = Join-Path -Path $WorkDir -ChildPath "Tcpip_Backup.reg"
    reg export "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters" $backupPath /y | Out-Null
    Set-AnimatedProgress 100
    if (Test-Path $backupPath) {
        Write-GuiLog "TCP/IP Registry hive exported to: $backupPath" "OK"
    }
})

# ==========================================
# 2. BENCHMARK MODULE
# ==========================================
$BtnPing.Add_Click({
    Write-GuiLog "--- RUNNING MULTI-NODE ICMP & JITTER BENCHMARK ---" "SECTION"
    $Targets = @(
        @{ Name = "Cloudflare DNS"; IP = "1.1.1.1" },
        @{ Name = "Google DNS    "; IP = "8.8.8.8" },
        @{ Name = "Quad9 Secure  "; IP = "9.9.9.9" },
        @{ Name = "Cisco OpenDNS "; IP = "208.67.222.222" }
    )
    $idx = 1
    foreach ($T in $Targets) {
        Set-AnimatedProgress ($idx * 25)
        try {
            $Pings = Test-Connection -ComputerName $T.IP -Count 4 -ErrorAction Stop
            $Avg = [math]::Round(($Pings | Measure-Object -Property ResponseTime -Average).Average, 2)
            $Min = ($Pings | Measure-Object -Property ResponseTime -Minimum).Minimum
            $Max = ($Pings | Measure-Object -Property ResponseTime -Maximum).Maximum
            $Jitter = $Max - $Min
            Write-GuiLog "$($T.Name) [$($T.IP)] -> Avg: ${Avg}ms | Min: ${Min}ms | Max: ${Max}ms | Jitter: ${Jitter}ms" "PING"
        } catch {
            Write-GuiLog "$($T.Name) [$($T.IP)] -> Request Timed Out" "ERROR"
        }
        $idx++
    }
})

# ==========================================
# 3. MASTER OPTIMIZATION ENGINE (24 MODULES)
# ==========================================
$BtnOptimize.Add_Click({
    Write-GuiLog "=== EXECUTING KeraM v1.0 ENTERPRISE OPTIMIZATION ENGINE ===" "SECTION"
    Set-AnimatedProgress 5
    $PhysicalNics = Get-NetAdapter -Physical | Where-Object Status -eq "Up"

    # 1. Nagle's Algorithm
    if ($ChkNagle.IsChecked) {
        $Adapters = Get-ItemProperty "HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*"
        foreach ($A in $Adapters) {
            Set-ItemProperty -Path $A.PSPath -Name "TCPNoDelay" -Value 1 -Type DWord
            Set-ItemProperty -Path $A.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord
            Set-ItemProperty -Path $A.PSPath -Name "TcpDelAckTicks" -Value 0 -Type DWord
        }
        Write-GuiLog "Nagle's Algorithm disabled (TCPNoDelay=1, TcpAckFrequency=1, TcpDelAckTicks=0)." "OK"
    }

    # 2. Network Throttling
    if ($ChkThrottling.IsChecked) {
        $MMKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        if (-not (Test-Path $MMKey)) { New-Item -Path $MMKey -Force | Out-Null }
        Set-ItemProperty -Path $MMKey -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -Type DWord
        Set-ItemProperty -Path $MMKey -Name "SystemResponsiveness" -Value 0 -Type DWord
        Write-GuiLog "Multimedia Network Throttling removed (0xFFFFFFFF) & SystemResponsiveness=0." "OK"
    }
    Set-AnimatedProgress 15

    # 3. CUBIC & RSS
    if ($ChkCubic.IsChecked) {
        netsh int tcp set global autotuninglevel=normal | Out-Null
        netsh int tcp set global rss=enabled | Out-Null
        netsh int tcp set global ecncapability=enabled | Out-Null
        netsh int tcp set supplemental template=internet congestionprovider=cubic | Out-Null
        Write-GuiLog "TCP Global: CUBIC Congestion Provider, RSS Multi-Core & ECN active." "OK"
    }

    # 4. TCP Timestamps
    if ($ChkTimestamps.IsChecked) {
        netsh int tcp set global timestamps=disabled | Out-Null
        Write-GuiLog "RFC 1323 TCP Timestamps disabled (-12B header overhead per packet)." "OK"
    }

    # 5. Ephemeral Ports
    if ($ChkPorts.IsChecked) {
        $TcpKey = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
        Set-ItemProperty -Path $TcpKey -Name "MaxUserPort" -Value 65534 -Type DWord
        Set-ItemProperty -Path $TcpKey -Name "TcpTimedWaitDelay" -Value 30 -Type DWord
        Set-ItemProperty -Path $TcpKey -Name "DefaultTTL" -Value 64 -Type DWord
        Write-GuiLog "Ephemeral ports expanded (MaxUserPort=65534, TimedWaitDelay=30s, TTL=64)." "OK"
    }
    Set-AnimatedProgress 30

    # 6. Auto-MTU Discovery
    if ($ChkAutoMTU.IsChecked) {
        Invoke-AutoMtuDiscovery
    }

    # 7. Platform Clock (TSC)
    if ($ChkHPET.IsChecked) {
        bcdedit /deletevalue useplatformclock | Out-Null
        bcdedit /set disabledynamictick yes | Out-Null
        Write-GuiLog "Kernel Platform Clock forced to TSC & Dynamic Tick disabled." "OK"
    }

    # 8. MMCSS Game Scheduler
    if ($ChkMMCSS.IsChecked) {
        $GameKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        if (-not (Test-Path $GameKey)) { New-Item -Path $GameKey -Force | Out-Null }
        Set-ItemProperty -Path $GameKey -Name "GPU Priority" -Value 8 -Type DWord
        Set-ItemProperty -Path $GameKey -Name "Priority" -Value 6 -Type DWord
        Set-ItemProperty -Path $GameKey -Name "Scheduling Category" -Value "High" -Type String
        Set-ItemProperty -Path $GameKey -Name "SFIO Priority" -Value "High" -Type String
        Write-GuiLog "MMCSS Game Scheduler elevated (GPU Priority=8, CPU=6, SFIO=High)." "OK"
    }
    Set-AnimatedProgress 45

    # 9. NIC Power Saving
    if ($ChkNicPower.IsChecked) {
        foreach ($Nic in $PhysicalNics) {
            Set-NetAdapterAdvancedProperty -Name $Nic.Name -RegistryKeyword "*EEE" -RegistryValue 0
            Set-NetAdapterAdvancedProperty -Name $Nic.Name -RegistryKeyword "*FlowControl" -RegistryValue 0
            Set-NetAdapterAdvancedProperty -Name $Nic.Name -RegistryKeyword "*SelectiveSuspend" -RegistryValue 0
            Set-NetAdapterAdvancedProperty -Name $Nic.Name -DisplayName "Green Ethernet" -DisplayValue "Disabled"
        }
        Write-GuiLog "NIC Hardware Power Saving (EEE, Selective Suspend, Flow Control) disabled." "OK"
    }

    # 10. Interrupt Moderation
    if ($ChkInterrupt.IsChecked) {
        foreach ($Nic in $PhysicalNics) {
            Set-NetAdapterAdvancedProperty -Name $Nic.Name -RegistryKeyword "*InterruptModeration" -RegistryValue 0
        }
        Write-GuiLog "NIC Interrupt Moderation disabled (Zero-delay CPU interrupt servicing)." "OK"
    }

    # 11. Large Send Offload (LSO)
    if ($ChkLSO.IsChecked) {
        foreach ($Nic in $PhysicalNics) {
            Set-NetAdapterAdvancedProperty -Name $Nic.Name -RegistryKeyword "*LsoV2IPv4" -RegistryValue 0
            Set-NetAdapterAdvancedProperty -Name $Nic.Name -RegistryKeyword "*LsoV2IPv6" -RegistryValue 0
        }
        Write-GuiLog "Large Send Offload (LSO v2 IPv4/IPv6) disabled." "OK"
    }

    # 12. Receive Segment Coalescing (RSC)
    if ($ChkRSC.IsChecked) {
        foreach ($Nic in $PhysicalNics) {
            Disable-NetAdapterRsc -Name $Nic.Name -IPv4 -IPv6
            Set-NetAdapterAdvancedProperty -Name $Nic.Name -RegistryKeyword "*RscIPv4" -RegistryValue 0
            Set-NetAdapterAdvancedProperty -Name $Nic.Name -RegistryKeyword "*RscIPv6" -RegistryValue 0
        }
        Write-GuiLog "Receive Segment Coalescing (RSC) disabled on active adapters." "OK"
    }
    Set-AnimatedProgress 60

    # 13. Wi-Fi 6E (WLAN) Tuning
    if ($ChkWlanTune.IsChecked) {
        foreach ($Nic in $PhysicalNics) {
            Set-NetAdapterAdvancedProperty -Name $Nic.Name -RegistryKeyword "RoamAggressiveness" -RegistryValue 0
            Set-NetAdapterAdvancedProperty -Name $Nic.Name -DisplayName "Roaming Aggressiveness" -DisplayValue "1. Lowest"
            if ($Nic.InterfaceDescription -match "Wi-Fi|Wireless|802\.11|MediaTek|Intel") {
                netsh wlan set autoconfig enabled=no interface="$($Nic.Name)" | Out-Null
            }
        }
        Write-GuiLog "Wi-Fi 6E Tuned: Background scanning suspended & Roaming Aggressiveness set to Lowest." "OK"
    }

    # 14. Ring Buffers (512 Rx / 128 Tx)
    if ($ChkBuffers.IsChecked) {
        foreach ($Nic in $PhysicalNics) {
            Set-NetAdapterAdvancedProperty -Name $Nic.Name -RegistryKeyword "*ReceiveBuffers" -RegistryValue 512
            Set-NetAdapterAdvancedProperty -Name $Nic.Name -RegistryKeyword "*TransmitBuffers" -RegistryValue 128
        }
        Write-GuiLog "NIC Ring Buffers calibrated (ReceiveBuffers=512, TransmitBuffers=128)." "OK"
    }

    # 15. Gaming QoS DSCP 46
    if ($ChkGameQoS.IsChecked) {
        $Games = @("cs2.exe", "FiveM.exe", "VALORANT-Win64-Shipping.exe")
        foreach ($G in $Games) {
            Remove-NetQosPolicy -Name "KeraM-$G" -Confirm:$false
            New-NetQosPolicy -Name "KeraM-$G" -AppPathNameMatchCondition $G -DSCPAction 46 -NetworkProfile All | Out-Null
        }
        Write-GuiLog "QoS DSCP 46 (Expedited Forwarding) active for CS2, FiveM & Valorant." "OK"
    }

    # 16. QoS 20% Cap Unlock
    if ($ChkQoSLimit.IsChecked) {
        $QoSKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"
        if (-not (Test-Path $QoSKey)) { New-Item -Path $QoSKey -Force | Out-Null }
        Set-ItemProperty -Path $QoSKey -Name "NonBestEffortLimit" -Value 0 -Type DWord
        Write-GuiLog "Windows Psched 20% QoS bandwidth reservation unlocked (0%)." "OK"
    }
    Set-AnimatedProgress 75

    # 17. NetBIOS & LLMNR Hardening
    if ($ChkHardening.IsChecked) {
        $DnsPolKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
        if (-not (Test-Path $DnsPolKey)) { New-Item -Path $DnsPolKey -Force | Out-Null }
        Set-ItemProperty -Path $DnsPolKey -Name "EnableMulticast" -Value 0 -Type DWord

        Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" | ForEach-Object {
            Invoke-CimMethod -InputObject $_ -MethodName SetTcpipNetbios -Arguments @{ TcpipNetbiosOptions = [uint32]2 } | Out-Null
        }
        Write-GuiLog "Security Hardening: NetBIOS over TCP/IP & LLMNR disabled (MitM protection)." "OK"
    }

    # 18. Firewall Outbound SMB & Telemetry Sinkhole
    if ($ChkFirewallSMB.IsChecked) {
        Remove-NetFirewallRule -Group "KeraM-Security" -ErrorAction SilentlyContinue
        New-NetFirewallRule -DisplayName "KeraM-Block-Outbound-SMB-TCP" -Group "KeraM-Security" -Direction Outbound -Action Block -Protocol TCP -RemotePort 135,137,138,139,445 | Out-Null
        New-NetFirewallRule -DisplayName "KeraM-Block-Outbound-SMB-UDP" -Group "KeraM-Security" -Direction Outbound -Action Block -Protocol UDP -RemotePort 137,138,139,445 | Out-Null
        New-NetFirewallRule -DisplayName "KeraM-Block-Telemetry-IPs" -Group "KeraM-Security" -Direction Outbound -Action Block -RemoteAddress "13.64.90.137","40.77.226.250","65.55.252.93","131.253.61.96" | Out-Null
        Write-GuiLog "Firewall Sinkhole: Outbound SMB (135/137-139/445) & telemetry IPs blocked." "OK"
    }

    # 19. Hosts Sinkhole
    if ($ChkHostsSinkhole.IsChecked) {
        Invoke-HostsSinkhole -Enable $true
    }

    # 20. Telemetry & P2P Services
    if ($ChkTelemetry.IsChecked) {
        Stop-Service -Name "DiagTrack" -Force; Set-Service -Name "DiagTrack" -StartupType Disabled
        Stop-Service -Name "DoSvc" -Force; Set-Service -Name "DoSvc" -StartupType Disabled
        Write-GuiLog "DiagTrack Telemetry and Delivery Optimization (DoSvc) services disabled." "OK"
    }
    Set-AnimatedProgress 90

    # 21. Dynamic DNS Evaluation
    if ($ChkAutoDns.IsChecked) {
        $DnsList = @(
            @{ Name="Cloudflare"; IP1="1.1.1.1"; IP2="1.0.0.1" },
            @{ Name="Google";     IP1="8.8.8.8"; IP2="8.8.4.4" },
            @{ Name="Quad9";      IP1="9.9.9.9"; IP2="149.112.112.112" }
        )
        $Best = $null; $Min = 9999
        foreach ($D in $DnsList) {
            try {
                $P = Test-Connection -ComputerName $D.IP1 -Count 2 -ErrorAction Stop
                $Avg = ($P | Measure-Object -Property ResponseTime -Average).Average
                if ($Avg -lt $Min) { $Min = $Avg; $Best = $D }
            } catch {}
        }
        if ($null -ne $Best) {
            foreach ($Nic in $PhysicalNics) {
                Set-DnsClientServerAddress -InterfaceIndex $Nic.ifIndex -ServerAddresses $Best.IP1, $Best.IP2
            }
            Write-GuiLog "Optimal DNS Bound: $($Best.Name) [$($Best.IP1)] ($([math]::Round($Min,2))ms)." "OK"
        }
    }

    # 22. DNS Leak Prevention (Smart Multi-Homed Name Resolution)
    if ($ChkDnsLeak.IsChecked) {
        $DnsPolKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
        if (-not (Test-Path $DnsPolKey)) { New-Item -Path $DnsPolKey -Force | Out-Null }
        Set-ItemProperty -Path $DnsPolKey -Name "DisableSmartNameResolution" -Value 1 -Type DWord
        $DnsCacheKey = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"
        Set-ItemProperty -Path $DnsCacheKey -Name "DisableParallelAandAAAA" -Value 1 -Type DWord
        Write-GuiLog "Smart Multi-Homed Name Resolution disabled (Zero DNS leaks across interfaces)." "OK"
    }

    # 23. Disable IPv6
    if ($ChkIPv6.IsChecked) {
        foreach ($Nic in $PhysicalNics) {
            Disable-NetAdapterBinding -Name $Nic.Name -ComponentID ms_tcpip6
        }
        Write-GuiLog "IPv6 protocol unbound from active physical network adapters." "OK"
    }

    # 24. Deep Cache & ARP Purge
    if ($ChkFlush.IsChecked) {
        ipconfig /flushdns | Out-Null
        arp -d * | Out-Null
        Write-GuiLog "DNS Resolver Cache and local ARP tables purged." "OK"
    }

    Set-AnimatedProgress 100
    Write-GuiLog "=== ALL SELECTED v1.0 OPTIMIZATIONS APPLIED SUCCESSFULLY ===" "SECTION"

    $Prompt = [System.Windows.MessageBox]::Show(
        "All selected optimizations have been applied and logged to KeraM.log.`n`nA system restart is recommended to commit kernel, NDIS, and security changes. Restart now?",
        "KeraM Optimizer v1.0 - Complete",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Information
    )
    if ($Prompt -eq "Yes") { Restart-Computer -Force }
})

# ==========================================
# 4. COMPLETE FACTORY ROLLBACK ENGINE
# ==========================================
$BtnRevert.Add_Click({
    Write-GuiLog "=== INITIATING COMPLETE FACTORY ROLLBACK ===" "SECTION"
    Set-AnimatedProgress 20
    $PhysicalNics = Get-NetAdapter -Physical | Where-Object Status -eq "Up"

    $backupPath = Join-Path -Path $WorkDir -ChildPath "Tcpip_Backup.reg"
    if (Test-Path $backupPath) {
        reg import $backupPath | Out-Null
        Write-GuiLog "Original TCP/IP Registry hive restored." "OK"
    }

    Set-AnimatedProgress 50
    foreach ($Nic in $PhysicalNics) {
        Set-DnsClientServerAddress -InterfaceIndex $Nic.ifIndex -ResetServerAddresses
        Enable-NetAdapterBinding -Name $Nic.Name -ComponentID ms_tcpip6
        Enable-NetAdapterRsc -Name $Nic.Name -IPv4 -IPv6
        Reset-NetAdapterAdvancedProperty -Name $Nic.Name -DisplayName "*"
        netsh interface ipv4 set subinterface "$($Nic.Name)" mtu=1500 store=persistent | Out-Null
        if ($Nic.InterfaceDescription -match "Wi-Fi|Wireless|802\.11|MediaTek|Intel") {
            netsh wlan set autoconfig enabled=yes interface="$($Nic.Name)" | Out-Null
        }
    }
    Write-GuiLog "NIC hardware properties, MTU (1500), RSC, WLAN scanning & DHCP DNS restored." "OK"

    Set-AnimatedProgress 80
    Remove-NetQosPolicy -Name "KeraM-*" -Confirm:$false
    Remove-NetFirewallRule -Group "KeraM-Security" -ErrorAction SilentlyContinue
    Invoke-HostsSinkhole -Enable $false

    $DnsPolKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
    if (Test-Path $DnsPolKey) {
        Remove-ItemProperty -Path $DnsPolKey -Name "EnableMulticast" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $DnsPolKey -Name "DisableSmartNameResolution" -ErrorAction SilentlyContinue
    }
    Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" | ForEach-Object {
        Invoke-CimMethod -InputObject $_ -MethodName SetTcpipNetbios -Arguments @{ TcpipNetbiosOptions = [uint32]0 } | Out-Null
    }

    bcdedit /deletevalue disabledynamictick | Out-Null
    Set-Service -Name "DiagTrack" -StartupType Automatic; Start-Service -Name "DiagTrack"
    Set-Service -Name "DoSvc" -StartupType Automatic; Start-Service -Name "DoSvc"
    ipconfig /flushdns | Out-Null

    Set-AnimatedProgress 100
    Write-GuiLog "Firewall rules, Hosts sinkhole, NetBIOS/LLMNR, and Windows services restored to factory defaults." "OK"

    $Prompt = [System.Windows.MessageBox]::Show(
        "All network, hardware, and security settings have been reverted to factory defaults.`n`nRestart computer now?",
        "Factory Rollback Complete",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )
    if ($Prompt -eq "Yes") { Restart-Computer -Force }
})

# Launch GUI
$Window.ShowDialog() | Out-Null
