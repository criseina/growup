param(
  [string]$Flutter = 'flutter',
  [string]$Adb = '',
  [int]$Rounds = 2,
  [switch]$SkipDevice
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$outputDir = Join-Path $projectRoot "build\avatar_qc\$stamp"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
$reportPath = Join-Path $outputDir 'report.txt'

function Write-Report([string]$Message) {
  $Message | Tee-Object -FilePath $reportPath -Append
}

function Run-Step([string]$Name, [scriptblock]$Action) {
  Write-Report ""
  Write-Report "[$Name]"
  & $Action 2>&1 | Tee-Object -FilePath $reportPath -Append
  if ($LASTEXITCODE -ne 0) {
    throw "$Name failed with exit code $LASTEXITCODE"
  }
}

Set-Location $projectRoot
Write-Report 'GrowUp Avatar QC Loop'
Write-Report "Started: $(Get-Date -Format o)"
Write-Report "Rounds: $Rounds"

for ($round = 1; $round -le $Rounds; $round++) {
  Write-Report ""
  Write-Report "========== ROUND $round / $Rounds =========="
  Run-Step 'Static analysis' { & $Flutter --no-version-check analyze }
  Run-Step 'Avatar structural critic' {
    & $Flutter --no-version-check test test\widget_test.dart --plain-name 'avatar QC loop keeps every room above the release threshold'
  }
}

Run-Step 'Integrated regression suite' { & $Flutter --no-version-check test }
Run-Step 'QC-enabled Android profile build' {
  & $Flutter --no-version-check build apk --profile --dart-define=AVATAR_QC=true
}

if (-not $SkipDevice) {
  if (-not $Adb) {
    $sdkAdb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
    if (Test-Path -LiteralPath $sdkAdb) { $Adb = $sdkAdb }
  }
  if ($Adb -and (Test-Path -LiteralPath $Adb)) {
    $device = (& $Adb devices | Select-String '^emulator-\d+\s+device$' | Select-Object -First 1)
    if ($device) {
      $serial = $device.ToString().Split()[0]
      $apk = Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-profile.apk'
      Run-Step 'Emulator install' { & $Adb -s $serial install -r $apk }
      & $Adb -s $serial shell am force-stop com.criseina.growup | Out-Null
      & $Adb -s $serial shell monkey -p com.criseina.growup -c android.intent.category.LAUNCHER 1 | Out-Null
      Start-Sleep -Seconds 8
      $appPid = (& $Adb -s $serial shell pidof com.criseina.growup).Trim()
      if (-not $appPid) { throw 'GrowUp profile app did not start' }
      & $Adb -s $serial shell dumpsys gfxinfo com.criseina.growup reset | Out-Null
      & $Adb -s $serial shell input tap 205 580 | Out-Null
      Start-Sleep -Seconds 3
      for ($index = 0; $index -lt 6; $index++) {
        & $Adb -s $serial shell input tap 245 315 | Out-Null
        Start-Sleep -Seconds 2
        $remote = "/sdcard/growup-avatar-$index.png"
        $local = Join-Path $outputDir ("room-{0:D2}.png" -f ($index + 1))
        & $Adb -s $serial shell screencap -p $remote | Out-Null
        & $Adb -s $serial pull $remote $local | Out-Null
        if ((Get-Item -LiteralPath $local).Length -lt 10000) {
          throw "Room screenshot $index is unexpectedly small"
        }
        if ($index -lt 5) {
          & $Adb -s $serial shell input swipe 285 300 45 300 500 | Out-Null
          Start-Sleep -Seconds 1
        }
      }
      & $Adb -s $serial shell input tap 248 56 | Out-Null
      Start-Sleep -Seconds 2
      & $Adb -s $serial shell screencap -p /sdcard/growup-avatar-qc.png | Out-Null
      & $Adb -s $serial pull /sdcard/growup-avatar-qc.png (Join-Path $outputDir 'qc-panel.png') | Out-Null
      $gfx = & $Adb -s $serial shell dumpsys gfxinfo com.criseina.growup
      $gfx | Set-Content -LiteralPath (Join-Path $outputDir 'gfxinfo.txt')
      $jank = $gfx | Select-String 'Janky frames:' | Select-Object -First 1
      Write-Report "Device performance: $jank"
      Write-Report 'Flutter performance: see qc-panel.png (FrameTiming source)'
    } else {
      Write-Report 'Device performance: SKIPPED (no booted emulator)'
    }
  } else {
    Write-Report 'Device performance: SKIPPED (adb not found)'
  }
}

Write-Report ''
Write-Report 'RESULT: PASS'
Write-Report "Finished: $(Get-Date -Format o)"
Write-Output "Avatar QC report: $reportPath"
