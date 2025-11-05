# Daily-Work（Typora 项目 / 双机同步）

本仓库用于日常科研/工程笔记（Typora），统一采用**相对路径**与本地 `assets/` 目录管理图片，保证两台 Windows 设备间一致、可复现。

---

下面给你一份**标准操作流程（SOP）**，每次在 *Daily-Work* 里新增或编辑完内容后，按此同步即可。命令默认在 Windows PowerShell、仓库根目录执行。

---

## 一、常规四步（每次写完就做）

```powershell
# 0) 进入仓库根目录
Set-Location "C:\Users\<YourName>\Documents\Daily-Work"

# 1) 先拉远端，避免非快进冲突
git pull --rebase --autostash origin main

# 2)（可选）快速自查本地图片引用是否都在 assets/
PowerShell -ExecutionPolicy Bypass -File .\fix-assets-links.ps1

# 3) 纳入变更并提交
git add -A
git commit -m "docs: 2025-11-05 更新（<简述本次改动>）"

# 4) 推送
git push origin main
```

> 另一台电脑开始工作前只需：

```powershell
Set-Location "C:\Users\<YourName>\Documents\Daily-Work"
git pull --rebase origin main
```

---

## 二、遇到冲突时

```powershell
# rebase 时如提示冲突：
git status                  # 查看冲突文件
# 用编辑器解决 <<<<<<< ======= >>>>>>> 标记后的差异
git add <冲突文件> ...
git rebase --continue
# 若想放弃 rebase：
# git rebase --abort
```

---

## 三、常见小问题与快速处理

* **图片仍缺失**：
  先跑 `fix-assets-links.ps1`；仍缺则：

  ```powershell
  PowerShell -ExecutionPolicy Bypass -File .\rescue-missing-assets.ps1
  ```

  脚本会在常见目录里搜原图并复制回 `assets/`。

* **提示非快进或有别人先推送**：
  先 `git pull --rebase origin main`，解决冲突后再 `git push origin main`。

* **偶发权限/用户变更导致安全目录报错**（两台机器用户名不同）：

  ```powershell
  git config --global --add safe.directory "C:/Users/<YourName>/Documents/Daily-Work"
  ```

---

## 四、可选：一键提交函数（减少重复输入）

```powershell
function gwc { param([string]$m="update")
  git pull --rebase --autostash origin main
  git add -A
  git commit -m "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m"
  git push origin main
}
# 使用示例：
# gwc "docs: CO2 DIAL 外差检测笔记（补图）"
```

如果希望每次打开 PowerShell 都可用，将上面函数追加进 `$PROFILE`：

