# 簡化版 GitHub 設定腳本

Write-Host "=== GitHub Token 設定 ==="

# 檢查當前 Token
$currentToken = [Environment]::GetEnvironmentVariable("GITHUB_TOKEN", "User")

if ($currentToken) {
    Write-Host "已設定 GitHub Token"
    
    # 測試 Token
    $headers = @{
        "Authorization" = "token $currentToken"
        "Accept" = "application/vnd.github.v3+json"
    }
    
    try {
        $userInfo = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -ErrorAction Stop
        Write-Host "Token 有效 - 用戶: $($userInfo.login)"
        exit 0
    } catch {
        Write-Host "Token 無效或已過期"
        $currentToken = $null
    }
}

if (-not $currentToken) {
    Write-Host "`n需要設定 GitHub Personal Access Token"
    Write-Host "請按照以下步驟操作："
    Write-Host ""
    Write-Host "1. 訪問: https://github.com/settings/tokens"
    Write-Host "2. 點擊 'Generate new token' -> 'Generate new token (classic)'"
    Write-Host "3. 設定 Token 名稱: 'OpenClaw-Access'"
    Write-Host "4. 選擇權限:"
    Write-Host "   - repo (全選)"
    Write-Host "   - workflow"
    Write-Host "5. 點擊 'Generate token'"
    Write-Host "6. 複製生成的 Token"
    Write-Host ""
    
    $tokenInput = Read-Host "請輸入你的 GitHub Token"
    
    if ($tokenInput) {
        # 設定環境變數
        [System.Environment]::SetEnvironmentVariable('GITHUB_TOKEN', $tokenInput, 'User')
        Write-Host "GitHub Token 已設定"
        
        # 測試新 Token
        $headers = @{
            "Authorization" = "token $tokenInput"
            "Accept" = "application/vnd.github.v3+json"
        }
        
        try {
            $userInfo = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -ErrorAction Stop
            Write-Host "Token 測試成功 - 用戶: $($userInfo.login)"
        } catch {
            Write-Host "Token 測試失敗"
        }
    }
}

Write-Host "`n=== GitHub 設定完成 ==="