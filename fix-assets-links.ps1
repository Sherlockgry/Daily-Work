param([string]$Root=".")

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root   = Resolve-Path $Root
Set-Location $root
$assets = Join-Path $root "assets"
$log    = Join-Path $root "migration.log"

# 1) 从 migration.log 构建 “旧名 -> 新名” 映射
$map = @{}
if (Test-Path $log) {
  Get-Content $log -Encoding UTF8 | ForEach-Object {
    if ($_ -match 'MOVE:\s+"(.+?)"\s+->\s+"(.+?)"') {
      $src=$matches[1]; $dst=$matches[2]
      $sb=[IO.Path]::GetFileName($src)
      $db=[IO.Path]::GetFileName($dst)
      if ($sb -ne $db) { $map[$sb]=$db }
    }
  }
}

# 2) 补充：检测 assets 中形如 “数字_旧名” 的重命名
if (Test-Path $assets) {
  foreach ($f in Get-ChildItem -LiteralPath $assets -File) {
    if ($f.Name -match '^\d+_(.+)$') {
      $orig=$Matches[1]
      if (-not $map.ContainsKey($orig)) { $map[$orig]=$f.Name }
    }
  }
}

function Fix-MdFile([string]$mdPath) {
  $txt = Get-Content -LiteralPath $mdPath -Raw -Encoding UTF8
  $changed = $false

  # Markdown 语法
  $txt = [Regex]::Replace($txt, '!\[([^\]]*)\]\((assets\/[^)]+)\)', {
    param($m)
    $alt=$m.Groups[1].Value; $url=$m.Groups[2].Value
    $base=[IO.Path]::GetFileName($url)
    $full=Join-Path $root $url
    if (Test-Path -LiteralPath $full) { return $m.Value } # 已存在

    if ($map.ContainsKey($base)) {
      $changed = $true
      return "![${alt}](assets/$($map[$base]))"
    }
    $cand = @(Get-ChildItem -LiteralPath $assets -File -Filter "*_$base" -ErrorAction SilentlyContinue)
    if ($cand.Length -eq 1) {
      $changed = $true
      return "![${alt}](assets/$($cand[0].Name))"
    }
    return $m.Value
  })

  # HTML <img src="">
  $txt = [Regex]::Replace($txt, '(<img[^>]*?\bsrc=["''])(assets\/[^"''>]+)(["''][^>]*>)', {
    param($m)
    $pre=$m.Groups[1].Value; $url=$m.Groups[2].Value; $post=$m.Groups[3].Value
    $base=[IO.Path]::GetFileName($url)
    $full=Join-Path $root $url
    if (Test-Path -LiteralPath $full) { return $m.Value }

    if ($map.ContainsKey($base)) {
      $changed = $true
      return "${pre}assets/$($map[$base])${post}"
    }
    $cand = @(Get-ChildItem -LiteralPath $assets -File -Filter "*_$base" -ErrorAction SilentlyContinue)
    if ($cand.Length -eq 1) {
      $changed = $true
      return "${pre}assets/$($cand[0].Name)${post}"
    }
    return $m.Value
  }, [Text.RegularExpressions.RegexOptions]::IgnoreCase)

  if ($changed) {
    Set-Content -LiteralPath $mdPath -Value $txt -Encoding UTF8
    "FIXED: $mdPath"
  }
}

# 执行修复
Get-ChildItem -Recurse -Filter *.md | ForEach-Object { Fix-MdFile $_.FullName }

# 3) 报告仍缺失的引用
$missing = @()
foreach ($md in Get-ChildItem -Recurse -Filter *.md) {
  $t = Get-Content -LiteralPath $md.FullName -Raw -Encoding UTF8
  $matches = [Regex]::Matches($t, 'assets\/[^)>"'']+', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
  foreach ($mm in $matches) {
    $rel=$mm.Value; $full=Join-Path $root $rel
    if (-not (Test-Path -LiteralPath $full)) { $missing += "$($md.Name) -> $rel" }
  }
}
if ($missing.Count -gt 0) {
  "Missing assets after fix:"
  $missing | Sort-Object -Unique
} else {
  "All assets resolved."
}
