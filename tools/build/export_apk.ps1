# 自动导出 Android APK
# 用法：
#   .\tools\build\export_apk.ps1                  # debug 默认
#   .\tools\build\export_apk.ps1 -Mode release    # release（需配 release keystore）
#   .\tools\build\export_apk.ps1 -BumpVersion     # 自动 +1 version code

param(
    [ValidateSet("debug", "release")]
    [string]$Mode = "debug",
    [switch]$BumpVersion,
    [string]$GodotExe = "godot",
    [string]$PresetName = "Android",
    [string]$OutDir = "build"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $ProjectRoot

# 创建输出目录
$null = New-Item -ItemType Directory -Force -Path $OutDir

# 版本号 +1（可选）
if ($BumpVersion) {
    $cfg = Get-Content "export_presets.cfg" -Raw -Encoding utf8
    $match = [regex]::Match($cfg, "version/code=(\d+)")
    if ($match.Success) {
        $newCode = [int]$match.Groups[1].Value + 1
        $cfg = $cfg -replace "version/code=\d+", "version/code=$newCode"
        Set-Content "export_presets.cfg" $cfg -Encoding utf8 -NoNewline
        Write-Host "version/code bumped to $newCode" -ForegroundColor Cyan
    }
}

# 时间戳 + 模式后缀
$stamp = Get-Date -Format "yyyyMMdd-HHmm"
$outFile = Join-Path $OutDir "xiaogouxiuxian-$Mode-$stamp.apk"

# 导出
$exportFlag = if ($Mode -eq "release") { "--export-release" } else { "--export-debug" }
Write-Host "→ exporting [$Mode] $PresetName → $outFile" -ForegroundColor Yellow
& $GodotExe --headless --path $ProjectRoot $exportFlag $PresetName $outFile
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ export failed (exit $LASTEXITCODE)" -ForegroundColor Red
    exit $LASTEXITCODE
}

# 校验输出
if (-not (Test-Path $outFile)) {
    Write-Host "✗ APK not produced at $outFile" -ForegroundColor Red
    exit 1
}
$size = [math]::Round((Get-Item $outFile).Length / 1MB, 2)
Write-Host "✓ APK: $outFile ($size MB)" -ForegroundColor Green
