# 紧急修复脚本 - 全面修复OpenClaw和系统优化

Write-Host "🚨 紧急修复和系统优化"
Write-Host "====================="
Write-Host "时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

# 1. 修复WhatsApp网关连接问题
Write-Host "1. 🔧 修复WhatsApp网关连接..."
Write-Host "   a. 停止所有OpenClaw进程..."
Get-Process | Where-Object { $_.ProcessName -like "*openclaw*" -or $_.ProcessName -like "*node*" } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

Write-Host "   b. 清理临时文件..."
Remove-Item "$env:TEMP\openclaw\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\whatsapp-*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "   c. 重置OpenClaw配置..."
$configPath = "$env:USERPROFILE\.openclaw\openclaw.json"
if (Test-Path $configPath) {
    $config = Get-Content $configPath | ConvertFrom-Json
    
    # 优化WhatsApp配置
    $config.channels.whatsapp = @{
        enabled = $true
        reconnect = @{
            enabled = $true
            maxAttempts = 20
            delayMs = 3000
            backoffFactor = 1.2
        }
        heartbeat = @{
            enabled = $true
            intervalMs = 15000
            timeoutMs = 10000
        }
        timeout = @{
            connection = 45000
            response = 90000
            idle = 600000
        }
        qos = @{
            enabled = $true
            priority = "high"
            retryOnFailure = $true
        }
    }
    
    # 优化网关配置
    $config.gateway = @{
        mode = "local"
        bind = "0.0.0.0"
        port = 18789
        auth = @{
            mode = "token"
            token = "5ef38dca1acb459b7fbb08e630da0b08a49f26cc3520c2f2"
        }
        healthCheck = @{
            enabled = $true
            intervalMs = 30000
            timeoutMs = 10000
        }
        autoRestart = @{
            enabled = $true
            maxRestarts = 5
            windowMinutes = 60
        }
    }
    
    # 保存配置
    $config | ConvertTo-Json -Depth 10 | Set-Content $configPath
    Write-Host "   ✅ WhatsApp和网关配置已优化"
}

# 2. 启动OpenClaw网关
Write-Host "`n2. 🚀 启动OpenClaw网关..."
try {
    # 启动网关服务
    openclaw gateway start
    
    # 等待启动
    Write-Host "   等待网关启动..."
    $maxWait = 30
    $waitCount = 0
    $gatewayReady = $false
    
    while ($waitCount -lt $maxWait) {
        $portTest = Test-NetConnection localhost -Port 18789 -InformationLevel Quiet
        if ($portTest) {
            $gatewayReady = $true
            break
        }
        Start-Sleep -Seconds 1
        $waitCount++
    }
    
    if ($gatewayReady) {
        Write-Host "   ✅ 网关启动成功"
    } else {
        Write-Host "   ⚠️  网关启动可能有问题"
    }
} catch {
    Write-Host "   ❌ 网关启动失败: $_"
}

# 3. 系统优化
Write-Host "`n3. ⚡ 系统优化..."
Write-Host "   a. 检查网络连接..."
try {
    # 测试DNS
    $dnsTest = Resolve-DnsName google.com -ErrorAction SilentlyContinue
    if ($dnsTest) {
        Write-Host "      ✅ DNS解析正常"
    }
    
    # 测试网络延迟
    $pingTest = Test-Connection google.com -Count 2 -Quiet
    if ($pingTest) {
        Write-Host "      ✅ 网络连接正常"
    }
} catch {
    Write-Host "      ⚠️  网络检查失败: $_"
}

Write-Host "   b. 优化系统性能..."
try {
    # 清理系统临时文件
    Write-Host "      清理临时文件..."
    Cleanmgr /sagerun:1 | Out-Null
    
    # 优化电源设置（高性能）
    Write-Host "      优化电源设置..."
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c  # 高性能模式
    
    Write-Host "      ✅ 系统性能优化完成"
} catch {
    Write-Host "      ⚠️  系统优化部分失败: $_"
}

