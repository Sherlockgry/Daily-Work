# push.ps1 —— 一键提交并推送（适合双击或由 Push-Daily-Work.bat 调用）
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Info($msg){ Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Warn($msg){ Write-Warning $msg }
function Die($msg){ Write-Host "[ERROR] $msg" -ForegroundColor Red; exit 1 }

$root = Split-Path -LiteralPath $MyInvocation.MyCommand.Path -Parent
Set-Location $root

& git rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) { Die "当前目录不是 Git 仓库：$root" }

# 建议的仓库内配置
git config pull.rebase true      *> $null
git config rebase.autostash true *> $null
git config core.autocrlf false   *> $null
git config core.safecrlf false   *> $null

# 1) 预先同步远端，减少拒推
Info "预同步：git -c rebase.autostash=true pull --rebase origin main"
try { & git -c rebase.autostash=true pull --rebase origin main } catch { Warn "预同步失败，将继续尝试提交与推送…" }

# 2) 可选：修复本地图片链接（若仓库存在此脚本）
if (Test-Path "$root\fix-assets-links.ps1") {
  Info "执行修复脚本：fix-assets-links.ps1"
  & powershell -NoProfile -ExecutionPolicy Bypass -File "$root\fix-assets-links.ps1"
}

# 3) 有改动才提交
$needCommit = (git status --porcelain)
if ($needCommit) {
  Info "发现改动，开始提交…"
  & git add -A
  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  & git commit -m "docs: $ts 更新"
} else {
  Info "无需提交（无改动）。"
}

# 4) 推送；如被拒，自动 rebase 后重试一次
function TryPush(){
  Info "执行：git push origin main"
  & git push origin main
  return $LASTEXITCODE
}

if ( (TryPush) -ne 0 ) {
  Warn "push 被拒，尝试：git pull --rebase origin main 后重推…"
  & git pull --rebase origin main
  if ( (TryPush) -ne 0 ) {
    Die "推送仍失败。请执行 `git status` 查看冲突或权限问题。"
  }
}

Info "推送完成。当前分支：$(git rev-parse --abbrev-ref HEAD)"
git status --short