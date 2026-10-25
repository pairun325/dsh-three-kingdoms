param(
  [string]$TaskName = 'dsh-game-music'
)
# 装一次：把监测挂成开机自启的计划任务。
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$watch = Join-Path $here 'helper\watch.ps1'

# 本地音频（不进仓库，自己下）
$media = Join-Path $here 'media\guanyu.mp3'
if (-not (Test-Path $media)) {
  New-Item -ItemType Directory -Path (Split-Path $media) -Force | Out-Null
  Write-Host "下载《关羽之歌》…"
  try {
    Invoke-WebRequest -UseBasicParsing -Uri 'https://music.163.com/song/media/outer/url?id=1349225260.mp3' -OutFile $media -TimeoutSec 60
    Write-Host ("音频就位：" + $media)
  } catch {
    Write-Warning "自动下载失败，请手动放一个 mp3 到 media\guanyu.mp3"
  }
}

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "{0}"' -f $watch)
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartCount 2 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description '一进游戏就放《关羽之歌》并出字' -Force | Out-Null
Start-ScheduledTask -TaskName $TaskName

Write-Host ("已安装计划任务 " + $TaskName + "（开机自启，现在已启动）")
Write-Host ("卸载：Unregister-ScheduledTask -TaskName " + $TaskName + " -Confirm:`$false")
