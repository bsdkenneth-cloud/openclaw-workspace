# Simple n8n Installation Script

Write-Host "=== n8n Installation ==="

# 1. Check if Node.js is installed
Write-Host "`n1. Checking Node.js..."
$nodeVersion = node --version 2>$null
if ($nodeVersion) {
    Write-Host "   Node.js version: $nodeVersion"
} else {
    Write-Host "   Node.js not found. Please install Node.js first."
    Write-Host "   Download from: https://nodejs.org/"
    exit 1
}

# 2. Check if n8n is already installed
Write-Host "`n2. Checking n8n installation..."
$n8nVersion = n8n --version 2>$null
if ($n8nVersion) {
    Write-Host "   n8n is already installed: version $n8nVersion"
} else {
    Write-Host "   n8n not found. Installing..."
    
    # Install n8n globally
    npm install -g n8n
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   n8n installed successfully"
        $n8nVersion = n8n --version
        Write-Host "   n8n version: $n8nVersion"
    } else {
        Write-Host "   Failed to install n8n"
        exit 1
    }
}

# 3. Check if n8n is running
Write-Host "`n3. Checking n8n service..."
$n8nProcess = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {$_.Path -like "*n8n*"}
$portTest = Test-NetConnection localhost -Port 5678 -InformationLevel Quiet

if ($n8nProcess -or $portTest) {
    Write-Host "   n8n is running"
    Write-Host "   Access: http://localhost:5678"
} else {
    Write-Host "   n8n is not running"
    Write-Host "   To start n8n, run: n8n start"
    Write-Host "   Or start as service: nssm install n8n"
}

# 4. Set up n8n API key
Write-Host "`n4. Setting up n8n API key..."
$n8nApiKey = [Environment]::GetEnvironmentVariable("N8N_API_KEY", "User")
if ($n8nApiKey) {
    Write-Host "   N8N_API_KEY is already set"
} else {
    Write-Host "   N8N_API_KEY is not set"
    Write-Host "   To set it: [Environment]::SetEnvironmentVariable('N8N_API_KEY', 'your_key', 'User')"
}

# 5. Import workflows if config exists
Write-Host "`n5. Checking workflow configuration..."
$workflowConfig = "$env:USERPROFILE\.openclaw\workspace\config\n8n-config.json"
if (Test-Path $workflowConfig) {
    Write-Host "   Workflow configuration found"
    Write-Host "   To import: n8n import:workflow --input=$workflowConfig"
} else {
    Write-Host "   No workflow configuration found"
}

Write-Host "`n=== n8n Setup Complete ==="
Write-Host "Next steps:"
Write-Host "1. Start n8n: n8n start"
Write-Host "2. Access: http://localhost:5678"
Write-Host "3. Set API key: [Environment]::SetEnvironmentVariable('N8N_API_KEY', 'your_key', 'User')"
Write-Host "4. Import workflows: n8n import:workflow --input=$workflowConfig"