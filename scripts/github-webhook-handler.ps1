# GitHub Webhook處理器
# 接收GitHub事件並轉發到n8n和OpenClaw

param(
    [Parameter(Mandatory=$true)]
    [string]$EventType,
    
    [Parameter(Mandatory=$true)]
    [string]$Payload
)

Write-Host "📥 GitHub Webhook事件: $EventType"
Write-Host "時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# 解析Payload
$eventData = $Payload | ConvertFrom-Json

# 記錄事件
$logEntry = @{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    event = $EventType
    repository = $eventData.repository.full_name
    action = $eventData.action
    sender = $eventData.sender.login
} | ConvertTo-Json

Add-Content -Path "~/.openclaw/workspace/logs/github-events.log" -Value $logEntry

# 根據事件類型處理
switch ($EventType) {
    "push" {
        Write-Host "🔀 處理Push事件"
        Handle-PushEvent -EventData $eventData
    }
    
    "pull_request" {
        Write-Host "🔀 處理Pull Request事件"
        Handle-PullRequestEvent -EventData $eventData
    }
    
    "issues" {
        Write-Host "🔀 處理Issue事件"
        Handle-IssueEvent -EventData $eventData
    }
    
    default {
        Write-Host "⚠️  未知事件類型: $EventType"
    }
}

function Handle-PushEvent {
    param($EventData)
    
    $commitCount = $EventData.commits.Count
    $branch = $EventData.ref -replace "refs/heads/", ""
    
    Write-Host "   📊 提交數量: $commitCount"
    Write-Host "   🌿 分支: $branch"
    Write-Host "   👤 提交者: $($EventData.pusher.name)"
    
    # 轉發到n8n
    $n8nPayload = @{
        source = "github"
        event = "push"
        repository = $EventData.repository.full_name
        branch = $branch
        commitCount = $commitCount
        commits = $EventData.commits
        pusher = $EventData.pusher
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    } | ConvertTo-Json
    
    Send-ToN8N -Payload $n8nPayload -Workflow "github-sync"
    
    # 轉發到OpenClaw
    $openclawPayload = @{
        type = "github_push"
        data = @{
            repository = $EventData.repository.full_name
            branch = $branch
            message = "收到 $commitCount 個新提交"
        }
    } | ConvertTo-Json
    
    Send-ToOpenClaw -Payload $openclawPayload
}

function Handle-PullRequestEvent {
    param($EventData)
    
    $prNumber = $EventData.number
    $prAction = $EventData.action
    $prTitle = $EventData.pull_request.title
    
    Write-Host "   🔢 PR編號: $prNumber"
    Write-Host "   📝 標題: $prTitle"
    Write-Host "   ⚡ 動作: $prAction"
    
    # 轉發到n8n
    $n8nPayload = @{
        source = "github"
        event = "pull_request"
        action = $prAction
        repository = $EventData.repository.full_name
        prNumber = $prNumber
        prTitle = $prTitle
        author = $EventData.sender.login
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    } | ConvertTo-Json
    
    Send-ToN8N -Payload $n8nPayload -Workflow "pr-review"
    
    # 如果是opened或reopened，觸發自動審查
    if ($prAction -in @("opened", "reopened")) {
        Write-Host "   🔍 觸發PR自動審查"
        
        $reviewPayload = @{
            type = "github_pr_review"
            data = @{
                repository = $EventData.repository.full_name
                prNumber = $prNumber
                prTitle = $prTitle
                author = $EventData.sender.login
                url = $EventData.pull_request.html_url
            }
        } | ConvertTo-Json
        
        Send-ToOpenClaw -Payload $reviewPayload
    }
}

function Handle-IssueEvent {
    param($EventData)
    
    $issueNumber = $EventData.issue.number
    $issueAction = $EventData.action
    $issueTitle = $EventData.issue.title
    
    Write-Host "   🔢 Issue編號: $issueNumber"
    Write-Host "   📝 標題: $issueTitle"
    Write-Host "   ⚡ 動作: $issueAction"
    
    # 轉發到n8n
    $n8nPayload = @{
        source = "github"
        event = "issue"
        action = $issueAction
        repository = $EventData.repository.full_name
        issueNumber = $issueNumber
        issueTitle = $issueTitle
        author = $EventData.sender.login
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    } | ConvertTo-Json
    
    Send-ToN8N -Payload $n8nPayload -Workflow "issue-tracker"
    
    # 如果是opened，觸發自動分類
    if ($issueAction -eq "opened") {
        Write-Host "   🏷️  觸發Issue自動分類"
        
        $classificationPayload = @{
            type = "github_issue_classify"
            data = @{
                repository = $EventData.repository.full_name
                issueNumber = $issueNumber
                issueTitle = $issueTitle
                body = $EventData.issue.body
                author = $EventData.sender.login
            }
        } | ConvertTo-Json
        
        Send-ToOpenClaw -Payload $classificationPayload
    }
}

function Send-ToN8N {
    param(
        [string]$Payload,
        [string]$Workflow
    )
    
    $n8nUrl = "http://localhost:5678/webhook/$Workflow"
    
    try {
        $response = Invoke-RestMethod -Uri $n8nUrl -Method Post -Body $Payload -ContentType "application/json" -ErrorAction Stop
        Write-Host "   ✅ 成功轉發到n8n ($Workflow)"
        return $true
    } catch {
        Write-Host "   ❌ n8n轉發失敗: $_"
        return $false
    }
}

function Send-ToOpenClaw {
    param([string]$Payload)
    
    $openclawUrl = "http://localhost:18789/api/events"
    
    try {
        $headers = @{
            "Authorization" = "Bearer 5ef38dca1acb459b7fbb08e630da0b08a49f26cc3520c2f2"
            "Content-Type" = "application/json"
        }
        
        $response = Invoke-RestMethod -Uri $openclawUrl -Method Post -Body $Payload -Headers $headers -ErrorAction Stop
        Write-Host "   ✅ 成功轉發到OpenClaw"
        return $true
    } catch {
        Write-Host "   ❌ OpenClaw轉發失敗: $_"
        return $false
    }
}

Write-Host "🎯 GitHub Webhook處理完成"
Write-Host "=========================="