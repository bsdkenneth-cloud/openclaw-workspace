# OpenClaw 模型自我修復腳本
# 當用量過大或模型故障時自動執行

param(
    [string]$IssueType = "high_usage",  # high_usage, deepseek_failed, ollama_failed
    [int]$DailyCost = 0
)

Write-Host "🔧 OpenClaw 模型修復腳本啟動"
Write-Host "問題類型: $IssueType"
Write-Host "日費用: $$DailyCost"

switch ($IssueType) {
    "high_usage" {
        Write-Host "📈 檢測到高用量，啟用分流策略"
        
        # 檢查Ollama狀態
        $ollamaStatus = tasklist | findstr ollama.exe
        if (-not $ollamaStatus) {
            Write-Host "🔄 啟動Ollama服務"
            Start-Process "ollama" "serve" -WindowStyle Hidden
            Start-Sleep -Seconds 5
        }
        
        # 檢查phi3:mini模型
        Write-Host "🔍 檢查phi3:mini模型"
        $models = ollama list 2>$null
        if ($models -like "*phi3:mini*") {
            Write-Host "✅ phi3:mini模型已就緒"
            
            # 更新OpenClaw配置，添加Ollama為備用
            $configPath = "$env:USERPROFILE\.openclaw\openclaw.json"
            $config = Get-Content $configPath | ConvertFrom-Json
            
            # 添加Ollama到備用模型
            $config.agents.defaults.model.fallbacks = @("ollama/phi3:mini")
            
            $config | ConvertTo-Json -Depth 10 | Set-Content $configPath
            Write-Host "✅ 已添加Ollama為備用模型"
            
            # 建議使用模式
            Write-Host "💡 建議："
            Write-Host "  1. 簡單任務使用Ollama（免費）"
            Write-Host "  2. 複雜任務使用DeepSeek"
            Write-Host "  3. 預計可節省50%費用"
        } else {
            Write-Host "⚠️ phi3:mini未就緒，嘗試下載"
            ollama pull phi3:mini
        }
    }
    
    "deepseek_failed" {
        Write-Host "🔴 DeepSeek故障，切換到Ollama"
        
        # 更新配置，將Ollama設為主要
        $configPath = "$env:USERPROFILE\.openclaw\openclaw.json"
        $config = Get-Content $configPath | ConvertFrom-Json
        
        $config.agents.defaults.model.primary = "ollama/phi3:mini"
        $config.agents.defaults.model.fallbacks = @()
        
        $config | ConvertTo-Json -Depth 10 | Set-Content $configPath
        Write-Host "✅ 已切換到Ollama為主要模型"
        
        # 發送通知
        Write-Host "📢 已自動切換到本地Ollama模型"
        Write-Host "   - 費用：$0"
        Write-Host "   - 速度：較慢"
        Write-Host "   - 隱私：100%本地"
    }
    
    "ollama_failed" {
        Write-Host "🔴 Ollama故障，嘗試修復"
        
        # 停止Ollama
        taskkill /f /im ollama.exe 2>$null
        
        # 重新啟動
        Start-Process "ollama" "serve" -WindowStyle Hidden
        Start-Sleep -Seconds 10
        
        # 測試
        $testResult = ollama run phi3:mini "test" 2>$null
        if ($testResult) {
            Write-Host "✅ Ollama修復成功"
        } else {
            Write-Host "❌ Ollama修復失敗，重新下載模型"
            ollama rm phi3:mini 2>$null
            ollama pull phi3:mini
        }
    }
}

Write-Host "🎯 修復完成"
Write-Host "下次檢查時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"