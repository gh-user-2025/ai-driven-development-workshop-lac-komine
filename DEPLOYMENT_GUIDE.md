# デプロイメント手順書

## 1. デプロイメント概要

### 1.1 デプロイメント戦略
- **ブルーグリーンデプロイメント**: 本番環境での安全なデプロイ
- **段階的リリース**: 開発 → ステージング → 本番の順でリリース
- **自動化**: Azure DevOps パイプラインによる CI/CD

### 1.2 環境構成
```
開発環境 (Development)
├── Azure Functions (Consumption Plan)
├── Azure SQL Database (Basic)
└── Azure Cosmos DB (Shared throughput)

ステージング環境 (Staging)  
├── Azure Functions (Premium Plan)
├── Azure SQL Database (Standard)
└── Azure Cosmos DB (Dedicated throughput)

本番環境 (Production)
├── Azure Functions (Premium Plan)
├── Azure SQL Database (Premium)
├── Azure Cosmos DB (Dedicated throughput)
└── Application Gateway (Load Balancer)
```

## 2. 事前準備

### 2.1 必要なツール・権限
```bash
# 必要なツールの確認
az --version
node --version
npm --version
python --version

# 必要な権限
# - Azure サブスクリプションのContributor権限
# - Azure DevOps プロジェクトの管理者権限
# - GitHub リポジトリへの書き込み権限
```

### 2.2 環境変数の設定
```bash
# 共通設定
export SUBSCRIPTION_ID="your-subscription-id"
export TENANT_ID="your-tenant-id"
export LOCATION="japaneast"

# 環境別設定
export ENV="dev"  # dev, staging, prod
export RESOURCE_GROUP_NAME="rg-factory-management-${ENV}"
export APP_NAME="factory-management-${ENV}"
```

## 3. Azure DevOps パイプライン設定

### 3.1 サービス接続の作成
```bash
# Azure Resource Manager サービス接続作成
az ad sp create-for-rbac --name "factory-management-sp" \
  --role contributor \
  --scopes /subscriptions/${SUBSCRIPTION_ID}

# 出力された値をAzure DevOpsのサービス接続に設定
# - Application (client) ID
# - Directory (tenant) ID  
# - Client Secret
```

### 3.2 パイプライン変数の設定
```yaml
# Azure DevOps パイプライン変数
variables:
  # Azure 設定
  azureSubscription: 'factory-management-connection'
  
  # アプリケーション設定
  functionAppName: 'func-factory-management-$(Environment.Name)'
  resourceGroupName: 'rg-factory-management-$(Environment.Name)'
  
  # ビルド設定
  pythonVersion: '3.9'
  nodeVersion: '16.x'
  
  # セキュリティ設定（変数グループで管理）
  sqlConnectionString: '$(SqlConnectionString)'
  cosmosDbConnectionString: '$(CosmosDbConnectionString)'
```

