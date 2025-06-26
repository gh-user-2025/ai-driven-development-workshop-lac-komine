# Azure デプロイメント詳細手順書

## 概要
FactoryManagement システムを Azure にデプロイするための詳細な手順書です。Azure CLI を使用してサーバーレスアーキテクチャを構築します。

## 前提条件

### 必要なツール
1. **Azure CLI**: バージョン 2.30.0 以上
2. **Git**: バージョン 2.20.0 以上  
3. **Azure サブスクリプション**: 有効なサブスクリプション
4. **適切な権限**: サブスクリプションでのContributor権限

### Azure CLI のインストール

#### Windows
```powershell
# Chocolatey を使用
choco install azure-cli

# または MSI インストーラーをダウンロード
# https://aka.ms/installazurecliwindows
```

#### macOS
```bash
# Homebrew を使用
brew install azure-cli

# または pkg インストーラーをダウンロード
# https://aka.ms/installazureclimacos
```

#### Ubuntu/Debian
```bash
# Microsoft の署名キーを追加
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# または手動インストール
sudo apt-get update
sudo apt-get install ca-certificates curl apt-transport-https lsb-release gnupg
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-get update
sudo apt-get install azure-cli
```

### インストール確認
```bash
# バージョン確認
az --version

# Azure にログイン
az login

# サブスクリプション一覧表示
az account list --output table

# 使用するサブスクリプションを設定
az account set --subscription "your-subscription-id"
```

## デプロイメント手順

### 1. リポジトリのクローン
```bash
# GitHub からクローン
git clone https://github.com/gh-user-2025/ai-driven-development-workshop-lac-komine.git

# プロジェクトディレクトリに移動
cd ai-driven-development-workshop-lac-komine
```

### 2. デプロイスクリプトの実行

#### 基本実行
```bash
# スクリプトを実行可能にする
chmod +x deploy-azure-resources.sh

# デプロイメント実行
./deploy-azure-resources.sh
```

#### 環境別デプロイメント
```bash
# 開発環境
ENVIRONMENT=dev ./deploy-azure-resources.sh

# ステージング環境  
ENVIRONMENT=staging ./deploy-azure-resources.sh

# 本番環境
ENVIRONMENT=prod ./deploy-azure-resources.sh
```

#### カスタム設定でのデプロイメント
```bash
# 特定のリージョンでデプロイ
LOCATION="East US" ./deploy-azure-resources.sh

# カスタムアプリケーション名
APP_NAME="MyFactoryApp" ./deploy-azure-resources.sh
```

### 3. 作成されるリソース

デプロイメントスクリプトにより以下のリソースが作成されます：

| リソースタイプ | リソース名 | 用途 |
|---|---|---|
| Resource Group | rg-factorymanagement-dev | 全リソースの親グループ |
| Storage Account | factorymanagementstoragedev | Function App とファイル保存 |
| Function App | factorymanagement-functions-dev | バックエンド API |
| Cosmos DB | factorymanagement-cosmos-dev | NoSQL データベース |
| Static Web Apps | factorymanagement-webapp-dev | フロントエンド Web アプリ |
| Key Vault | factorymanagement-kv-dev | シークレット管理 |
| Application Insights | factorymanagement-insights-dev | 監視・ログ |

### 4. デプロイメント後の設定

#### Function App のコードデプロイ
```bash
# Azure Functions Core Tools のインストール
npm install -g azure-functions-core-tools@4 --unsafe-perm true

# Function App にデプロイ
cd backend
func azure functionapp publish factorymanagement-functions-dev
```

#### Static Web Apps のビルドとデプロイ
```bash
# フロントエンドのビルド
cd frontend
npm install
npm run build

# Static Web Apps CLI のインストール
npm install -g @azure/static-web-apps-cli

# デプロイトークンを使用してデプロイ
swa deploy ./dist --deployment-token $DEPLOYMENT_TOKEN
```

#### Cosmos DB へのサンプルデータインポート
```bash
# Azure Cosmos DB Data Migration Tool を使用
# または PowerShell/Azure CLI スクリプトでインポート

# サンプルデータファイルの場所
# - database/sample_data_equipment.json
# - database/cosmos_sample_sensor_data.json
# - database/cosmos_sample_alert_events.json
```

## CI/CD セットアップ

### GitHub Actions の設定

#### 1. GitHub Secrets の設定
リポジトリの Settings > Secrets and variables > Actions で以下のシークレットを設定：

