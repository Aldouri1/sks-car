$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$desktop = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktop "SKS Car.lnk"
$targetExe = Join-Path $root "SKS-Car.exe"
$iconPath = Join-Path $root "icons\sks-car.ico"

$wsh = New-Object -ComObject WScript.Shell
$shortcut = $wsh.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $targetExe
$shortcut.WorkingDirectory = $root
$shortcut.Description = "SKS Car - نظام إدارة خدمات السيارات والعقود المرورية"
if (Test-Path $iconPath) {
  $shortcut.IconLocation = $iconPath
}
$shortcut.Save()

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "  تم إنشاء أيقونة برنامج SKS Car على سطح المكتب بنجاح!" -ForegroundColor Green
Write-Host "  المسار: $shortcutPath" -ForegroundColor White
Write-Host "=================================================" -ForegroundColor Cyan
