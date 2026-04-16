# n8n安装和设定脚本

Write-Host "⚙️ n8n安装和设定"
Write-Host "================"

# 1. 检查Node.js安装
Write-Host "1. 检查Node.js安装..."
$nodeVersion = node --version 2>$null
$npmVersion = npm --version 2>$null

if ($nodeVersion -and $npmVersion) {
    Write-Host "   ✅ Node.js已安装: $nodeVersion"
    Write-Host "   ✅ npm已安装: $npmVersion"
} else {
    Write-Host "   ❌ Node.js未安装"
    Write-Host ""
    Write-Host "   请先安装Node.js："
    Write-Host "   1. 访问: https://nodejs.org/"
    Write-Host "   2. 下载LTS版本"
    Write-Host "   3. 安装Node.js"
    Write-Host "   4. 重新启动终端"
    Write-Host ""
    exit 1
}

# 2. 检查n8n是否已安装
Write-Host "`n2. 检查n8n安装..."
$n8nVersion = n8n --version 2>$null
if ($n8nVersion) {
    Write-Host "   ✅ n8n已安装: $n8nVersion"
} else {
    Write-Host "   ⚠️  n8n未安装，开始安装..."
    
    # 安装n8n
    Write-Host "   📦 安装n8n (可能需要几分钟)..."
    npm install -g n8n
    
    # 验证安装
    $n8nVersion = n8n --version 2>$null
    if ($n8nVersion) {
        Write-Host "   ✅ n8n安装成功: $n8nVersion"
    } else {
        Write-Host "   ❌ n8n安装失败"
        exit 1
    }
}

# 3. 检查n8n服务状态
Write-Host "`n3. 检查n8n服务状态..."
$n8nProcess = Get-Process -Name "n8n" -ErrorAction SilentlyContinue
if ($n8nProcess) {
    Write-Host "   ✅ n8n服务运行中 (PID: $($n8nProcess.Id))"
    Write-Host "      访问: http://localhost:5678"
} else {
    Write-Host "   ⚠️  n8n服务未运行"
    Write-Host ""
    Write-Host "   启动n8n服务："
    Write-Host "   1. 打开新的终端窗口"
    Write-Host "   2. 运行: n8n start"
    Write-Host "   3. 等待启动完成"
    Write-Host "   4. 访问: http://localhost:5678"
    Write-Host ""
    
    $startN8n = Read-Host "   是否现在启动n8n? (y/n)"
    if ($startN8n -eq 'y') {
        Write-Host "   🚀 启动n8n服务..."
        Start-Process "n8n" "start" -WindowStyle Hidden
        Write-Host "   ⏳ 等待10秒启动..."
        Start-Sleep -Seconds 10
        
        # 检查是否启动成功
        $portTest = Test-NetConnection localhost -Port 5678 -InformationLevel Quiet
        if ($portTest) {
            Write-Host "   ✅ n8n启动成功"
            Write-Host "      访问: http://localhost:5678"
        } else {
            Write-Host "   ⚠️  n8n启动可能失败，请手动检查"
        }
    }
}

# 4. 测试n8n连接
Write-Host "`n4. 测试n8n连接..."
$portTest = Test-NetConnection localhost -Port 5678 -InformationLevel Quiet
if ($portTest) {
    Write-Host "   ✅ n8n端口可连接"
    
    # 测试API
    try {
        $health = Invoke-RestMethod -Uri "http://localhost:5678/rest/health" -ErrorAction SilentlyContinue
        if ($health.status -eq "ok") {
            Write-Host "   ✅ n8n API健康状态: $($health.status)"
        } else {
            Write-Host "   ✅ n8n API可连接"
        }
    } catch {
        Write-Host "   ⚠️  n8n API连接失败: $_"
    }
} else {
    Write-Host "   ❌ 无法连接n8n端口"
    Write-Host "      请确认n8n已启动: n8n start"
}

# 5. 设定n8n环境变量
Write-Host "`n5. 设定n8n环境变量..."
$n8nApiKey = [Environment]::GetEnvironmentVariable("N8N_API_KEY", "User")
if ($n8nApiKey) {
    Write-Host "   ✅ N8N_API_KEY已设定"
    Write-Host "      前5位: $($n8nApiKey.Substring(0, [Math]::Min(5, $n8nApiKey.Length)))..."
} else {
    Write-Host "   ⚠️  N8N_API_KEY未设定"
    Write-Host ""
    Write-Host "   获取n8n API Key："
    Write-Host "   1. 访问: http://localhost:5678"
    Write-Host "   2. 首次访问需要设定管理员账号"
    Write-Host "   3. 登录后，点击右上角用户图标"
    Write-Host "   4. 选择 'Settings' → 'API'"
    Write-Host "   5. 点击 'Create New API Key'"
    Write-Host "   6. 复制生成的API Key"
    Write-Host ""
    
    $newApiKey = Read-Host "   请输入你的n8n API Key" -AsSecureString
    $apiKeyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($newApiKey)
    )
    
    if ($apiKeyPlain) {
        [System.Environment]::SetEnvironmentVariable('N8N_API_KEY', $apiKeyPlain, 'User')
        Write-Host "   ✅ N8N_API_KEY已设定"
    }
}

# 6. 导入OpenClaw工作流程
Write-Host "`n6. 导入OpenClaw工作流程..."
$workflowConfig = "~/.openclaw/workspace/config/n8n-workflows.json"
if (Test-Path $workflowConfig) {
    Write-Host "   ✅ 工作流程配置存在: $workflowConfig"
    Write-Host ""
    Write-Host "   手动导入步骤："
    Write-Host "   1. 访问: http://localhost:5678"
    Write-Host "   2. 点击左侧 'Workflows'"
    Write-Host "   3. 点击 'Import from file'"
    Write-Host "   4. 选择文件: $workflowConfig"
    Write-Host "   5. 点击 'Import'"
    Write-Host "   6. 激活工作流程"
} else {
    Write-Host "   ⚠️  工作流程配置不存在"
}

# 7. 测试Webhook
Write-Host "`n7. 测试Webhook连接..."
$webhookUrl = "http://localhost:5678/webhook/openclaw"
$testPayload = @{
    event = "connection_test"
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    source = "OpenClaw安装脚本"
    message = "测试n8n Webhook连接"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $testPayload -ContentType "application/json" -ErrorAction SilentlyContinue
    Write-Host "   ✅ Webhook测试成功"
} catch {
    Write-Host "   ⚠️  Webhook测试失败: $_"
    Write-Host "      这可能是正常的，如果n8n中尚未建立/webhook/openclaw工作流程"
}

Write-Host "`n🎯 n8n设定完成"
Write-Host "================"
Write-Host "下一步操作："
Write-Host "1. 访问n8n界面: http://localhost:5678"
Write-Host "2. 导入工作流程配置"
Write-Host "3. 建立Webhook工作流程 (路径: /webhook/openclaw)"
Write-Host "4. 测试完整集成"
Write-Host ""
Write-Host "重要提醒："
Write-Host "- n8n需要保持运行状态"
Write-Host "- 可以设定n8n为Windows服务"
Write-Host "- 定期备份n8n工作流程"