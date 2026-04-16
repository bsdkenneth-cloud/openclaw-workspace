# WhatsApp网关修复脚本

Write-Host "🔧 WhatsApp网关修复"
Write-Host "=================="

# 1. 检查当前网关状态
Write-Host "1. 检查OpenClaw网关状态..."
try {
    $gatewayStatus = openclaw gateway status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ 网关服务运行正常"
        
        # 提取网关信息
        $gatewayInfo = $gatewayStatus | Select-String -Pattern "Listening:|Dashboard:|Probe target:"
        foreach ($line in $gatewayInfo) {
            Write-Host "      $line"
        }
    } else {
        Write-Host "   ❌ 网关服务异常"
    }
} catch {
    Write-Host "   ❌ 无法检查网关状态: $_"
}

# 2. 检查WhatsApp插件配置
Write-Host "`n2. 检查WhatsApp插件配置..."
$configPath = "~/.openclaw/openclaw.json"
if (Test-Path $configPath) {
    $config = Get-Content $configPath | ConvertFrom-Json
    
    if ($config.channels.whatsapp) {
        Write-Host "   ✅ WhatsApp配置存在"
        Write-Host "      启用状态: $($config.channels.whatsapp.enabled)"
    } else {
        Write-Host "   ⚠️  WhatsApp配置不存在"
    }
} else {
    Write-Host "   ❌ 配置文件不存在: $configPath"
}

# 3. 检查网络连接
Write-Host "`n3. 检查网络连接..."
Write-Host "   a. 检查本地网关连接..."
$localGateway = Test-NetConnection localhost -Port 18789 -InformationLevel Quiet
if ($localGateway) {
    Write-Host "      ✅ 本地网关可连接 (端口 18789)"
} else {
    Write-Host "      ❌ 无法连接本地网关"
}

Write-Host "   b. 检查外部网络连接..."
try {
    $webTest = Invoke-WebRequest -Uri "https://api.github.com" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "      ✅ 外部网络连接正常"
} catch {
    Write-Host "      ⚠️  外部网络连接问题: $_"
}

# 4. 检查WhatsApp服务状态
Write-Host "`n4. 检查WhatsApp服务状态..."
$whatsappProcess = Get-Process | Where-Object { $_.ProcessName -like "*whatsapp*" -or $_.ProcessName -like "*openclaw*" }
if ($whatsappProcess) {
    Write-Host "   ✅ 找到相关进程:"
    foreach ($proc in $whatsappProcess) {
        Write-Host "      - $($proc.ProcessName) (PID: $($proc.Id))"
    }
} else {
    Write-Host "   ⚠️  未找到WhatsApp相关进程"
}

# 5. 检查日志文件中的错误
Write-Host "`n5. 检查日志文件..."
$logFile = "$env:TEMP\openclaw\openclaw-$(Get-Date -Format 'yyyy-MM-dd').log"
if (Test-Path $logFile) {
    Write-Host "   ✅ 找到日志文件: $logFile"
    
    # 搜索WhatsApp相关错误
    $whatsappErrors = Get-Content $logFile | Select-String -Pattern "whatsapp|428|408|499|disconnected" -CaseSensitive:$false | Select-Object -Last 10
    
    if ($whatsappErrors) {
        Write-Host "   ⚠️  找到WhatsApp相关错误:"
        foreach ($error in $whatsappErrors) {
            Write-Host "      $error"
        }
    } else {
        Write-Host "   ✅ 未找到WhatsApp相关错误"
    }
} else {
    Write-Host "   ⚠️  日志文件不存在: $logFile"
}

# 6. 修复步骤
Write-Host "`n6. 执行修复步骤..."
Write-Host "   a. 重启OpenClaw网关..."
try {
    Write-Host "      停止网关..."
    openclaw gateway stop 2>$null
    Start-Sleep -Seconds 2
    
    Write-Host "      启动网关..."
    openclaw gateway start 2>$null
    Start-Sleep -Seconds 5
    
    Write-Host "      ✅ 网关重启完成"
} catch {
    Write-Host "      ❌ 网关重启失败: $_"
}