```powershell
"function gwc { param([string]`$m=`"update`"); git pull --rebase --autostash origin main; git add -A; git commit -m `"$([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss')) `$m`"; git push origin main }" | Add-Content $PROFILE
```

---

按上述流程执行，你就能在两台电脑之间稳定、可重复地同步 *Typora* 的 `.md` 与 `assets/`。


## 目录结构与约定

```
Daily-Work/
├─ 25.xx.xx*.md                 # 笔记/论文阅读/实验记录
├─ 博士论文阅读.md 等            # 其他笔记
├─ assets/                      # 所有被 md 引用的本地图片/附件
│  └─ image-YYYYMMDDHHmmss*.png
├─ fix-assets-links.ps1         # 修复 md 中旧文件名的本地链接
├─ rescue-missing-assets.ps1    # 搜寻缺失图片并复制回 assets
├─ typora-migrate.ps1           # 可选：批量规范历史资源
├─ .gitignore
└─ README.md
```

**统一约定**：所有 md 中的本地资源链接写成 `assets/<文件名>`；不使用绝对路径或外部盘符。

---

## Typora 设置（两台电脑都需配置）

Typora → 偏好设置 → **图像**

* 插入图片时：**复制到指定路径**
* 目录：`./assets`
* **使用相对路径**：勾选
* 勾选“对本地剪贴板/拖拽图片执行复制”

---

## Git 基本配置（每台电脑一次）

```powershell
git config user.name  "<你的GitHub用户名>"
git config user.email "you@example.com"
git config core.quotepath false   # 终端显示中文友好
git config pull.rebase true       # 拉取默认 rebase，减少无意义 merge
git config core.autocrlf true     # Windows 推荐 true
```

---

## SSH（建议走 443 端口，适配受限网络）

1. 生成密钥并加载 ssh-agent：

   ```powershell
   New-Item -ItemType Directory -Path "$env:USERPROFILE\.ssh" -Force | Out-Null
   ssh-keygen -t ed25519 -C "you@example.com" -f "$env:USERPROFILE\.ssh\id_ed25519"

   # 以“管理员”PowerShell执行：
   Set-Service -Name ssh-agent -StartupType Automatic
   Start-Service ssh-agent

   # 回到普通 PowerShell：
   ssh-add "$env:USERPROFILE\.ssh\id_ed25519"
   ```

2. 写入 `~/.ssh/config`（**UTF-8 无 BOM**）：

   ```
   Host github.com
     HostName ssh.github.com
     Port 443
     User git
     IdentityFile ~/.ssh/id_ed25519
     IdentitiesOnly yes
   ```

3. 将公钥加入 GitHub（Settings → SSH and GPG keys），并验证：

   ```powershell
   ssh -T git@github.com
   # 成功会显示：Hi <username>! You've successfully authenticated...
   ```

---

## 第二台电脑首次克隆

```powershell
Set-Location "C:\Users\<YourName>\Documents"
git clone "ssh://git@ssh.github.com:443/<你的GitHub用户名>/Daily-Work.git"
Set-Location .\Daily-Work
```

---

## 日常同步流程（两台电脑通用）

```powershell
# 1) 拉最新（避免冲突）
git pull --rebase origin main

# 2) 写作/编辑（md 与 assets/*）

# 3) 提交
git add -A
git commit -m "docs: <本次改动说明>"

# 4) 推送
git push origin main
```

> 若出现合并冲突，Git 会用 `<<<<<<<`, `=======`, `>>>>>>>` 标注冲突区。手工合并后：

```powershell
git add <冲突文件>
git rebase --continue   # 若处在 rebase 流程
git push origin main
```

---

## 脚本工具（在仓库根目录执行）

### `fix-assets-links.ps1`

**用途**：当 `assets/` 内文件被重命名或迁移后，修复 md 中仍指向旧文件名的链接。
**用法**：

```powershell
PowerShell -ExecutionPolicy Bypass -File .\fix-assets-links.ps1
```

执行完成会列出仍缺失的资源（如有）。

### `rescue-missing-assets.ps1`

**用途**：在常见目录（`Documents/Desktop/Downloads/Pictures/OneDrive/Typora 用户目录`）中**搜索缺失图片**，并复制回 `assets/`。
**用法**：

```powershell
PowerShell -ExecutionPolicy Bypass -File .\rescue-missing-assets.ps1
```

若同名多处，脚本默认选取**最新**候选并标注 `AMBIGUOUS`。

### `typora-migrate.ps1`（可选）

**用途**：一次性规范历史 md 的图片路径到 `assets/`，并按统一策略重命名。
**建议**：执行前先 `git commit` 形成可回滚快照。

---

## 常见问题（FAQ）

* **另一台电脑图片不显示**
  1）确认 Typora 设置为“复制到 `./assets` + 使用相对路径”；
  2）运行 `fix-assets-links.ps1`；
  3）若仍缺文件，运行 `rescue-missing-assets.ps1` 补齐。

* **推送失败（网络/代理/端口限制）**

  * 已使用 **SSH over 443**；若仍失败，检查防火墙/代理对白名单 `ssh.github.com:443`。
  * 本仓库默认**不启用 Git LFS**（图片体量较小）；如未来需要托管超大文件，请再启用 LFS 并确保网络放行。

* **Permission denied (publickey)**

  * 执行 `ssh-add ~/.ssh/id_ed25519` 后再 `ssh -T git@github.com` 验证。

* **中文路径显示异常**

  * 运行：`git config core.quotepath false`。

---

## `.gitignore`（建议）

```
# Windows
Thumbs.db
Desktop.ini

# macOS（如将来跨平台）
.DS_Store

# 临时/缓存/日志
*.log
tmp/

# Typora 缓存（如有）
.typora-cache/
```

---

## 可选：一键提交函数（本机 PowerShell 临时定义）

```powershell
function gwc { param([string]$m="update")
  git pull --rebase origin main
  git add -A
  git commit -m "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m"
  git push origin main
}
# 使用：gwc "docs: 本次实验记录与两张图"
```

> 说明：本仓库默认视为**个人资料**。若转为团队协作，请补充 LICENSE/CONTRIBUTING 等，并在 `.gitignore` 中避免提交任何敏感信息（如 `.ssh`、token、密钥、医疗/隐私数据等）。
