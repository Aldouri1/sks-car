$port = 8095
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$stateFile = Join-Path $root "live-state.json"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
try {
  $listener.Start()
} catch {
  # Server is likely already running on port 8095
  exit 0
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "  SKS Car - System Server (PWA & Desktop App Mode)" -ForegroundColor White
Write-Host "  Running at: http://localhost:$port" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Cyan

$mimeTypes = @{
  ".html" = "text/html; charset=utf-8"
  ".css"  = "text/css; charset=utf-8"
  ".js"   = "application/javascript; charset=utf-8"
  ".json" = "application/json; charset=utf-8"
  ".svg"  = "image/svg+xml"
  ".png"  = "image/png"
  ".ico"  = "image/x-icon"
}

try {
  while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response
    $response.Headers.Add("Access-Control-Allow-Origin", "*")
    $response.Headers.Add("Cache-Control", "no-cache")

    $relPath = $request.Url.LocalPath.TrimStart('/')

    if ($relPath -eq "api/state") {
      if ($request.HttpMethod -eq "POST") {
        $reader = New-Object System.IO.StreamReader($request.InputStream, [System.Text.Encoding]::UTF8)
        $body = $reader.ReadToEnd()
        $reader.Close()
        [System.IO.File]::WriteAllText($stateFile, $body, [System.Text.Encoding]::UTF8)
        $bytes = [System.Text.Encoding]::UTF8.GetBytes('{"ok":true}')
        $response.ContentType = "application/json; charset=utf-8"
        $response.ContentLength64 = $bytes.Length
        $response.StatusCode = 200
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
      } else {
        if (Test-Path $stateFile) {
          $bytes = [System.IO.File]::ReadAllBytes($stateFile)
        } else {
          $bytes = [System.Text.Encoding]::UTF8.GetBytes('{}')
        }
        $response.ContentType = "application/json; charset=utf-8"
        $response.ContentLength64 = $bytes.Length
        $response.StatusCode = 200
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
      }
      $response.OutputStream.Close()
      continue
    }

    if ([string]::IsNullOrWhiteSpace($relPath)) { $relPath = "index.html" }
    $filePath = Join-Path $root ($relPath -replace '/', '\')

    if (Test-Path $filePath -PathType Leaf) {
      $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
      $response.ContentType = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { "application/octet-stream" }
      if ($relPath -eq "sw.js") {
        $response.Headers.Add("Service-Worker-Allowed", "/")
      }
      $bytes = [System.IO.File]::ReadAllBytes($filePath)
      $response.ContentLength64 = $bytes.Length
      $response.StatusCode = 200
      $response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $response.StatusCode = 404
    }
    $response.OutputStream.Close()
  }
} finally {
  $listener.Stop()
}