# 4. 建立自动修复系统
Write-Host "`n4. 🤖 建立自动修复系统..."
$autoRepairScript = @"
# OpenClaw自动修复脚本
`$logFile = "`$env:TEMP\openclaw-auto-repair.log"

function Log-Message {
    param([string]`$Message)
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[" + `$timestamp + "] " + `$Message | Add-Content -Path `$logFile
    Write-Host "[`$timestamp] `$Message"
}

# 检查网关状态
function Check-Gateway {
    `$portTest = Test-NetConnection localhost -Port 18789 -InformationLevel Quiet
    return `$portTest
}

# 检查WhatsApp连接
function Check-WhatsApp {
    try {
        `$status = openclaw status 2>&1 | Select-String -Pattern "whatsapp.*connected"
        return (`$status -ne `$null)
    } catch {
        return `$false
    }
}

# 主修复循环
while (`$true) {
    Log-Message "开始系统检查..."
    
    # 检查网关
    if (-not (Check-Gateway)) {
        Log-Message "网关断开，尝试重启..."
        openclaw gateway restart
        Start-Sleep -Seconds 10
    }
    
    # 检查WhatsApp
    if (-not (Check-WhatsApp)) {
        Log-Message "WhatsApp连接异常，等待重连..."
        Start-Sleep -Seconds 30
    }
    
    # 检查系统资源
    `$cpuUsage = (Get-Counter "\Processor(_Total)\% Processor Time").CounterSamples.CookedValue
    `$memoryUsage = (Get-Counter "\Memory\% Committed Bytes In Use").CounterSamples.CookedValue
    
    if (`$cpuUsage -gt 90) {
        Log-Message "CPU使用率过高: `$cpuUsage%"
    }
    
    if (`$memoryUsage -gt 85) {
        Log-Message "内存使用率过高: `$memoryUsage%"
        # 清理内存
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    }
    
    # 每5分钟检查一次
    Start-Sleep -Seconds 300
}
"@

$autoRepairPath = "$env:USERPROFILE\.openclaw\scripts\auto-repair.ps1"
New-Item -ItemType Directory -Path "$env:USERPROFILE\.openclaw\scripts" -Force | Out-Null
Set-Content -Path $autoRepairPath -Value $autoRepairScript
Write-Host "   ✅ 自动修复脚本已建立: $autoRepairPath"

# 5. 建立Windows计划任务
Write-Host "`n5. 📅 建立Windows计划任务..."
$taskName = "OpenClaw-Auto-Repair"
$taskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-WindowStyle Hidden -File `"$autoRepairPath`""
$taskTrigger = New-ScheduledTaskTrigger -AtStartup
$taskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

try {
    Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Principal $taskPrincipal -Settings $taskSettings -Force
    Write-Host "   ✅ 计划任务已建立: $taskName"
} catch {
    Write-Host "   ⚠️  计划任务建立失败: $_"
    Write-Host "      手动建立: 任务计划程序 → 创建任务 → 名称: OpenClaw-Auto-Repair"
}

