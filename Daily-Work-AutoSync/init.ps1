# init.ps1 —— 一键初始化/修复当前设备上的仓库环境
# 作用：
#  - 设置推荐的本地仓库配置（rebase/autostash、换行策略等）
#  -（可选）设置 origin 远端（若不存在则提示输入 SSH/HTTPS 地址）
#  - 校验 SSH 连通性（如远端为 SSH）
#  - 首次拉取并 rebase
#  - 安装一键脚本（本包已包含，无需额外安装）

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Info($msg){ Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Warn($msg){ Write-Warning $msg }
function Die($msg){ Write-Host "[ERROR] $msg" -ForegroundColor Red; exit 1 }

$root = Split-Path -LiteralPath $MyInvocation.MyCommand.Path -Parent
Set-Location $root

# 基础检查
try { & git --version | Out-Null } catch { Die "未检测到 Git。请先安装 Git for Windows 后重试。" }
& git rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) { Die "当前目录不是 Git 仓库：$root" }

# 推荐仓库配置
Info "写入本地仓库配置…"
git config pull.rebase true      *> $null
git config rebase.autostash true *> $null
git config core.autocrlf false   *> $null
git config core.safecrlf false   *> $null
git config fetch.prune true      *> $null

# 统一主分支名
$cur = (git rev-parse --abbrev-ref HEAD).Trim()
if ($cur -ne "main") {
  Info "将当前分支重命名为 main（原：$cur）"
  & git branch -M main
}

# 远端配置
$hasOrigin = $false
try {
  $rv = git remote get-url origin 2>$null
  if ($LASTEXITCODE -eq 0 -and $rv) { $hasOrigin = $true }
} catch { }

if (-not $hasOrigin) {
  Warn "未检测到远端 origin。"
  $url = Read-Host "请输入 GitHub 仓库地址（建议 SSH，如：git@github.com:Sherlockgry/Daily-Work.git）"
  if (-not $url) { Die "未提供远端地址，初始化中止。" }
  & git remote add origin $url
  Info "已添加 origin：$url"
} else {
  Info "检测到 origin：$(git remote get-url origin)"
}

# 如为 SSH 远端，则快速连通性测试（非致命）
$originUrl = (git remote get-url origin)
if ($originUrl -match '^git@github\.com:') {
  Info "检测 SSH 连通性（若提示成功认证即正常）…"
  try { ssh -T git@github.com } catch { Warn "SSH 连通性测试出现异常，可稍后重试。" }
}

# 初次拉取（带 autostash）
Info "执行：git -c rebase.autostash=true pull --rebase origin main"
try {
  & git -c rebase.autostash=true pull --rebase origin main
} catch {
  Warn "自动拉取失败。尝试手动 stash 后再次拉取…"
  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  & git stash push -u -m "WIP $ts (auto before first pull)" | Out-Null
  & git pull --rebase origin main
  Info "恢复暂存改动：git stash pop（如冲突请按提示处理）"
  & git stash pop
}

Info "初始化完成。之后可直接双击：Pull-Daily-Work.bat / Push-Daily-Work.bat"
git status --short