# Create GitHub repository
# Note: GitHub Token should be passed as parameter or from environment variable

param(
    [string]$Token = $env:GITHUB_TOKEN
)

if (-not $Token) {
    Write-Host "Error: GitHub Token is required"
    Write-Host "Set environment variable: `$env:GITHUB_TOKEN = 'your_token'"
    Write-Host "Or pass as parameter: .\create-repo.ps1 -Token 'your_token'"
    exit 1
}

$repoName = "openclaw-workspace"

$headers = @{
    "Authorization" = "token $token"
    "Accept" = "application/vnd.github.v3+json"
}

$body = @{
    name = $repoName
    description = "OpenClaw workspace configuration and skills library"
    private = $false
    auto_init = $false
} | ConvertTo-Json

try {
    Write-Host "Creating repository: $repoName"
    $result = Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Method Post -Headers $headers -Body $body -ContentType "application/json"
    Write-Host "Repository created successfully!"
    Write-Host "URL: $($result.html_url)"
    Write-Host "Clone URL: $($result.clone_url)"
} catch {
    Write-Host "Error creating repository: $_"
    
    # Check if repository already exists
    try {
        $check = Invoke-RestMethod -Uri "https://api.github.com/repos/bsdkenneth-cloud/$repoName" -Headers $headers
        Write-Host "Repository already exists: $($check.html_url)"
    } catch {
        Write-Host "Repository does not exist and creation failed"
    }
}