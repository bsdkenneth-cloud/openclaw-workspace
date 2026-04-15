# GitHub 連接設定指南

## 1. 建立GitHub Personal Access Token (PAT)

### 步驟：
1. 訪問 https://github.com/settings/tokens
2. 點擊 "Generate new token" → "Generate new token (classic)"
3. 設定權限：
   - `repo` (全選)
   - `workflow`
   - `write:packages`
   - `delete:packages`
4. 生成Token並複製

## 2. 設定環境變數

### Windows PowerShell:
```powershell
# 設定GitHub Token
[System.Environment]::SetEnvironmentVariable('GITHUB_TOKEN', '你的GitHub_PAT', 'User')

# 重新啟動PowerShell或執行
$env:GITHUB_TOKEN = '你的GitHub_PAT'
```

### 命令提示字元 (CMD):
```cmd
setx GITHUB_TOKEN "你的GitHub_PAT"
```

## 3. 初始化Git倉庫

```powershell
# 進入工作空間
cd ~/.openclaw/workspace

# 初始化Git
git init
git config user.name "Kenneth"
git config user.email "bsd.kenneth@gmail.com"

# 建立.gitignore
@"
# OpenClaw工作空間忽略檔案
node_modules/
.DS_Store
*.log
*.tmp
.env
secrets/
temp/
cache/
"@ | Out-File -FilePath .gitignore -Encoding UTF8

# 首次提交
git add .
git commit -m "初始提交: OpenClaw工作空間 $(Get-Date -Format 'yyyy-MM-dd')"

# 連接到GitHub (先在GitHub建立倉庫)
git remote add origin https://github.com/你的用戶名/openclaw-workspace.git
git branch -M main
git push -u origin main
```

## 4. 自動化設定

### 每日自動提交腳本：
```powershell
# ~/.openclaw/workspace/scripts/auto-commit.ps1
cd ~/.openclaw/workspace
git add .
git commit -m "自動提交: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
git push origin main
```

### 設定Windows排程任務：
```powershell
# 建立每日自動提交任務
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File ~/.openclaw/workspace/scripts/auto-commit.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At "21:00"
Register-ScheduledTask -TaskName "OpenClawAutoCommit" -Action $action -Trigger $trigger -Description "每日自動提交OpenClaw工作空間"
```

## 5. 測試連接

```powershell
# 測試GitHub API
$headers = @{
    "Authorization" = "token $env:GITHUB_TOKEN"
    "Accept" = "application/vnd.github.v3+json"
}

# 測試獲取用戶資訊
Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers

# 測試倉庫操作
Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Headers $headers
```

## 6. 整合到OpenClaw

配置已自動載入：
- GitHub Token: 從環境變數讀取
- 自動提交: 已啟用
- 用戶資訊: Kenneth / bsd.kenneth@gmail.com

## 疑難排解

### 問題1: Token無效
```powershell
# 重新生成Token並更新
[System.Environment]::SetEnvironmentVariable('GITHUB_TOKEN', '新Token', 'User')
```

### 問題2: 權限不足
- 確認Token有足夠權限
- 重新生成Token並選擇所有必要權限

### 問題3: 連線問題
```powershell
# 測試網路連線
Test-NetConnection github.com -Port 443

# 測試API連線
curl -H "Authorization: token $env:GITHUB_TOKEN" https://api.github.com/user
```

## 進階功能

### Webhook設定：
1. 在GitHub倉庫設定中新增Webhook
2. URL: `http://你的OpenClaw實例/webhook/github`
3. 事件: push, pull_request, issues

### 自動化工作流程：
- 代碼變更時自動備份
- Issue建立時自動通知
- Pull Request時自動檢查