param([int]$IntervalMs = 2000)
# 盯游戏：一有游戏跑到前台（或进入 D3D 全屏）就吐一行 JSON。
$ErrorActionPreference = 'SilentlyContinue'

Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;

public static class GameWatch {
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern int GetWindowThreadProcessId(IntPtr hWnd, out int pid);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr hWnd, StringBuilder text, int max);
  [DllImport("shell32.dll")] public static extern int SHQueryUserNotificationState(out int state);

  public static string ForegroundProcess() {
    IntPtr h = GetForegroundWindow();
    int pid;
    GetWindowThreadProcessId(h, out pid);
    try { return System.Diagnostics.Process.GetProcessById(pid).ProcessName; } catch { return ""; }
  }
  public static string ForegroundTitle() {
    IntPtr h = GetForegroundWindow();
    var sb = new StringBuilder(512);
    GetWindowTextW(h, sb, 512);
    return sb.ToString();
  }
  public static int NotificationState() {
    int s;
    SHQueryUserNotificationState(out s);
    return s;
  }
}
'@

$gamePatterns = @(
  'minecraft', 'javaw', 'hoi4', 'stellaris', 'ck3', 'eu4', 'victoria3', 'imperator',
  'game', 'gamemd', 'ra2', 'yuri', 'exefile', 'evelauncher', 'eve',
  'witcher', 'cyberpunk', 'eldenring', 'sekiro', 'darksouls', 'skyrim', 'fallout',
  'gta', 'rdr2', 'gtav', 'hl2', 'cs2', 'csgo', 'dota2', 'valorant', 'league'
)
$titlePatterns = @(
  'Minecraft', 'Red Alert', 'Hearts of Iron', '星战前夜', 'EVE Online', 'Crusader Kings',
  'Stellaris', 'Europa Universalis', 'Victoria', 'Total War', '三国', 'Age of Empires',
  'Command & Conquer', 'Warcraft', 'StarCraft', 'Diablo', '艾尔登', '原神', '崩坏',
  'Cyberpunk', 'Witcher', 'GTA', 'Red Dead', 'Civili[sz]ation', 'Frostpunk', 'Cities: Skylines'
)
$ignorePatterns = @('explorer', 'dsh', 'deepseek', 'steam', 'steamwebhelper', 'wallpaper64', 'wallpaper32', 'cloudmusic', 'chrome', 'msedge', 'firefox', 'code', 'powershell', 'pwsh', 'node')

$last = ''
while ($true) {
  $proc = [GameWatch]::ForegroundProcess()
  $title = [GameWatch]::ForegroundTitle()
  $state = [GameWatch]::NotificationState()

  $isGame = $false
  if ($proc -ne '' -and -not ($ignorePatterns | Where-Object { $proc -like "*$_*" })) {
    foreach ($p in $gamePatterns) {
      if ($proc -eq $p -or $proc -like "*$p*") { $isGame = $true; break }
    }
  }
  if (-not $isGame -and $title -ne '') {
    foreach ($t in $titlePatterns) {
      if ($title -match $t) { $isGame = $true; break }
    }
  }

  # 前台不是游戏也不要紧：后台任何一个窗口像游戏就算（全屏、或名字对得上）
  if (-not $isGame) {
    $candidates = Get-Process -ErrorAction SilentlyContinue | Where-Object {
      $_.MainWindowHandle -ne 0 -and $_ -and $_.MainWindowTitle -ne ''
    }
    foreach ($cand in $candidates) {
      $cname = $cand.ProcessName
      if ($ignorePatterns | Where-Object { $cname -like "*$_*" }) { continue }
      $hit = $false
      foreach ($p in $gamePatterns) { if ($cname -eq $p -or $cname -like "*$p*") { $hit = $true; break } }
      if (-not $hit) {
        foreach ($t in $titlePatterns) { if ($cand.MainWindowTitle -match $t) { $hit = $true; break } }
      }
      if ($hit) {
        $isGame = $true
        $proc = $cname
        $title = $cand.MainWindowTitle
        break
      }
    }
  }

  if (-not $isGame -and $state -eq 3 -and $proc -ne '') {
    # QUNS_RUNNING_D3D_FULL_SCREEN：独占全屏的前台程序，基本就是游戏
    if (-not ($ignorePatterns | Where-Object { $proc -like "*$_*" })) { $isGame = $true }
  }

  $key = if ($isGame) { "game:$proc" } else { 'idle' }
  if ($key -ne $last) {
    $last = $key
    $payload = [ordered]@{
      event = if ($isGame) { 'game' } else { 'idle' }
      proc  = $proc
      title = $title
      state = $state
      at    = (Get-Date).ToString('o')
    }
    Write-Output ($payload | ConvertTo-Json -Compress)
    [Console]::Out.Flush()

    if ($isGame) {
      # 一进游戏：放歌 + 出字。两个都丢给子进程，不阻塞监测。
      $here = $PSScriptRoot
      $logDir = Join-Path $env:TEMP 'dsh-three-kingdoms'
      if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
      $log = Join-Path $logDir 'watch.log'
      try {
        Start-Process -FilePath 'powershell' -WindowStyle Hidden -ArgumentList @(
          '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $here 'play.ps1')
        ) | Out-Null
        Add-Content -Path $log -Value ("{0} play.ps1 launched for {1}" -f (Get-Date).ToString('s'), $proc)
        Start-Process -FilePath 'powershell' -WindowStyle Hidden -ArgumentList @(
          '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $here 'show-art.ps1'), '-Seconds', '14'
        ) | Out-Null
        Add-Content -Path $log -Value ("{0} show-art.ps1 launched" -f (Get-Date).ToString('s'))
      } catch {
        Add-Content -Path $log -Value ("{0} ERROR {1}" -f (Get-Date).ToString('s'), $_.Exception.Message)
      }
    }
  }
  Start-Sleep -Milliseconds $IntervalMs
}