### 3.3 ビルドパイプライン（azure-pipelines.yml）
```yaml
trigger:
  branches:
    include:
    - main
    - develop
  paths:
    include:
    - backend/*
    - frontend/*

pool:
  vmImage: 'ubuntu-latest'

variables:
  pythonVersion: '3.9'
  nodeVersion: '16.x'

stages:
- stage: Build
  displayName: 'Build Application'
  jobs:
  
  # Backend (Azure Functions) ビルド
  - job: BuildBackend
    displayName: 'Build Backend'
    steps:
    - task: UsePythonVersion@0
      inputs:
        versionSpec: '$(pythonVersion)'
      displayName: 'Use Python $(pythonVersion)'
    
    - script: |
        cd backend
        python -m pip install --upgrade pip
        pip install -r requirements.txt
      displayName: 'Install Backend Dependencies'
    
    - script: |
        cd backend
        python -m pytest tests/ --junitxml=test-results.xml --cov=. --cov-report=xml
      displayName: 'Run Backend Tests'
    
    - task: PublishTestResults@2
      inputs:
        testResultsFiles: 'backend/test-results.xml'
        testRunTitle: 'Backend Tests'
      condition: succeededOrFailed()
    
    - task: ArchiveFiles@2
      inputs:
        rootFolderOrFile: 'backend'
        includeRootFolder: false
        archiveType: 'zip'
        archiveFile: '$(Build.ArtifactStagingDirectory)/backend.zip'
      displayName: 'Archive Backend'
    
    - publish: '$(Build.ArtifactStagingDirectory)/backend.zip'
      artifact: backend
      displayName: 'Publish Backend Artifact'
  
  # Frontend (Vue.js) ビルド
  - job: BuildFrontend
    displayName: 'Build Frontend'
    steps:
    - task: NodeTool@0
      inputs:
        versionSpec: '$(nodeVersion)'
      displayName: 'Use Node.js $(nodeVersion)'
    
    - script: |
        cd frontend
        npm ci
      displayName: 'Install Frontend Dependencies'
    
    - script: |
        cd frontend
        npm run test:unit
      displayName: 'Run Frontend Tests'
    
    - script: |
        cd frontend
        npm run build
      displayName: 'Build Frontend'
    
    - task: ArchiveFiles@2
      inputs:
        rootFolderOrFile: 'frontend/dist'
        includeRootFolder: false
        archiveType: 'zip'
        archiveFile: '$(Build.ArtifactStagingDirectory)/frontend.zip'
      displayName: 'Archive Frontend'
    
    - publish: '$(Build.ArtifactStagingDirectory)/frontend.zip'
      artifact: frontend
      displayName: 'Publish Frontend Artifact'

- stage: DeployDev
  displayName: 'Deploy to Development'
  dependsOn: Build
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/develop'))
  jobs:
  - deployment: DeployBackendDev
    displayName: 'Deploy Backend to Dev'
    environment: 'Development'
    strategy:
      runOnce:
        deploy:
          steps:
          - download: current
            artifact: backend
          
          - task: AzureFunctionApp@1
            inputs:
              azureSubscription: '$(azureSubscription)'
              appType: 'functionAppLinux'
              appName: 'func-factory-management-dev'
              package: '$(Pipeline.Workspace)/backend/backend.zip'
              runtimeStack: 'PYTHON|3.9'

- stage: DeployProd
  displayName: 'Deploy to Production'
  dependsOn: Build
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: DeployBackendProd
    displayName: 'Deploy Backend to Production'
    environment: 'Production'
    strategy:
      runOnce:
        deploy:
          steps:
          - download: current
            artifact: backend
          
          - task: AzureFunctionApp@1
            inputs:
              azureSubscription: '$(azureSubscription)'
              appType: 'functionAppLinux'
              appName: 'func-factory-management-prod'
              package: '$(Pipeline.Workspace)/backend/backend.zip'
              runtimeStack: 'PYTHON|3.9'
```

## 4. 手動デプロイメント手順

### 4.1 Backend（Azure Functions）デプロイ

#### 開発環境への手動デプロイ
```bash
# Azure Functions Core Tools を使用
cd backend

# ローカルでテスト実行
func start

# Azure にデプロイ
func azure functionapp publish func-factory-management-dev

# デプロイ確認
az functionapp show --name func-factory-management-dev --resource-group rg-factory-management-dev
```

#### アプリケーション設定の更新
```bash
# 環境変数設定
az functionapp config appsettings set \
  --name func-factory-management-dev \
  --resource-group rg-factory-management-dev \
  --settings \
    "SqlConnectionString=${SQL_CONNECTION_STRING}" \
    "CosmosDbConnectionString=${COSMOS_CONNECTION_STRING}" \
    "APPINSIGHTS_INSTRUMENTATIONKEY=${INSTRUMENTATION_KEY}"
```

### 4.2 Frontend（Vue.js）デプロイ

#### Azure Static Web Apps へのデプロイ
```bash
# 静的Webアプリリソース作成
az staticwebapp create \
  --name "swa-factory-management-dev" \
  --resource-group rg-factory-management-dev \
  --source "https://github.com/your-org/factory-management" \
  --location "East Asia" \
  --branch "develop" \
  --app-location "frontend" \
  --output-location "dist"

# ビルドと手動デプロイ
cd frontend
npm run build

# SWA CLI を使用した手動デプロイ
npm install -g @azure/static-web-apps-cli
swa deploy ./dist --deployment-token $SWA_DEPLOYMENT_TOKEN
```

#### App Service へのデプロイ（代替案）
```bash
# App Service 作成
az appservice plan create \
  --name "asp-factory-management-dev" \
  --resource-group rg-factory-management-dev \
  --sku FREE \
  --is-linux

az webapp create \
  --name "app-factory-management-dev" \
  --resource-group rg-factory-management-dev \
  --plan "asp-factory-management-dev" \
  --runtime "NODE|16-lts"

# デプロイ
cd frontend
npm run build
zip -r dist.zip dist/

az webapp deployment source config-zip \
  --name "app-factory-management-dev" \
  --resource-group rg-factory-management-dev \
  --src dist.zip
```

## 5. データベースマイグレーション

### 5.1 SQL Database スキーマデプロイ
```bash
# SQL スクリプト実行
sqlcmd -S ${SQL_SERVER_NAME}.database.windows.net \
  -d ${SQL_DATABASE_NAME} \
  -U ${SQL_ADMIN_USER} \
  -P ${SQL_ADMIN_PASSWORD} \
  -i ./data/sql-scripts/001_create_tables.sql

# または Azure CLI を使用
az sql db query \
  --server ${SQL_SERVER_NAME} \
  --name ${SQL_DATABASE_NAME} \
  --query "$(cat ./data/sql-scripts/001_create_tables.sql)"
```

