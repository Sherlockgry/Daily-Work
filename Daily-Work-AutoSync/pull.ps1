# pull.ps1 —— 一键拉取更新（适合双击或由 Pull-Daily-Work.bat 调用）
param([switch]$NoStashPop)  # 如遇复杂冲突：.\pull.ps1 -NoStashPop

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Info($msg){ Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Warn($msg){ Write-Warning $msg }
function Die($msg){ Write-Host "[ERROR] $msg" -ForegroundColor Red; exit 1 }

# 进入仓库根目录（脚本所在目录）
$root = Split-Path -LiteralPath $MyInvocation.MyCommand.Path -Parent
Set-Location $root

# 基础检查
& git rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) { Die "当前目录不是 Git 仓库：$root" }

# 建议的仓库内配置
git config pull.rebase true      *> $null
git config rebase.autostash true *> $null
git config core.autocrlf false   *> $null
git config core.safecrlf false   *> $null

Info "检查工作区状态…"
$dirty = (git status --porcelain)

$needFallback = $false
try {
  Info "执行：git -c rebase.autostash=true pull --rebase origin main"
  & git -c rebase.autostash=true pull --rebase origin main
} catch {
  $needFallback = $true
}

if ($needFallback -and $dirty) {
  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  Info "autostash 失败，改用手动 stash：git stash push -u -m 'WIP $ts (auto before pull)'"
  & git stash push -u -m "WIP $ts (auto before pull)" | Out-Null

  Info "再次拉取：git pull --rebase origin main"
  & git pull --rebase origin main

  if (-not $NoStashPop) {
    Info "恢复暂存改动：git stash pop"
    & git stash pop
    if ($LASTEXITCODE -ne 0) {
      Warn "stash pop 发生冲突，请手动解决后 `git add -A`，然后 `git rebase --continue` 或 `git commit --no-edit`。"
    }
  } else {
    Warn "已保留 stash，请稍后 `git stash list` / `git stash pop` 自行处理。"
  }
}

Info "完成。当前分支：$(git rev-parse --abbrev-ref HEAD)"
git status --short