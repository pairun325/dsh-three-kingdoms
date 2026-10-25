param(
  [string]$Text = "胜    兵    必     骄`n必                    兵`n兵                    必`n哀    必    兵     败",
  [int]$Seconds = 14
)
# 在屏幕上方浮一块字：不抢焦点、鼠标穿透、几秒后自己消失。
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        Topmost="True" ShowInTaskbar="False" ResizeMode="NoResize"
        SizeToContent="WidthAndHeight" ShowActivated="False">
  <Grid>
    <Border Background="#D9070D18" CornerRadius="22" Padding="54,34"
            BorderBrush="#55A8C8FF" BorderThickness="1">
      <StackPanel>
        <TextBlock Text="关 羽 之 歌" Foreground="#7FA9DE" FontSize="15" Margin="4,0,0,14"
                   FontFamily="Microsoft YaHei" TextWrapping="NoWrap"/>
        <StackPanel Name="Art"/>
      </StackPanel>
    </Border>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)
$stack = $window.FindName('Art')
foreach ($line in ($Text -split "`n")) {
  $block = New-Object System.Windows.Controls.TextBlock
  $block.Text = $line.TrimEnd()
  $block.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#F4F7FF')
  $block.FontFamily = [System.Windows.Media.FontFamily]::new('Consolas, Microsoft YaHei')
  $block.FontSize = 40
  $block.LineHeight = 62
  $block.LineStackingStrategy = 'BlockLineHeight'
  $block.TextWrapping = 'NoWrap'
  $block.HorizontalAlignment = 'Center'
  [void]$stack.Children.Add($block)
}

$window.Left = [System.Windows.SystemParameters]::PrimaryScreenWidth / 2 - 330
$window.Top = 66
$window.Show()

$deadline = (Get-Date).AddSeconds($Seconds)
while ((Get-Date) -lt $deadline) {
  [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke(
    [System.Windows.Threading.DispatcherPriority]::Background,
    [action] { }
  )
  Start-Sleep -Milliseconds 80
}
$window.Close()
