# n8n連接測試腳本

Write-Host "🔗 測試n8n連接..."
Write-Host "=========================="

# 1. 檢查n8n是否安裝
Write-Host "1. 檢查n8n安裝..."
try {
    $n8nVersion = n8n --version 2>$null
    if ($n8nVersion) {
        Write-Host "   ✅ n8n已安裝: $n8nVersion"
    } else {
        Write-Host "   ❌ n8n未安裝"
        Write-Host "      安裝指令: npm install -g n8n"
        exit 1
    }
} catch {
    Write-Host "   ❌ n8n未安裝"
    Write-Host "      安裝指令: npm install -g n8n"
    exit 1
}

# 2. 檢查n8n服務狀態
Write-Host "`n2. 檢查n8n服務狀態..."
$n8nProcess = Get-Process -Name "n8n" -ErrorAction SilentlyContinue
if ($n8nProcess) {
    Write-Host "   ✅ n8n服務運行中 (PID: $($n8nProcess.Id))"
} else {
    Write-Host "   ⚠️  n8n服務未運行"
    Write-Host "      啟動指令: n8n start"
    
    # 嘗試啟動n8n
    Write-Host "     嘗試啟動n8n..."
    Start-Process "n8n" "start" -WindowStyle Hidden
    Start-Sleep -Seconds 5
}

# 3. 測試端口連接
Write-Host "`n3. 測試端口連接..."
$portTest = Test-NetConnection localhost -Port 5678 -InformationLevel Quiet
if ($portTest) {
    Write-Host "   ✅ 端口5678可連接"
} else {
    Write-Host "   ❌ 無法連接端口5678"
    Write-Host "      請確認n8n已啟動: n8n start"
    exit 1
}

# 4. 測試Webhook
Write-Host "`n4. 測試Webhook連接..."
$webhookUrl = "http://localhost:5678/webhook/openclaw"
$testPayload = @{
    event = "connection_test"
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    source = "OpenClaw"
    message = "測試n8n連接"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $testPayload -ContentType "application/json" -ErrorAction Stop
    Write-Host "   ✅ Webhook測試成功"
    Write-Host "      回應: $($response | ConvertTo-Json -Compress)"
} catch {
    Write-Host "   ⚠️  Webhook測試失敗: $_"
    Write-Host "      這可能是正常的，如果n8n中尚未建立/webhook/openclaw工作流程"
}

# 5. 測試API連接
Write-Host "`n5. 測試API連接..."
$apiUrl = "http://localhost:5678/rest/health"
try {
    $health = Invoke-RestMethod -Uri $apiUrl -ErrorAction SilentlyContinue
    if ($health.status -eq "ok") {
        Write-Host "   ✅ n8n API健康狀態: $($health.status)"
    } else {
        Write-Host "   ✅ n8n API可連接"
    }
} catch {
    Write-Host "   ⚠️  n8n API連接失敗: $_"
}

# 6. 檢查環境變數
Write-Host "`n6. 檢查環境變數..."
$n8nApiKey = [Environment]::GetEnvironmentVariable("N8N_API_KEY", "User")
if ($n8nApiKey) {
    Write-Host "   ✅ N8N_API_KEY已設定"
} else {
    Write-Host "   ⚠️  N8N_API_KEY未設定"
    Write-Host "      設定指令:"
    Write-Host "      [System.Environment]::SetEnvironmentVariable('N8N_API_KEY', '你的n8n_API_KEY', 'User')"
}

Write-Host "`n🎯 n8n連接測試完成"
Write-Host "=========================="
Write-Host "下一步操作:"
Write-Host "1. 訪問n8n介面: http://localhost:5678"
Write-Host "2. 建立Webhook工作流程:"
Write-Host "   - 路徑: /webhook/openclaw"
Write-Host "   - 方法: POST"
Write-Host "3. 設定環境變數N8N_API_KEY"
Write-Host "4. 測試完整工作流程"