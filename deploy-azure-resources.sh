#!/bin/bash

# FactoryManagement システム Azure デプロイメントスクリプト
# このスクリプトは Azure CLI を使用してサーバーレスアーキテクチャを構築します

set -e  # エラー時に停止

# =============================================================================
# 設定変数
# =============================================================================

# 基本設定
APP_NAME="FactoryManagement"
RESOURCE_GROUP_PREFIX="rg"
LOCATION="Japan East"  # Tokyo region
ENVIRONMENT="dev"  # dev, staging, prod

# プレフィックス付きリソース名の生成
RG_NAME="${RESOURCE_GROUP_PREFIX}-${APP_NAME,,}-${ENVIRONMENT}"
STORAGE_ACCOUNT_NAME="${APP_NAME,,}storage${ENVIRONMENT}"
FUNCTION_APP_NAME="${APP_NAME,,}-functions-${ENVIRONMENT}"
COSMOS_ACCOUNT_NAME="${APP_NAME,,}-cosmos-${ENVIRONMENT}"
STATIC_WEB_APP_NAME="${APP_NAME,,}-webapp-${ENVIRONMENT}"
KEYVAULT_NAME="${APP_NAME,,}-kv-${ENVIRONMENT}"
APP_INSIGHTS_NAME="${APP_NAME,,}-insights-${ENVIRONMENT}"

# タグ設定
TAGS="Environment=${ENVIRONMENT} Project=${APP_NAME} Owner=DevOps CreatedBy=AzureCLI"

# =============================================================================
# ヘルパー関数
# =============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

check_prerequisites() {
    log "前提条件をチェックしています..."
    
    # Azure CLI のインストール確認
    if ! command -v az &> /dev/null; then
        log "ERROR: Azure CLI がインストールされていません"
        log "インストール方法: https://docs.microsoft.com/cli/azure/install-azure-cli"
        exit 1
    fi
    
    # Azure CLI ログイン確認
    if ! az account show &> /dev/null; then
        log "Azure CLI にログインが必要です"
        az login
    fi
    
    # サブスクリプション情報の表示
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
    log "使用するサブスクリプション: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
    
    # 続行確認
    read -p "このサブスクリプションでデプロイを続行しますか？ (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "デプロイを中止しました"
        exit 1
    fi
}

create_resource_group() {
    log "リソースグループを作成しています: $RG_NAME"
    
    az group create \
        --name "$RG_NAME" \
        --location "$LOCATION" \
        --tags $TAGS
    
    log "リソースグループ作成完了: $RG_NAME"
}

create_storage_account() {
    log "ストレージアカウントを作成しています: $STORAGE_ACCOUNT_NAME"
    
    az storage account create \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RG_NAME" \
        --location "$LOCATION" \
        --sku "Standard_LRS" \
        --kind "StorageV2" \
        --access-tier "Hot" \
        --tags $TAGS
    
    log "ストレージアカウント作成完了: $STORAGE_ACCOUNT_NAME"
}

create_application_insights() {
    log "Application Insights を作成しています: $APP_INSIGHTS_NAME"
    
    az monitor app-insights component create \
        --app "$APP_INSIGHTS_NAME" \
        --location "$LOCATION" \
        --resource-group "$RG_NAME" \
        --kind "web" \
        --application-type "web" \
        --tags $TAGS
    
    # Instrumentation Key を取得
    INSTRUMENTATION_KEY=$(az monitor app-insights component show \
        --app "$APP_INSIGHTS_NAME" \
        --resource-group "$RG_NAME" \
        --query instrumentationKey -o tsv)
    
    log "Application Insights 作成完了: $APP_INSIGHTS_NAME"
    log "Instrumentation Key: $INSTRUMENTATION_KEY"
}

