# GitHub Token Setup Script

Write-Host "GitHub Token Setup"
Write-Host "=================="

# Check current token
$currentToken = [Environment]::GetEnvironmentVariable("GITHUB_TOKEN", "User")

if ($currentToken) {
    Write-Host "GitHub Token is already set"
    
    # Test the token
    $headers = @{
        "Authorization" = "token $currentToken"
        "Accept" = "application/vnd.github.v3+json"
    }
    
    try {
        $userInfo = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -ErrorAction Stop
        Write-Host "Token is valid - User: $($userInfo.login)"
        Write-Host "Name: $($userInfo.name)"
        Write-Host "Email: $($userInfo.email)"
        exit 0
    } catch {
        Write-Host "Token is invalid or expired"
        $currentToken = $null
    }
}

if (-not $currentToken) {
    Write-Host "`nGitHub Personal Access Token is required"
    Write-Host "Please follow these steps:"
    Write-Host ""
    Write-Host "1. Go to: https://github.com/settings/tokens"
    Write-Host "2. Click 'Generate new token' -> 'Generate new token (classic)'"
    Write-Host "3. Set Token name: 'OpenClaw-Access'"
    Write-Host "4. Select scopes:"
    Write-Host "   - repo (all)"
    Write-Host "   - workflow"
    Write-Host "5. Click 'Generate token'"
    Write-Host "6. Copy the generated token"
    Write-Host ""
    
    $tokenInput = Read-Host "Please enter your GitHub Token"
    
    if ($tokenInput) {
        # Set environment variable
        [System.Environment]::SetEnvironmentVariable('GITHUB_TOKEN', $tokenInput, 'User')
        Write-Host "GitHub Token has been set"
        
        # Test the new token
        $headers = @{
            "Authorization" = "token $tokenInput"
            "Accept" = "application/vnd.github.v3+json"
        }
        
        try {
            $userInfo = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -ErrorAction Stop
            Write-Host "Token test successful - User: $($userInfo.login)"
        } catch {
            Write-Host "Token test failed"
        }
    }
}

Write-Host "`nGitHub setup completed"
Write-Host "======================"