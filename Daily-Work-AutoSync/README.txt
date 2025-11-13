Daily-Work AutoSync Pack
========================

包含以下文件：
- pull.ps1 / push.ps1：一键拉取与一键上传（PowerShell）
- Pull-Daily-Work.bat / Push-Daily-Work.bat：双击调用 PowerShell 脚本
- init.ps1：新设备一键初始化（设置仓库参数、首次拉取等）
- Init-Daily-Work.bat：双击调用初始化脚本
- fix-assets-links.ps1：推送前可选的图片引用修复（push.ps1 会自动调用）

使用方法：
1) 首次在新设备：把整个压缩包解压到你仓库根目录（Daily-Work），双击 `Init-Daily-Work.bat` 按提示完成初始化。
2) 平时：写作前双击 `Pull-Daily-Work.bat` 拉取更新；写作后双击 `Push-Daily-Work.bat` 提交并推送。