create_cosmos_db() {
    log "Cosmos DB アカウントを作成しています: $COSMOS_ACCOUNT_NAME"
    
    # Cosmos DB アカウント作成
    az cosmosdb create \
        --name "$COSMOS_ACCOUNT_NAME" \
        --resource-group "$RG_NAME" \
        --locations regionName="$LOCATION" failoverPriority=0 isZoneRedundant=False \
        --default-consistency-level "Session" \
        --capabilities EnableServerless \
        --tags $TAGS
    
    # データベース作成
    az cosmosdb sql database create \
        --account-name "$COSMOS_ACCOUNT_NAME" \
        --resource-group "$RG_NAME" \
        --name "FactoryIoTData"
    
    # コンテナ作成
    az cosmosdb sql container create \
        --account-name "$COSMOS_ACCOUNT_NAME" \
        --resource-group "$RG_NAME" \
        --database-name "FactoryIoTData" \
        --name "Equipment" \
        --partition-key-path "/equipmentType" \
        --throughput 400
    
    # 接続文字列を取得
    COSMOS_CONNECTION_STRING=$(az cosmosdb keys list \
        --name "$COSMOS_ACCOUNT_NAME" \
        --resource-group "$RG_NAME" \
        --type connection-strings \
        --query "connectionStrings[0].connectionString" -o tsv)
    
    log "Cosmos DB 作成完了: $COSMOS_ACCOUNT_NAME"
}

create_key_vault() {
    log "Key Vault を作成しています: $KEYVAULT_NAME"
    
    az keyvault create \
        --name "$KEYVAULT_NAME" \
        --resource-group "$RG_NAME" \
        --location "$LOCATION" \
        --sku "standard" \
        --tags $TAGS
    
    # シークレットの設定
    az keyvault secret set \
        --vault-name "$KEYVAULT_NAME" \
        --name "CosmosConnectionString" \
        --value "$COSMOS_CONNECTION_STRING"
    
    az keyvault secret set \
        --vault-name "$KEYVAULT_NAME" \
        --name "ApplicationInsightsKey" \
        --value "$INSTRUMENTATION_KEY"
    
    log "Key Vault 作成完了: $KEYVAULT_NAME"
}

create_function_app() {
    log "Azure Functions アプリを作成しています: $FUNCTION_APP_NAME"
    
    # Function App 作成
    az functionapp create \
        --name "$FUNCTION_APP_NAME" \
        --resource-group "$RG_NAME" \
        --storage-account "$STORAGE_ACCOUNT_NAME" \
        --consumption-plan-location "$LOCATION" \
        --runtime "python" \
        --runtime-version "3.9" \
        --os-type "Linux" \
        --app-insights "$APP_INSIGHTS_NAME" \
        --tags $TAGS
    
    # アプリケーション設定
    az functionapp config appsettings set \
        --name "$FUNCTION_APP_NAME" \
        --resource-group "$RG_NAME" \
        --settings \
            "COSMOS_DB_ENDPOINT=https://${COSMOS_ACCOUNT_NAME}.documents.azure.com:443/" \
            "COSMOS_DB_DATABASE=FactoryIoTData" \
            "COSMOS_DB_CONTAINER=Equipment" \
            "APPINSIGHTS_INSTRUMENTATIONKEY=$INSTRUMENTATION_KEY"
    
    # Key Vault への参照設定（シークレット）
    az functionapp config appsettings set \
        --name "$FUNCTION_APP_NAME" \
        --resource-group "$RG_NAME" \
        --settings \
            "COSMOS_DB_KEY=@Microsoft.KeyVault(VaultName=${KEYVAULT_NAME};SecretName=CosmosConnectionString)"
    
    # CORS 設定
    az functionapp cors add \
        --name "$FUNCTION_APP_NAME" \
        --resource-group "$RG_NAME" \
        --allowed-origins "*"
    
    log "Azure Functions 作成完了: $FUNCTION_APP_NAME"
}

create_static_web_app() {
    log "Azure Static Web Apps を作成しています: $STATIC_WEB_APP_NAME"
    
    # GitHub リポジトリ情報（必要に応じて変更）
    GITHUB_REPO="https://github.com/gh-user-2025/ai-driven-development-workshop-lac-komine"
    
    az staticwebapp create \
        --name "$STATIC_WEB_APP_NAME" \
        --resource-group "$RG_NAME" \
        --source "$GITHUB_REPO" \
        --location "$LOCATION" \
        --branch "main" \
        --app-location "frontend" \
        --output-location "dist" \
        --tags $TAGS
    
    # デプロイトークンを取得
    DEPLOYMENT_TOKEN=$(az staticwebapp secrets list \
        --name "$STATIC_WEB_APP_NAME" \
        --resource-group "$RG_NAME" \
        --query "properties.apiKey" -o tsv)
    
    log "Static Web Apps 作成完了: $STATIC_WEB_APP_NAME"
    log "デプロイトークン: $DEPLOYMENT_TOKEN"
}

