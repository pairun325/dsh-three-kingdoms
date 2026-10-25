param(
  [string]$File = (Join-Path $PSScriptRoot '..\media\guanyu.mp3'),
  [int]$TimeoutSeconds = 0
)
# 静静地放一段本地音频：无窗口、不抢焦点，放完自己退出。
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationCore, WindowsBase, PresentationFramework

$player = New-Object System.Windows.Media.MediaPlayer
$player.Open([Uri]::new((Resolve-Path $File).Path))
$player.Volume = 1.0
$player.Play()

$deadline = if ($TimeoutSeconds -gt 0) { (Get-Date).AddSeconds($TimeoutSeconds) } else { [DateTime]::MaxValue }
while ($true) {
  [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke(
    [System.Windows.Threading.DispatcherPriority]::Background,
    [action] { }
  )
  Start-Sleep -Milliseconds 120
  if ($player.NaturalDuration.HasTimeSpan -and $player.Position -ge $player.NaturalDuration.TimeSpan) { break }
  if ((Get-Date) -ge $deadline) { break }
}
$player.Stop()
$player.Close()
