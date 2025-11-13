## 常规四步（每次写完就做）



```
# 0) 进入仓库根目录
Set-Location "C:\Users\<YourName>\Documents\Daily-Work"
Set-Location "C:\Users\Irenegry\Documents\Daily-Work"
Set-Location "C:\Users\13678\Documents\Daily-Work"

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

```
Set-Location "C:\Users\<YourName>\Documents\Daily-Work"
Set-Location "C:\Users\Irenegry\Documents\Daily-Work"
Set-Location "C:\Users\13678\Documents\Daily-Work"

git pull --rebase origin main
```

```
# 1) 到仓库根目录
Set-Location "C:\Users\Irenegry\Documents\Daily-Work"
Set-Location "C:\Users\13678\Documents\Daily-Work"

# 2) 把当前所有改动（含新文件）先塞进临时区
$ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
git stash push -u -m "WIP $ts before pull on Device-2"

# 3) 拉取并变基到最新
git pull --rebase origin main

# 4) 把刚才的工作弹回工作区
git stash pop

# 5) 如有冲突：按提示逐个文件解决 → 标记解决
git status
git add <有冲突的文件>  # 逐个添加
# 若 rebase 仍在进行（提示你继续 rebase），执行：
# git rebase --continue

# 6) 正常提交并推送
git add -A
git commit -m "docs: sync changes on Device-2 after rebase"
git push origin main

```

