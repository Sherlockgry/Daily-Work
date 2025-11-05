param(
  [string]$Root = "."
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Resolve-Path $Root
Set-Location $root
New-Item -ItemType Directory -Force -Path .\assets | Out-Null

# 日志
$log = Join-Path $root "migration.log"
"== Typora migration started: $(Get-Date -Format s) ==" | Out-File $log -Encoding UTF8

# 1) 移动图片/附件到 assets（避免覆盖，自动重命名）
$exts = @('png','jpg','jpeg','gif','svg','bmp','webp','tif','tiff','pdf','mp4')
Get-ChildItem -Recurse -File | Where-Object {
  $ext = $_.Extension.TrimStart('.').ToLower()
  ($exts -contains $ext) -and
  ($_.FullName -notmatch '\\\.git\\') -and
  ($_.FullName -notmatch '\\assets\\')
} | ForEach-Object {
  $base = $_.Name
  $dest = Join-Path .\assets $base
  $i = 1
  while (Test-Path $dest) {
    $dest = Join-Path .\assets ("{0}_{1}" -f $i, $base)
    $i++
  }
  Move-Item $_.FullName $dest
  "MOVE: `"$($_.FullName)`" -> `"$dest`"" | Out-File $log -Append -Encoding UTF8
}

# 2) 改写 Markdown 中的本地图片链接为 assets/xxx
$mds = Get-ChildItem -Recurse -Filter *.md
foreach ($md in $mds) {
  $txt = Get-Content $md.FullName -Raw -Encoding UTF8

  # ![alt](url)
  $txt = [Regex]::Replace($txt, '!\[([^\]]*)\]\(([^)]+)\)', {
    param($m)
    $alt = $m.Groups[1].Value
    $url = $m.Groups[2].Value.Trim()
    if ($url -match '^(https?:)?//') { return $m.Value }            # 保留 http(s)
    $name = [System.IO.Path]::GetFileName($url)
    "REWRITE: $($md.FullName) : $url -> assets/$name" | Out-File $log -Append -Encoding UTF8
    return "![${alt}](assets/${name})"
  })

  # <img src="url">
  $txt = [Regex]::Replace($txt, '(<img[^>]*?\bsrc=["''])([^"''>]+)(["''][^>]*>)', {
    param($m)
    $pre = $m.Groups[1].Value; $url = $m.Groups[2].Value.Trim(); $post = $m.Groups[3].Value
    if ($url -match '^(https?:)?//') { return $m.Value }
    $name = [System.IO.Path]::GetFileName($url)
    "REWRITE: $($md.FullName) : $url -> assets/$name" | Out-File $log -Append -Encoding UTF8
    return "${pre}assets/${name}${post}"
  }, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

  Set-Content -Path $md.FullName -Value $txt -Encoding UTF8
}

"== Completed: $(Get-Date -Format s) ==" | Out-File $log -Append -Encoding UTF8