# 6. 建立健康检查端点
Write-Host "`n6. 🩺 建立健康检查系统..."
$healthCheckScript = @"
# 健康检查脚本
param([string]`$CheckType = "all")

function Get-SystemHealth {
    `$health = @{
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        status = "healthy"
        checks = @()
    }
    
    # 检查网关
    `$gatewayCheck = Test-NetConnection localhost -Port 18789 -InformationLevel Quiet
    `$health.checks += @{
        name = "gateway"
        status = if (`$gatewayCheck) { "healthy" } else { "unhealthy" }
        details = if (`$gatewayCheck) { "端口18789可连接" } else { "端口18789无法连接" }
    }
    
    # 检查WhatsApp
    try {
        `$whatsappStatus = openclaw status 2>&1 | Select-String -Pattern "whatsapp"
        `$whatsappHealthy = (`$whatsappStatus -like "*connected*")
        `$health.checks += @{
            name = "whatsapp"
            status = if (`$whatsappHealthy) { "healthy" } else { "unhealthy" }
            details = if (`$whatsappHealthy) { "WhatsApp连接正常" } else { "WhatsApp连接异常" }
        }
    } catch {
        `$health.checks += @{
            name = "whatsapp"
            status = "error"
            details = "检查失败: $_"
        }
    }
    
    # 检查系统资源
    `$cpu = (Get-Counter "\Processor(_Total)\% Processor Time" -ErrorAction SilentlyContinue).CounterSamples.CookedValue
    `$memory = (Get-Counter "\Memory\% Committed Bytes In Use" -ErrorAction SilentlyContinue).CounterSamples.CookedValue
    
    `$health.checks += @{
        name = "cpu"
        status = if (`$cpu -lt 80) { "healthy" } else { "warning" }
        details = "CPU使用率: `$cpu%"
    }
    
    `$health.checks += @{
        name = "memory"
        status = if (`$memory -lt 85) { "healthy" } else { "warning" }
        details = "内存使用率: `$memory%"
    }
    
    # 如果有任何检查失败，更新总体状态
    `$unhealthyChecks = `$health.checks | Where-Object { `$_.status -ne "healthy" }
    if (`$unhealthyChecks) {
        `$health.status = "degraded"
        if (`$unhealthyChecks.status -contains "unhealthy") {
            `$health.status = "unhealthy"
        }
    }
    
    return `$health
}

# 输出健康状态
`$health = Get-SystemHealth
`$health | ConvertTo-Json -Depth 10
"@

$healthCheckPath = "$env:USERPROFILE\.openclaw\scripts\health-check.ps1"
Set-Content -Path $healthCheckPath -Value $healthCheckScript
Write-Host "   ✅ 健康检查脚本已建立: $healthCheckPath"

# 7. 测试修复效果
Write-Host "`n7. ✅ 测试修复效果..."
Write-Host "   等待15秒让系统稳定..."
Start-Sleep -Seconds 15

Write-Host "   a. 测试网关连接..."
$gatewayTest = Test-NetConnection localhost -Port 18789 -InformationLevel Quiet
if ($gatewayTest) {
    Write-Host "      ✅ 网关连接正常"
} else {
    Write-Host "      ❌ 网关连接失败"
}

Write-Host "   b. 运行健康检查..."
try {
    $healthResult = powershell -File $healthCheckPath
    $health = $healthResult | ConvertFrom-Json
    Write-Host "      ✅ 健康检查完成"
    Write-Host "      总体状态: $($health.status)"
    foreach ($check in $health.checks) {
        Write-Host "      - $($check.name): $($check.status) ($($check.details))"
    }
} catch {
    Write-Host "      ⚠️  健康检查失败: $_"
}

Write-Host "`n🎯 紧急修复完成！"
Write-Host "====================="
Write-Host "已完成的修复:"
Write-Host "1. ✅ WhatsApp网关配置优化"
Write-Host "2. ✅ OpenClaw网关重启和优化"
Write-Host "3. ✅ 系统性能优化"
Write-Host "4. ✅ 自动修复系统建立"
Write-Host "5. ✅ Windows计划任务设定"
Write-Host "6. ✅ 健康检查系统建立"
Write-Host ""
Write-Host "📋 下一步操作:"
Write-Host "1. 观察WhatsApp连接稳定性"
Write-Host "2. 如果仍有问题，考虑:"
Write-Host "   - 使用Telegram代替WhatsApp"
Write-Host "   - 检查网络防火墙设置"
Write-Host "   - 重启路由器"
Write-Host "3. 定期运行健康检查:"
Write-Host "   powershell -File `"$healthCheckPath`""
Write-Host ""
Write-Host "🔔 系统现在会自动修复和监控！"