### 5.2 Cosmos DB 初期設定
```bash
# Cosmos DB コンテナとインデックス設定
az cosmosdb sql container create \
  --account-name ${COSMOS_ACCOUNT_NAME} \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --database-name "FactoryIoTData" \
  --name "SensorData" \
  --partition-key-path "/deviceId" \
  --throughput 400 \
  --idx @./data/cosmos-indexes.json
```

### 5.3 初期データ投入
```python
# Python スクリプトによる初期データ投入
python ./data/scripts/seed_data.py \
  --sql-connection "${SQL_CONNECTION_STRING}" \
  --cosmos-connection "${COSMOS_CONNECTION_STRING}"
```

## 6. 環境設定とシークレット管理

### 6.1 Azure Key Vault 設定
```bash
# Key Vault 作成
az keyvault create \
  --name "kv-factory-management-${ENV}" \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --location ${LOCATION}

# シークレット設定
az keyvault secret set \
  --vault-name "kv-factory-management-${ENV}" \
  --name "SqlConnectionString" \
  --value "${SQL_CONNECTION_STRING}"

az keyvault secret set \
  --vault-name "kv-factory-management-${ENV}" \
  --name "CosmosDbConnectionString" \
  --value "${COSMOS_CONNECTION_STRING}"
```

### 6.2 Managed Identity 設定
```bash
# Function App にマネージドアイデンティティ設定
az functionapp identity assign \
  --name func-factory-management-${ENV} \
  --resource-group ${RESOURCE_GROUP_NAME}

# Key Vault アクセス許可
PRINCIPAL_ID=$(az functionapp identity show \
  --name func-factory-management-${ENV} \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --query principalId -o tsv)

az keyvault set-policy \
  --name "kv-factory-management-${ENV}" \
  --object-id ${PRINCIPAL_ID} \
  --secret-permissions get list
```

## 7. 監視とログ設定

### 7.1 Application Insights 設定
```bash
# Application Insights リソース作成
az monitor app-insights component create \
  --app "appi-factory-management-${ENV}" \
  --location ${LOCATION} \
  --resource-group ${RESOURCE_GROUP_NAME}

# インストルメンテーションキー取得
INSTRUMENTATION_KEY=$(az monitor app-insights component show \
  --app "appi-factory-management-${ENV}" \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --query instrumentationKey -o tsv)
```

### 7.2 アラート設定
```bash
# メトリックアラート作成（例：Function App エラー率）
az monitor metrics alert create \
  --name "FunctionApp-ErrorRate-${ENV}" \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --target-resource-id "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Web/sites/func-factory-management-${ENV}" \
  --metric-name "Http5xx" \
  --operator GreaterThan \
  --threshold 5 \
  --aggregation Total \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action-group-ids "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/microsoft.insights/actionGroups/factory-management-alerts"
```

## 8. バックアップとディザスタリカバリ

### 8.1 自動バックアップ設定
```bash
# SQL Database 自動バックアップ設定
az sql db ltr-policy set \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --server ${SQL_SERVER_NAME} \
  --database ${SQL_DATABASE_NAME} \
  --weekly-retention P4W \
  --monthly-retention P12M \
  --yearly-retention P7Y

# Cosmos DB バックアップ設定（連続バックアップ）
az cosmosdb create \
  --name ${COSMOS_ACCOUNT_NAME} \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --backup-policy-type Continuous
```

### 8.2 災害復旧計画
```bash
# 別リージョンへのフェイルオーバー設定
az cosmosdb failover-priority-change \
  --name ${COSMOS_ACCOUNT_NAME} \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --failover-policies "japaneast=0" "japanwest=1"

# SQL Database のGeo-Replication設定
az sql db replica create \
  --name ${SQL_DATABASE_NAME} \
  --partner-server ${SQL_SERVER_NAME}-secondary \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --server ${SQL_SERVER_NAME}
```

## 9. パフォーマンス最適化

### 9.1 Azure Functions 最適化
```bash
# Premium プランへのアップグレード（本番環境）
az functionapp plan create \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --name "asp-factory-management-prod" \
  --location ${LOCATION} \
  --sku EP1 \
  --is-linux

# 事前ウォームアップ設定
az functionapp config appsettings set \
  --name func-factory-management-prod \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --settings "WEBSITE_PRELOAD_ENABLED=1"
```

