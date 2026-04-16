# GitHub Token设定脚本

Write-Host "🔑 GitHub Token设定"
Write-Host "=================="

# 1. 检查当前环境变量
Write-Host "1. 检查当前GitHub Token设定..."
$currentToken = [Environment]::GetEnvironmentVariable("GITHUB_TOKEN", "User")

if ($currentToken) {
    Write-Host "   ✅ 已设定GitHub Token"
    Write-Host "      前5位: $($currentToken.Substring(0, [Math]::Min(5, $currentToken.Length)))..."
    
    # 测试Token有效性
    Write-Host "   🔍 测试Token有效性..."
    $headers = @{
        "Authorization" = "token $currentToken"
        "Accept" = "application/vnd.github.v3+json"
    }
    
    try {
        $userInfo = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -ErrorAction Stop
        Write-Host "   ✅ Token有效 - 用户: $($userInfo.login)"
        Write-Host "      名称: $($userInfo.name)"
        Write-Host "      邮箱: $($userInfo.email)"
    } catch {
        Write-Host "   ❌ Token无效或已过期: $_"
        $currentToken = $null
    }
} else {
    Write-Host "   ⚠️  未设定GitHub Token"
}

# 2. 如果没有Token，提示用户设定
if (-not $currentToken) {
    Write-Host "`n2. 需要设定GitHub Personal Access Token"
    Write-Host "   ====================================="
    Write-Host "   请按照以下步骤操作："
    Write-Host ""
    Write-Host "   1. 访问: https://github.com/settings/tokens"
    Write-Host "   2. 点击 'Generate new token' → 'Generate new token (classic)'"
    Write-Host "   3. 设定Token名称: 'OpenClaw-Access'"
    Write-Host "   4. 选择权限:"
    Write-Host "      - repo (全选)"
    Write-Host "      - workflow"
    Write-Host "      - write:packages"
    Write-Host "      - delete:packages"
    Write-Host "   5. 点击 'Generate token'"
    Write-Host "   6. 复制生成的Token"
    Write-Host ""
    
    $newToken = Read-Host "   请输入你的GitHub Token" -AsSecureString
    $tokenPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($newToken)
    )
    
    if ($tokenPlain) {
        # 设定环境变量
        [System.Environment]::SetEnvironmentVariable('GITHUB_TOKEN', $tokenPlain, 'User')
        Write-Host "   ✅ GitHub Token已设定"
        
        # 测试新Token
        $headers = @{
            "Authorization" = "token $tokenPlain"
            "Accept" = "application/vnd.github.v3+json"
        }
        
        try {
            $userInfo = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -ErrorAction Stop
            Write-Host "   ✅ Token测试成功 - 用户: $($userInfo.login)"
        } catch {
            Write-Host "   ❌ Token测试失败: $_"
        }
    }
}

# 3. 设定GitHub远程仓库
Write-Host "`n3. 设定GitHub远程仓库..."
cd ~/.openclaw/workspace

$remoteUrl = git remote get-url origin 2>$null
if ($remoteUrl) {
    Write-Host "   ✅ 已设定远程仓库: $remoteUrl"
} else {
    Write-Host "   ⚠️  未设定远程仓库"
    Write-Host ""
    Write-Host "   请先在GitHub建立仓库："
    Write-Host "   1. 访问: https://github.com/new"
    Write-Host "   2. 仓库名称: openclaw-workspace"
    Write-Host "   3. 描述: OpenClaw工作空间配置和技能库"
    Write-Host "   4. 选择: Public 或 Private"
    Write-Host "   5. 不要勾选 'Initialize this repository with:'"
    Write-Host "   6. 点击 'Create repository'"
    Write-Host ""
    
    $githubUsername = Read-Host "   请输入你的GitHub用户名"
    $repoUrl = "https://github.com/$githubUsername/openclaw-workspace.git"
    
    Write-Host "   设定远程仓库: $repoUrl"
    git remote add origin $repoUrl
    Write-Host "   ✅ 远程仓库已设定"
}

# 4. 推送代码到GitHub
Write-Host "`n4. 推送代码到GitHub..."
try {
    git push -u origin main
    Write-Host "   ✅ 代码推送成功"
} catch {
    Write-Host "   ⚠️  代码推送失败: $_"
    Write-Host "      可能是第一次推送，需要先拉取"
    try {
        git pull origin main --allow-unrelated-histories
        git push -u origin main
        Write-Host "   ✅ 代码推送成功（合并后）"
    } catch {
        Write-Host "   ❌ 仍然失败，请手动处理"
    }
}

# 5. 设定GitHub Webhook（可选）
Write-Host "`n5. 设定GitHub Webhook（可选）..."
Write-Host "   如果需要自动同步，可以设定Webhook："
Write-Host "   1. 访问你的仓库 Settings → Webhooks"
Write-Host "   2. 点击 'Add webhook'"
Write-Host "   3. Payload URL: http://你的服务器/webhook/github"
Write-Host "   4. Content type: application/json"
Write-Host "   5. 选择事件: Just the push event"
Write-Host "   6. 点击 'Add webhook'"

Write-Host "`n🎯 GitHub设定完成"
Write-Host "=================="
Write-Host "下一步："
Write-Host "1. 测试GitHub连接: git pull"
Write-Host "2. 测试自动提交: 修改文件后查看git status"
Write-Host "3. 检查GitHub仓库: 访问你的仓库页面"