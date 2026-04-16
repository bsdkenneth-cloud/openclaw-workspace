# Set GitHub Token directly

param(
    [string]$Token
)

if (-not $Token) {
    Write-Host "Error: Token parameter is required"
    Write-Host "Usage: .\set-github-token.ps1 -Token 'your_github_token'"
    exit 1
}

# Set environment variable
[System.Environment]::SetEnvironmentVariable('GITHUB_TOKEN', $Token, 'User')
Write-Host "GitHub Token has been set in User environment variables"

# Test the token
$headers = @{
    "Authorization" = "token $Token"
    "Accept" = "application/vnd.github.v3+json"
}

try {
    $userInfo = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -ErrorAction Stop
    Write-Host "Token is valid - User: $($userInfo.login)"
    Write-Host "Name: $($userInfo.name)"
    Write-Host "Email: $($userInfo.email)"
} catch {
    Write-Host "Warning: Token test failed - $_"
    Write-Host "The token has been set, but may be invalid"
}

Write-Host "`nTo use the token in current session, also set:"
Write-Host "`$env:GITHUB_TOKEN = '$Token'"