### 9.2 データベース最適化
```bash
# SQL Database のスケールアップ
az sql db update \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --server ${SQL_SERVER_NAME} \
  --name ${SQL_DATABASE_NAME} \
  --service-objective S2

# Cosmos DB スループットの調整
az cosmosdb sql container throughput update \
  --account-name ${COSMOS_ACCOUNT_NAME} \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --database-name "FactoryIoTData" \
  --name "SensorData" \
  --throughput 1000
```

## 10. デプロイ後検証

### 10.1 ヘルスチェック
```bash
# Function App の動作確認
curl -X GET "https://func-factory-management-${ENV}.azurewebsites.net/api/health"

# データベース接続確認
curl -X GET "https://func-factory-management-${ENV}.azurewebsites.net/api/v1/equipment" \
  -H "Authorization: Bearer ${JWT_TOKEN}"
```

### 10.2 パフォーマンステスト
```bash
# Apache Bench を使用した負荷テスト
ab -n 1000 -c 10 "https://func-factory-management-${ENV}.azurewebsites.net/api/v1/equipment"

# Azure Load Testing サービスの利用
az load test create \
  --name "factory-management-load-test" \
  --resource-group ${RESOURCE_GROUP_NAME}
```

## 11. ロールバック手順

### 11.1 緊急時のロールバック
```bash
# Function App の以前のバージョンへのロールバック
az functionapp deployment slot swap \
  --name func-factory-management-prod \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --slot staging \
  --target-slot production

# 特定のバージョンへのロールバック
az functionapp deployment source config-zip \
  --name func-factory-management-prod \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --src ./backup/backend-v1.2.0.zip
```

### 11.2 データベースロールバック
```bash
# SQL Database のポイントインタイムリストア
az sql db restore \
  --dest-name ${SQL_DATABASE_NAME}-restored \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --server ${SQL_SERVER_NAME} \
  --source-database ${SQL_DATABASE_NAME} \
  --time "2024-01-15T10:00:00Z"
```

## 12. 継続的デプロイメントの監視

### 12.1 デプロイメント成功率の監視
```bash
# Azure Monitor クエリ例
az monitor log-analytics query \
  --workspace "factory-management-logs" \
  --analytics-query "
    requests
    | where cloud_RoleName == 'func-factory-management-prod'
    | where timestamp > ago(1h)
    | summarize success_rate = avg(success) by bin(timestamp, 5m)
  "
```

### 12.2 アプリケーション正常性の監視
- Application Insights による可用性テスト
- Azure Monitor メトリックアラート
- カスタムダッシュボードでの可視化

## 13. セキュリティ強化

### 13.1 ネットワークセキュリティ
```bash
# Virtual Network統合
az functionapp vnet-integration add \
  --name func-factory-management-prod \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --vnet "vnet-factory-management" \
  --subnet "subnet-functions"

# プライベートエンドポイント設定
az network private-endpoint create \
  --name "pe-sql-factory-management" \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --vnet-name "vnet-factory-management" \
  --subnet "subnet-private-endpoints" \
  --private-connection-resource-id "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Sql/servers/${SQL_SERVER_NAME}" \
  --connection-name "sql-connection"
```

## 14. 本番運用チェックリスト

### 14.1 デプロイ前チェック
- [ ] コードレビュー完了
- [ ] 単体テスト・統合テスト実行
- [ ] セキュリティスキャン実行
- [ ] パフォーマンステスト実行
- [ ] データベースマイグレーション準備
- [ ] ロールバック計画策定

### 14.2 デプロイ後チェック
- [ ] アプリケーション正常動作確認
- [ ] データベース接続確認
- [ ] 外部API連携確認
- [ ] 監視・アラート動作確認
- [ ] バックアップ動作確認
- [ ] ドキュメント更新

## 15. トラブルシューティング

### 15.1 よくある問題と解決方法

#### Function App が起動しない
```bash
# ログ確認
az functionapp log tail \
  --name func-factory-management-prod \
  --resource-group ${RESOURCE_GROUP_NAME}

# アプリケーション設定確認
az functionapp config appsettings list \
  --name func-factory-management-prod \
  --resource-group ${RESOURCE_GROUP_NAME}
```

#### データベース接続エラー
```bash
# 接続文字列確認
az sql db show-connection-string \
  --server ${SQL_SERVER_NAME} \
  --name ${SQL_DATABASE_NAME} \
  --client ado.net

# ファイアウォール設定確認
az sql server firewall-rule list \
  --server ${SQL_SERVER_NAME} \
  --resource-group ${RESOURCE_GROUP_NAME}
```

### 15.2 緊急時の連絡先とエスカレーション手順
1. **レベル1**: 開発チーム（初動対応）
2. **レベル2**: インフラチーム（Azure関連）
3. **レベル3**: Microsoft サポート（重大障害時）

この手順書により、工場設備管理アプリケーションの安全で効率的なデプロイメントが実現できます。