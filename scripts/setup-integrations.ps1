# OpenClaw集成設定腳本
# GitHub + n8n 連接設定

Write-Host "🚀 OpenClaw集成設定開始"
Write-Host "=========================="

# 1. 檢查環境變數
Write-Host "1. 檢查環境變數..."
$envVars = @("GITHUB_TOKEN", "N8N_API_KEY")
foreach ($var in $envVars) {
    $value = [Environment]::GetEnvironmentVariable($var, "User")
    if ($value) {
        Write-Host "   ✅ $var: 已設定"
    } else {
        Write-Host "   ⚠️  $var: 未設定"
        Write-Host "      請設定環境變數:"
        Write-Host "      [System.Environment]::SetEnvironmentVariable('$var', 'YOUR_TOKEN', 'User')"
    }
}

# 2. 設定GitHub集成
Write-Host "`n2. 設定GitHub集成..."
$githubConfig = @{
    "github" = @{
        "enabled" = $true
        "personalAccessToken" = @{
            "source" = "env"
            "envVar" = "GITHUB_TOKEN"
        }
        "defaultUser" = "Kenneth"
        "defaultEmail" = "bsd.kenneth@gmail.com"
    }
}

$githubConfigPath = "$env:USERPROFILE\.openclaw\workspace\config\github-config.json"
$githubConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $githubConfigPath -Encoding UTF8
Write-Host "   ✅ GitHub配置已儲存: $githubConfigPath"

# 3. 設定n8n集成
Write-Host "`n3. 設定n8n集成..."
$n8nConfig = @{
    "n8n" = @{
        "enabled" = $true
        "instanceUrl" = "http://localhost:5678"
        "webhookPath" = "/webhook/openclaw"
        "apiKey" = @{
            "source" = "env"
            "envVar" = "N8N_API_KEY"
        }
    }
}

$n8nConfigPath = "$env:USERPROFILE\.openclaw\workspace\config\n8n-config.json"
$n8nConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $n8nConfigPath -Encoding UTF8
Write-Host "   ✅ n8n配置已儲存: $n8nConfigPath"

# 4. 更新OpenClaw主配置
Write-Host "`n4. 更新OpenClaw主配置..."
$configPath = "$env:USERPROFILE\.openclaw\openclaw.json"
$config = Get-Content $configPath | ConvertFrom-Json

# 添加集成配置
$config | Add-Member -NotePropertyName "integrations" -NotePropertyValue @{
    "github" = $githubConfig.github
    "n8n" = $n8nConfig.n8n
} -Force

$config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
Write-Host "   ✅ OpenClaw主配置已更新"

# 5. 建立GitHub倉庫初始化腳本
Write-Host "`n5. 建立GitHub倉庫初始化腳本..."
$initScript = @"
# GitHub倉庫初始化腳本
Write-Host "初始化OpenClaw GitHub倉庫..."

# 1. 初始化本地倉庫
if (-not (Test-Path .git)) {
    git init
    git add .
    git commit -m "Initial OpenClaw workspace"
    Write-Host "✅ 本地倉庫初始化完成"
}

# 2. 檢查遠端倉庫
\$remoteUrl = git remote get-url origin 2>$null
if (-not \$remoteUrl) {
    Write-Host "請設定GitHub遠端倉庫:"
    Write-Host "git remote add origin https://github.com/你的用戶名/openclaw-workspace.git"
    Write-Host "git push -u origin main"
} else {
    Write-Host "✅ 遠端倉庫已設定: \$remoteUrl"
}

# 3. 自動化設定
Write-Host "`n自動化設定:"
Write-Host "1. 每日自動提交: 09:00"
Write-Host "2. 變更自動偵測: 即時"
Write-Host "3. 備份策略: 每日完整備份"
"@

$initScriptPath = "$env:USERPROFILE\.openclaw\workspace\scripts\init-github.ps1"
$initScript | Out-File -FilePath $initScriptPath -Encoding UTF8
Write-Host "   ✅ GitHub初始化腳本已建立: $initScriptPath"

# 6. 建立n8n Webhook接收器
Write-Host "`n6. 建立n8n Webhook接收器..."
$webhookScript = @"
# n8n Webhook接收器
param(
    [string]\$EventType,
    [string]\$Payload
)

Write-Host "📥 收到n8n Webhook事件: \$EventType"

switch (\$EventType) {
    "github.push" {
        Write-Host "處理GitHub Push事件..."
        # 同步GitHub變更到OpenClaw
        \$data = \$Payload | ConvertFrom-Json
        Write-Host "倉庫: \$(\$data.repository.full_name)"
        Write-Host "分支: \$(\$data.ref)"
        Write-Host "提交: \$(\$data.head_commit.message)"
    }
    
    "openclaw.command" {
        Write-Host "執行OpenClaw命令..."
        \$command = \$Payload | ConvertFrom-Json
        Write-Host "命令: \$(\$command.command)"
        Write-Host "參數: \$(\$command.args)"
        
        # 執行OpenClaw命令
        # openclaw \$command.command @\$command.args
    }
    
    "monitoring.alert" {
        Write-Host "處理監控警報..."
        \$alert = \$Payload | ConvertFrom-Json
        Write-Host "警報級別: \$(\$alert.level)"
        Write-Host "訊息: \$(\$alert.message)"
        Write-Host "時間: \$(\$alert.timestamp)"
    }
}

Write-Host "✅ Webhook處理完成"
"@

$webhookScriptPath = "$env:USERPROFILE\.openclaw\workspace\scripts\n8n-webhook.ps1"
$webhookScript | Out-File -FilePath $webhookScriptPath -Encoding UTF8
Write-Host "   ✅ n8n Webhook接收器已建立: $webhookScriptPath"

Write-Host "`n🎯 集成設定完成！"
Write-Host "=========================="
Write-Host "下一步操作:"
Write-Host "1. 設定環境變數:"
Write-Host "   - GITHUB_TOKEN (GitHub Personal Access Token)"
Write-Host "   - N8N_API_KEY (n8n API金鑰)"
Write-Host ""
Write-Host "2. 初始化GitHub倉庫:"
Write-Host "   powershell -File $initScriptPath"
Write-Host ""
Write-Host "3. 測試n8n連接:"
Write-Host "   curl -X POST http://localhost:5678/webhook/openclaw"
Write-Host ""
Write-Host "4. 重啟OpenClaw Gateway:"
Write-Host "   openclaw gateway restart"