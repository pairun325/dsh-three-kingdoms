param(
  [string]$File = '',
  [switch]$Force
)
# 进游戏时放《关羽之歌》：优先本地 mp3（稳定、不看客户端脸色），已经在放就不重复开。
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($File)) { $File = Join-Path $here '..\media\guanyu.mp3' }
$logDir = Join-Path $env:TEMP 'dsh-three-kingdoms'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$log = Join-Path $logDir 'play.log'
function Note([string]$m) { Add-Content -Path $log -Value ("{0} {1}" -f (Get-Date).ToString('s'), $m) }

try {
  $resolved = (Resolve-Path $File -ErrorAction Stop).Path
} catch {
  Note "missing media: $File"
  '{"ok":false,"state":"missing","message":"找不到音频文件"}'
  exit 1
}

# 已经在放同一段？
$running = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
  Where-Object { $_.CommandLine -like '*play-local.ps1*' }
if ($running -and -not $Force) {
  Note 'already playing, skip'
  '{"ok":true,"state":"already","action":"none","message":"已经在放了"}'
  exit 0
}

Start-Process -FilePath 'powershell' -WindowStyle Hidden -ArgumentList @(
  '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $here 'play-local.ps1'), '-File', $resolved
) | Out-Null

Note ("launched local playback: " + $resolved)
'{"ok":true,"state":"playing","action":"local","message":"关羽之歌，放了"}'
