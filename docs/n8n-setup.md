# n8n 集成設定指南

## 1. 安裝n8n

### 方法1: npm安裝 (推薦)
```bash
npm install -g n8n
```

### 方法2: Docker安裝
```bash
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
```

### 方法3: Windows安裝
1. 下載Node.js: https://nodejs.org/
2. 安裝n8n:
   ```powershell
   npm install -g n8n
   ```

## 2. 啟動n8n

### 開發模式:
```bash
n8n start
```

### 生產模式:
```bash
n8n start --tunnel
```

### Windows服務:
```powershell
# 建立n8n服務
nssm install n8n "C:\Program Files\nodejs\node.exe" "C:\Users\你的用戶名\AppData\Roaming\npm\node_modules\n8n\bin\n8n" "start"
```

## 3. 存取n8n
- URL: http://localhost:5678
- 預設憑證: 首次啟動時設定

## 4. 設定OpenClaw Webhook

### 建立Webhook工作流程:
1. 在n8n中建立新工作流程
2. 新增 "Webhook" 節點
3. 設定:
   - Webhook方法: POST
   - Path: `/webhook/openclaw`
   - Response Mode: Respond to Webhook
   - Options: No Response Body

### 範例工作流程:
```
Webhook (接收) → Function (處理) → OpenClaw (執行)
```

## 5. 設定環境變數

### Windows PowerShell:
```powershell
# 設定n8n API金鑰
[System.Environment]::SetEnvironmentVariable('N8N_API_KEY', '你的n8n_API_KEY', 'User')

# 設定Webhook URL
[System.Environment]::SetEnvironmentVariable('N8N_WEBHOOK_URL', 'http://localhost:5678/webhook/openclaw', 'User')
```

## 6. 測試連接

### 測試Webhook:
```powershell
$webhookUrl = "http://localhost:5678/webhook/openclaw"
$payload = @{
    event = "test"
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    message = "測試OpenClaw連接"
} | ConvertTo-Json

Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType "application/json"
```

### 測試API:
```powershell
$headers = @{
    "X-N8N-API-KEY" = $env:N8N_API_KEY
}

Invoke-RestMethod -Uri "http://localhost:5678/rest/health" -Headers $headers
```

## 7. 自動化工作流程範例

### 工作流程1: GitHub事件處理
```json
{
  "nodes": [
    {
      "name": "GitHub Webhook",
      "type": "n8n-nodes-base.webhook",
      "position": [250, 300],
      "parameters": {
        "path": "/webhook/github",
        "responseMode": "responseNode"
      }
    },
    {
      "name": "處理GitHub事件",
      "type": "n8n-nodes-base.function",
      "position": [450, 300],
      "parameters": {
        "jsCode": "const event = items[0].json;\nif (event.action === 'opened' && event.issue) {\n  return [{ json: { type: 'github_issue', data: event.issue }}];\n}\nreturn [];"
      }
    },
    {
      "name": "發送到OpenClaw",
      "type": "n8n-nodes-base.httpRequest",
      "position": [650, 300],
      "parameters": {
        "url": "http://localhost:18789/api/events",
        "authentication": "genericCredentialType",
        "genericAuthType": "httpHeaderAuth",
        "sendHeaders": true,
        "headerParameters": {
          "parameters": [
            {
              "name": "Authorization",
              "value": "Bearer YOUR_OPENCLAW_TOKEN"
            }
          ]
        }
      }
    }
  ]
}
```

### 工作流程2: OpenClaw監控
```json
{
  "nodes": [
    {
      "name": "排程觸發",
      "type": "n8n-nodes-base.scheduleTrigger",
      "position": [250, 300],
      "parameters": {
        "rule": {
          "interval": [
            {
              "field": "minutes",
              "minutesInterval": 30
            }
          ]
        }
      }
    },
    {
      "name": "檢查OpenClaw狀態",
      "type": "n8n-nodes-base.httpRequest",
      "position": [450, 300],
      "parameters": {
        "url": "http://localhost:18789/api/status",
        "authentication": "genericCredentialType",
        "genericAuthType": "httpHeaderAuth"
      }
    },
    {
      "name": "發送警報",
      "type": "n8n-nodes-base.if",
      "position": [650, 300],
      "parameters": {
        "conditions": {
          "string": [
            {
              "value1": "={{$json.status}}",
              "operation": "notEquals",
              "value2": "healthy"
            }
          ]
        }
      }
    }
  ]
}
```

## 8. 整合到OpenClaw

配置已自動載入：
- n8n實例URL: http://localhost:5678
- Webhook路徑: /webhook/openclaw
- API金鑰: 從環境變數讀取

## 9. 疑難排解

### 問題1: n8n無法啟動
```bash
# 檢查端口占用
netstat -ano | findstr :5678

# 清除n8n快取
rm -rf ~/.n8n
```

### 問題2: Webhook無法接收
```powershell
# 檢查n8n日誌
n8n start --verbose

# 測試Webhook
curl -X POST http://localhost:5678/webhook/openclaw -H "Content-Type: application/json" -d '{"test":true}'
```

### 問題3: 連線問題
```powershell
# 測試網路連線
Test-NetConnection localhost -Port 5678

# 檢查防火牆
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*n8n*"}
```

## 10. 進階設定

### 安全設定:
```bash
# 啟用SSL
n8n start --ssl-key=key.pem --ssl-cert=cert.pem

# 啟用認證
n8n start --basic-auth-user=admin --basic-auth-password=password
```

### 效能優化:
```bash
# 增加記憶體限制
export NODE_OPTIONS="--max-old-space-size=4096"
n8n start
```

### 備份設定:
```bash
# 自動備份工作流程
n8n export:workflow --all --output=backup.json
```