# Create New GitHub Token Script

Write-Host "=== GitHub Token 重新建立流程 ==="
Write-Host ""

Write-Host "步驟 1: 刪除舊 Token"
Write-Host "請訪問: https://github.com/settings/tokens"
Write-Host "找到 Token 'OpenClaw-Access'"
Write-Host "點擊右側的垃圾桶圖示刪除"
Write-Host ""

Write-Host "步驟 2: 建立新 Token"
Write-Host "1. 點擊 'Generate new token' -> 'Generate new token (classic)'"
Write-Host "2. 設定 Token name: 'OpenClaw-Workspace'"
Write-Host "3. 選擇 Expiration: 建議 '90 days' 或 'No expiration'"
Write-Host "4. 選擇 scopes: 勾選 'repo' (全選) 和 'workflow'"
Write-Host "5. 點擊 'Generate token'"
Write-Host "6. 複製生成的 Token (只會顯示一次)"
Write-Host ""

Write-Host "步驟 3: 設定新 Token"
$newToken = Read-Host "請貼上新的 GitHub Token"

if ($newToken) {
    # 設定環境變數
    [System.Environment]::SetEnvironmentVariable('GITHUB_TOKEN', $newToken, 'User')
    $env:GITHUB_TOKEN = $newToken
    
    Write-Host "新 Token 已設定到環境變數"
    
    # 測試 Token
    $headers = @{
        "Authorization" = "token $newToken"
        "Accept" = "application/vnd.github.v3+json"
    }
    
    try {
        $userInfo = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -ErrorAction Stop
        Write-Host "Token 測試成功 - 用戶: $($userInfo.login)"
        
        # 檢查倉庫
        try {
            $repoInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/bsdkenneth-cloud/openclaw-workspace" -Headers $headers
            Write-Host "倉庫狀態: $($repoInfo.html_url)"
        } catch {
            Write-Host "倉庫不存在或無法存取"
        }
        
    } catch {
        Write-Host "Token 測試失敗: $_"
    }
    
    Write-Host ""
    Write-Host "步驟 4: 重新推送代碼"
    Write-Host "執行以下命令:"
    Write-Host "cd ~/.openclaw/workspace"
    Write-Host "git push -u origin main"
    
} else {
    Write-Host "未輸入 Token，設定取消"
}

Write-Host ""
Write-Host "=== 流程完成 ==="