```yaml
AZURE_CREDENTIALS: Azure サービスプリンシパルの認証情報
AZURE_FUNCTIONAPP_PUBLISH_PROFILE: Function App の発行プロファイル
AZURE_STATIC_WEB_APPS_API_TOKEN: Static Web Apps の API トークン
```

#### 2. ワークフローファイルの作成
`.github/workflows/azure-deploy.yml`:

```yaml
name: Azure デプロイメント

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  AZURE_FUNCTIONAPP_NAME: factorymanagement-functions-dev
  AZURE_FUNCTIONAPP_PACKAGE_PATH: 'backend'
  PYTHON_VERSION: '3.9'

jobs:
  build-and-deploy-backend:
    runs-on: ubuntu-latest
    steps:
    - name: 'コードのチェックアウト'
      uses: actions/checkout@v3

    - name: 'Python 環境のセットアップ'
      uses: actions/setup-python@v4
      with:
        python-version: ${{ env.PYTHON_VERSION }}

    - name: '依存関係のインストール'
      run: |
        cd ${{ env.AZURE_FUNCTIONAPP_PACKAGE_PATH }}
        python -m pip install --upgrade pip
        pip install -r requirements.txt

    - name: 'Azure Functions へのデプロイ'
      uses: Azure/functions-action@v1
      with:
        app-name: ${{ env.AZURE_FUNCTIONAPP_NAME }}
        package: ${{ env.AZURE_FUNCTIONAPP_PACKAGE_PATH }}
        publish-profile: ${{ secrets.AZURE_FUNCTIONAPP_PUBLISH_PROFILE }}

  build-and-deploy-frontend:
    runs-on: ubuntu-latest
    steps:
    - name: 'コードのチェックアウト'
      uses: actions/checkout@v3
      with:
        submodules: true

    - name: 'Node.js のセットアップ'
      uses: actions/setup-node@v3
      with:
        node-version: '18'

    - name: '依存関係のインストールとビルド'
      run: |
        cd frontend
        npm install
        npm run build

    - name: 'Static Web Apps へのデプロイ'
      uses: Azure/static-web-apps-deploy@v1
      with:
        azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
        repo_token: ${{ secrets.GITHUB_TOKEN }}
        action: "upload"
        app_location: "frontend"
        output_location: "dist"
```

### Azure DevOps パイプライン

#### azure-pipelines.yml
```yaml
trigger:
  branches:
    include:
    - main
    - develop

variables:
  azureSubscription: 'factory-management-service-connection'
  functionAppName: 'factorymanagement-functions-dev'
  staticWebAppName: 'factorymanagement-webapp-dev'

stages:
- stage: Build
  displayName: 'ビルドステージ'
  jobs:
  - job: BuildBackend
    displayName: 'バックエンドビルド'
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - task: UsePythonVersion@0
      inputs:
        versionSpec: '3.9'
      displayName: 'Python 3.9 の使用'

    - script: |
        cd backend
        python -m pip install --upgrade pip
        pip install -r requirements.txt
      displayName: '依存関係のインストール'

    - task: ArchiveFiles@2
      inputs:
        rootFolderOrFile: 'backend'
        includeRootFolder: false
        archiveType: 'zip'
        archiveFile: '$(Build.ArtifactStagingDirectory)/backend.zip'
      displayName: 'バックエンドのアーカイブ'

    - publish: '$(Build.ArtifactStagingDirectory)/backend.zip'
      artifact: 'backend'

  - job: BuildFrontend
    displayName: 'フロントエンドビルド'
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - task: NodeTool@0
      inputs:
        versionSpec: '18'
      displayName: 'Node.js 18 の使用'

    - script: |
        cd frontend
        npm install
        npm run build
      displayName: 'フロントエンドビルド'

    - publish: 'frontend/dist'
      artifact: 'frontend'

- stage: Deploy
  displayName: 'デプロイステージ'
  dependsOn: Build
  jobs:
  - deployment: DeployBackend
    displayName: 'バックエンドデプロイ'
    environment: 'development'
    pool:
      vmImage: 'ubuntu-latest'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureFunctionApp@1
            inputs:
              azureSubscription: '$(azureSubscription)'
              appType: 'functionAppLinux'
              appName: '$(functionAppName)'
              package: '$(Pipeline.Workspace)/backend/backend.zip'
              runtimeStack: 'PYTHON|3.9'

  - deployment: DeployFrontend
    displayName: 'フロントエンドデプロイ'
    environment: 'development'
    pool:
      vmImage: 'ubuntu-latest'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureStaticWebApp@0
            inputs:
              app_location: '$(Pipeline.Workspace)/frontend'
              azure_static_web_apps_api_token: '$(AZURE_STATIC_WEB_APPS_API_TOKEN)'
```

