# 批量安裝OpenClaw Skills腳本

$skills = @(
    # 已確認可安裝
    "self-improving-agent",
    "openclaw-tavily-search",
    
    # 需要搜索的skills
    "find-skills",
    "remind-me", 
    "feishu-toolkit",
    "summarize",
    "agent-browser",
    "nano-pdf",
    "skill-vetter",
    "humanizer",
    "free-ride",
    "api-gateway",
    "youtube-transcript",
    "auto-updater",
    "openai-whisper"
)

Write-Host "🔍 開始安裝Skills..."
Write-Host "總共需要安裝: $($skills.Count) 個skills"
Write-Host ""

foreach ($skill in $skills) {
    Write-Host "📦 嘗試安裝: $skill"
    
    try {
        # 先搜索
        Write-Host "  🔎 搜索 $skill..."
        $searchResult = clawhub search $skill 2>&1
        
        if ($searchResult -like "*not found*" -or $searchResult -like "*Error*") {
            Write-Host "  ⚠️  未找到 $skill，嘗試其他名稱..."
            
            # 嘗試常見變體
            $variants = @(
                "openclaw-$skill",
                "$skill-skill",
                "$skill-tool",
                "$skill-for-openclaw"
            )
            
            $installed = $false
            foreach ($variant in $variants) {
                Write-Host "  🔄 嘗試變體: $variant"
                $installResult = clawhub install $variant 2>&1
                if ($installResult -like "*OK*") {
                    Write-Host "  ✅ 成功安裝: $variant"
                    $installed = $true
                    break
                }
            }
            
            if (-not $installed) {
                Write-Host "  ❌ 無法安裝 $skill"
            }
        } else {
            # 直接安裝
            $installResult = clawhub install $skill 2>&1
            if ($installResult -like "*OK*") {
                Write-Host "  ✅ 成功安裝: $skill"
            } else {
                Write-Host "  ❌ 安裝失敗: $skill"
                Write-Host "    錯誤: $installResult"
            }
        }
    } catch {
        Write-Host "  ❌ 安裝過程錯誤: $_"
    }
    
    Write-Host ""
}

Write-Host "🎯 安裝完成！"
Write-Host "已安裝skills位置: ~/.openclaw/workspace/skills/"
Write-Host ""
Write-Host "下一步："
Write-Host "1. 檢查已安裝的skills"
Write-Host "2. 配置必要的API金鑰"
Write-Host "3. 測試功能"