setup_managed_identity() {
    log "マネージドアイデンティティを設定しています..."
    
    # Function App のシステム割り当てマネージドアイデンティティを有効化
    az functionapp identity assign \
        --name "$FUNCTION_APP_NAME" \
        --resource-group "$RG_NAME"
    
    # マネージドアイデンティティのプリンシパルIDを取得
    PRINCIPAL_ID=$(az functionapp identity show \
        --name "$FUNCTION_APP_NAME" \
        --resource-group "$RG_NAME" \
        --query principalId -o tsv)
    
    # Key Vault アクセスポリシーの設定
    az keyvault set-policy \
        --name "$KEYVAULT_NAME" \
        --object-id "$PRINCIPAL_ID" \
        --secret-permissions get list
    
    # Cosmos DB へのアクセス権限設定
    az cosmosdb sql role assignment create \
        --account-name "$COSMOS_ACCOUNT_NAME" \
        --resource-group "$RG_NAME" \
        --scope "/" \
        --principal-id "$PRINCIPAL_ID" \
        --role-definition-id "00000000-0000-0000-0000-000000000002"  # Cosmos DB Built-in Data Contributor
    
    log "マネージドアイデンティティ設定完了"
}

create_resource_tags() {
    log "リソースタグを設定しています..."
    
    # 作成日時タグの追加
    CREATION_DATE=$(date '+%Y-%m-%d')
    
    # 全リソースに追加タグを設定
    for resource in "$STORAGE_ACCOUNT_NAME" "$FUNCTION_APP_NAME" "$COSMOS_ACCOUNT_NAME" "$STATIC_WEB_APP_NAME" "$KEYVAULT_NAME" "$APP_INSIGHTS_NAME"; do
        az resource tag \
            --tags CreationDate="$CREATION_DATE" CostCenter="IT" \
            --ids "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.*/*/r$resource" \
            --operation merge || true  # エラーがあっても続行
    done
    
    log "リソースタグ設定完了"
}

display_deployment_info() {
    log "===================================="
    log "デプロイメント完了!"
    log "===================================="
    echo
    log "リソース情報:"
    log "- リソースグループ: $RG_NAME"
    log "- Function App: $FUNCTION_APP_NAME"
    log "- Static Web App: $STATIC_WEB_APP_NAME" 
    log "- Cosmos DB: $COSMOS_ACCOUNT_NAME"
    log "- Key Vault: $KEYVAULT_NAME"
    log "- Storage Account: $STORAGE_ACCOUNT_NAME"
    log "- Application Insights: $APP_INSIGHTS_NAME"
    echo
    log "エンドポイント:"
    
    # Function App URL
    FUNCTION_URL="https://${FUNCTION_APP_NAME}.azurewebsites.net"
    log "- Function App URL: $FUNCTION_URL"
    
    # Static Web App URL
    STATIC_URL=$(az staticwebapp show \
        --name "$STATIC_WEB_APP_NAME" \
        --resource-group "$RG_NAME" \
        --query defaultHostname -o tsv)
    log "- Static Web App URL: https://$STATIC_URL"
    
    echo
    log "次のステップ:"
    log "1. GitHub Actions でのCI/CDセットアップ"
    log "2. アプリケーションコードのデプロイ"
    log "3. Cosmos DB へのサンプルデータインポート"
    log "4. モニタリングダッシュボードの設定"
    echo
    log "詳細な手順は DEPLOYMENT_GUIDE.md を参照してください"
}

# =============================================================================
# メイン実行フロー
# =============================================================================

main() {
    log "FactoryManagement システムのデプロイを開始します"
    log "環境: $ENVIRONMENT"
    log "リージョン: $LOCATION"
    echo
    
    # 前提条件チェック
    check_prerequisites
    
    # リソース作成
    create_resource_group
    create_storage_account
    create_application_insights
    create_cosmos_db
    create_key_vault
    create_function_app
    create_static_web_app
    setup_managed_identity
    create_resource_tags
    
    # 完了情報表示
    display_deployment_info
    
    log "全ての処理が完了しました"
}

# スクリプト実行
main "$@"