## 環境固有設定

### 開発環境 (dev)
```bash
# 設定例
ENVIRONMENT=dev
LOCATION="Japan East"
APP_NAME="FactoryManagement"

# 作成されるリソース
# - rg-factorymanagement-dev
# - factorymanagement-functions-dev
# - factorymanagement-webapp-dev
```

### ステージング環境 (staging)
```bash
# 設定例  
ENVIRONMENT=staging
LOCATION="Japan East"
APP_NAME="FactoryManagement"

# Premium プランの使用
# - より高いパフォーマンス
# - VNet 統合
# - カスタムドメイン
```

### 本番環境 (prod)
```bash
# 設定例
ENVIRONMENT=prod
LOCATION="Japan East"
APP_NAME="FactoryManagement"

# 本番固有設定
# - Multi-region deployment
# - Premium プラン
# - WAF (Web Application Firewall)
# - Backup とディザスタリカバリ
```

## 監視とログ

### Application Insights の設定
```bash
# カスタムメトリクスの設定
az monitor app-insights metrics get-metadata \
  --app factorymanagement-insights-dev \
  --resource-group rg-factorymanagement-dev
```

### アラートの設定
```bash
# レスポンス時間アラート
az monitor metrics alert create \
  --name "High Response Time" \
  --resource-group rg-factorymanagement-dev \
  --scopes "/subscriptions/{subscription-id}/resourceGroups/rg-factorymanagement-dev/providers/Microsoft.Web/sites/factorymanagement-functions-dev" \
  --condition "avg requests/duration > 5000" \
  --description "Function App response time is high"
```

## トラブルシューティング

### よくある問題と解決方法

#### 1. リソース名の重複エラー
```bash
# 一意な名前を生成
RANDOM_SUFFIX=$(openssl rand -hex 3)
STORAGE_ACCOUNT_NAME="factorymanagement${RANDOM_SUFFIX}"
```

#### 2. 権限不足エラー
```bash
# 必要な権限を確認
az role assignment list --assignee $(az account show --query user.name -o tsv)

# Contributor 権限の付与
az role assignment create \
  --assignee user@domain.com \
  --role Contributor \
  --scope /subscriptions/{subscription-id}
```

#### 3. Function App デプロイエラー
```bash
# デプロイログの確認
az functionapp log deployment show \
  --name factorymanagement-functions-dev \
  --resource-group rg-factorymanagement-dev

# アプリケーション設定の確認
az functionapp config appsettings list \
  --name factorymanagement-functions-dev \
  --resource-group rg-factorymanagement-dev
```

#### 4. Cosmos DB 接続エラー
```bash
# 接続文字列の確認
az cosmosdb keys list \
  --name factorymanagement-cosmos-dev \
  --resource-group rg-factorymanagement-dev \
  --type connection-strings

# ファイアウォール設定の確認
az cosmosdb network-rule list \
  --name factorymanagement-cosmos-dev \
  --resource-group rg-factorymanagement-dev
```

## クリーンアップ

### リソースの削除
```bash
# リソースグループ全体を削除
az group delete \
  --name rg-factorymanagement-dev \
  --yes \
  --no-wait

# 特定のリソースのみ削除
az functionapp delete \
  --name factorymanagement-functions-dev \
  --resource-group rg-factorymanagement-dev
```

## コスト最適化

### 推奨設定
1. **開発環境**: Consumption プラン、Serverless Cosmos DB
2. **ステージング環境**: Premium プラン（最小インスタンス）
3. **本番環境**: Premium プラン（自動スケール）

### コスト監視
```bash
# 予算の設定
az consumption budget create \
  --amount 100 \
  --category Cost \
  --name "FactoryManagement Budget" \
  --time-grain Monthly \
  --time-period-start 2024-01-01 \
  --time-period-end 2024-12-31
```

---

このドキュメントに従って、FactoryManagement システムを Azure に正常にデプロイできます。問題が発生した場合は、トラブルシューティングセクションを参照してください。