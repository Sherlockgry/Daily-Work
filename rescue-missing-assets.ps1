param([string]$Root=".", [string[]]$SearchRoots)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root   = (Resolve-Path $Root).Path
$assets = Join-Path $root "assets"
if (-not (Test-Path -LiteralPath $assets)) { New-Item -ItemType Directory -Path $assets | Out-Null }

# 1) 收集 .md 中指向 assets/ 的资源，挑出缺失项
$missing = [System.Collections.Generic.HashSet[string]]::new()
foreach ($md in Get-ChildItem -Recurse -Filter *.md) {
  $t  = Get-Content -LiteralPath $md.FullName -Raw -Encoding UTF8
  $ms = [Regex]::Matches($t, 'assets\/[^)>"'']+', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
  foreach ($m in $ms) {
    $rel  = $m.Value
    $full = Join-Path $root $rel
    if (-not (Test-Path -LiteralPath $full)) {
      $missing.Add([IO.Path]::GetFileName($rel)) | Out-Null
    }
  }
}
if ($missing.Count -eq 0) { "No missing assets detected."; exit 0 }

"Missing filenames (unique): $($missing.Count)"
$missing | Sort-Object | ForEach-Object { " - $_" }

# 2) 设定搜索根（默认：用户目录常见位置 + Typora 缓存）
if (-not $SearchRoots -or $SearchRoots.Count -eq 0) {
  $userHome = $env:USERPROFILE
  $appdata  = $env:APPDATA
  $localapp = $env:LOCALAPPDATA
  $cands = @(
    (Join-Path $userHome "Documents"),
    (Join-Path $userHome "Desktop"),
    (Join-Path $userHome "Downloads"),
    (Join-Path $userHome "Pictures"),
    (Join-Path $userHome "OneDrive"),
    (Join-Path $userHome "OneDrive\图片"),
    (Join-Path $userHome "OneDrive\文档"),
    (Join-Path $appdata  "Typora"),
    (Join-Path $appdata  "Typora\typora-user-images"),
    (Join-Path $localapp "Typora")
  )
  $SearchRoots = @($cands | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -Unique)
}
"Search roots:"; $SearchRoots | ForEach-Object { " - $_" }

# 3) 搜索并复制
$copied = 0; $notfound = @()
foreach ($name in $missing) {
  $hits = @()
  foreach ($sr in $SearchRoots) {
    $hits += Get-ChildItem -Path $sr -Recurse -File -Filter $name -ErrorAction SilentlyContinue
  }
  if ($hits.Count -eq 1) {
    $src = $hits[0].FullName
  } elseif ($hits.Count -gt 1) {
    $src = ($hits | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
    "AMBIGUOUS: $name -> using newest: $src"
  } else {
    # 模糊匹配：按不含扩展名的 stem 搜索
    $stem = [IO.Path]::GetFileNameWithoutExtension($name)
    $ext  = [IO.Path]::GetExtension($name)
    foreach ($sr in $SearchRoots) {
      $hits += Get-ChildItem -Path $sr -Recurse -File -ErrorAction SilentlyContinue |
               Where-Object { $_.Name -like "*$stem*$ext" }
    }
    if ($hits.Count -gt 0) {
      $src = ($hits | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
      "FUZZY: $name -> using: $src"
    } else { $notfound += $name; continue }
  }
  $dst = Join-Path $assets $name
  if (-not (Test-Path -LiteralPath $dst)) {
    Copy-Item -LiteralPath $src -Destination $dst
    "COPIED: $src -> $dst"; $copied++
  }
}
"Copied: $copied file(s)."

# 4) 终末校验
$stillMissing = @()
foreach ($fn in $missing) {
  $full = Join-Path $assets $fn
  if (-not (Test-Path -LiteralPath $full)) { $stillMissing += $fn }
}
if ($stillMissing.Count -gt 0) {
  "Still missing:"; $stillMissing | Sort-Object
} else { "All assets resolved." }
