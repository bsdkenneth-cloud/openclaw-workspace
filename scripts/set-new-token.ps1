# Set new GitHub Token
# Usage: .\set-new-token.ps1 -Token "your_github_token"

param(
    [string]$Token
)

if (-not $Token) {
    Write-Host "Error: Token parameter is required"
    Write-Host "Usage: .\set-new-token.ps1 -Token 'your_github_token'"
    exit 1
}

# Set in User environment
[System.Environment]::SetEnvironmentVariable('GITHUB_TOKEN', $Token, 'User')
Write-Host "GitHub Token set in User environment"

# Set in current session
$env:GITHUB_TOKEN = $Token
Write-Host "GitHub Token set in current session"

# Test the token
$headers = @{
    "Authorization" = "token $Token"
    "Accept" = "application/vnd.github.v3+json"
}

try {
    $userInfo = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -ErrorAction Stop
    Write-Host "Token test successful - User: $($userInfo.login)"
    Write-Host "Name: $($userInfo.name)"
    Write-Host "Email: $($userInfo.email)"
} catch {
    Write-Host "Token test failed: $_"
}

Write-Host "`nReady to push to GitHub"