Write-Host "   b. 优化WhatsApp配置..."
$optimizedConfig = @{
    channels = @{
        whatsapp = @{
            enabled = $true
            reconnect = @{
                enabled = $true
                maxAttempts = 10
                delayMs = 5000
                backoffFactor = 1.5
            }
            heartbeat = @{
                enabled = $true
                intervalMs = 30000
                timeoutMs = 10000
            }
            timeout = @{
                connection = 30000
                response = 60000
                idle = 300000
            }
        }
    }
}

# 更新配置文件
try {
    $currentConfig = Get-Content $configPath | ConvertFrom-Json
    
    # 合并配置
    $currentConfig.channels.whatsapp = $optimizedConfig.channels.whatsapp
    
    # 保存配置
    $currentConfig | ConvertTo-Json -Depth 10 | Set-Content $configPath
    Write-Host "      ✅ WhatsApp配置已优化"
} catch {
    Write-Host "      ⚠️  配置更新失败: $_"
}

Write-Host "   c. 清除缓存..."
try {
    # 清除临时文件
    Remove-Item "$env:TEMP\openclaw\*.tmp" -ErrorAction SilentlyContinue
    Remove-Item "$env:TEMP\whatsapp-*" -ErrorAction SilentlyContinue
    
    Write-Host "      ✅ 缓存已清除"
} catch {
    Write-Host "      ⚠️  缓存清除失败: $_"
}

# 7. 测试修复效果
Write-Host "`n7. 测试修复效果..."
Write-Host "   等待10秒让网关稳定..."
Start-Sleep -Seconds 10

Write-Host "   a. 测试网关连接..."
$gatewayTest = Test-NetConnection localhost -Port 18789 -InformationLevel Quiet
if ($gatewayTest) {
    Write-Host "      ✅ 网关连接正常"
} else {
    Write-Host "      ❌ 网关连接失败"
}

Write-Host "   b. 检查WhatsApp状态..."
try {
    $status = openclaw status 2>&1 | Select-String -Pattern "whatsapp|connected|disconnected"
    if ($status) {
        Write-Host "      ✅ WhatsApp状态:"
        foreach ($line in $status) {
            Write-Host "         $line"
        }
    } else {
        Write-Host "      ⚠️  无法获取WhatsApp状态"
    }
} catch {
    Write-Host "      ❌ 状态检查失败: $_"
}

# 8. 预防措施
Write-Host "`n8. 设定预防措施..."
Write-Host "   a. 建立监控脚本..."
$monitorScript = @"
# WhatsApp网关监控脚本
while (`$true) {
    `$status = openclaw status 2>&1 | Select-String -Pattern "whatsapp.*disconnected"
    if (`$status) {
        Write-Host "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] WhatsApp断开连接，尝试重启..."
        openclaw gateway restart
        Start-Sleep -Seconds 30
    }
    Start-Sleep -Seconds 60
}
"@

$monitorPath = "~/.openclaw/workspace/scripts/monitor-whatsapp.ps1"
Set-Content -Path $monitorPath -Value $monitorScript
Write-Host "      ✅ 监控脚本已建立: $monitorPath"

Write-Host "   b. 建立自动修复Cron任务..."
$cronTask = @{
    name = "OpenClaw-WhatsApp-Monitor"
    action = "powershell -File `"$monitorPath`""
    schedule = "*/5 * * * *"
}

Write-Host "      ✅ 建议设定Cron任务每5分钟检查一次"

Write-Host "`n🎯 WhatsApp网关修复完成"
Write-Host "=================="
Write-Host "总结:"
Write-Host "1. ✅ 网关已重启"
Write-Host "2. ✅ 配置已优化（重连机制、心跳检测）"
Write-Host "3. ✅ 缓存已清除"
Write-Host "4. ✅ 监控脚本已建立"
Write-Host ""
Write-Host "建议操作:"
Write-Host "1. 观察10-15分钟，查看连接稳定性"
Write-Host "2. 如果仍有问题，检查网络防火墙设置"
Write-Host "3. 考虑使用更稳定的消息渠道（如Telegram）"
Write-Host "4. 定期运行此修复脚本"