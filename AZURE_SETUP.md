# Azure リソース構築手順書

## 1. 事前準備

### 1.1 必要なツール
- Azure CLI
- Azure アカウント（サブスクリプション）
- 適切な権限（Contributor以上）

### 1.2 Azure CLI インストール確認
```bash
# Azure CLI のバージョン確認
az --version

# ログイン状況の確認
az account show
```

## 2. Azureアカウントセットアップ

### 2.1 Azure にログイン
```bash
# Azureアカウントにログイン
az login

# 利用可能なサブスクリプション一覧表示
az account list --output table

# 使用するサブスクリプションを設定（必要に応じて）
az account set --subscription "<サブスクリプションID>"
```

## 3. リソースグループの作成

### 3.1 リソースグループ作成
```bash
# 環境変数設定（値は適宜変更してください）
export RESOURCE_GROUP_NAME="rg-factory-management"
export LOCATION="japaneast"

# リソースグループ作成
az group create \
  --name $RESOURCE_GROUP_NAME \
  --location $LOCATION

# 作成確認
az group show --name $RESOURCE_GROUP_NAME
```

## 4. Azure SQL Database の構築

### 4.1 SQL Server 作成
```bash
# 環境変数設定
export SQL_SERVER_NAME="sql-factory-management-$(date +%s)"
export SQL_ADMIN_USER="sqladmin"
export SQL_ADMIN_PASSWORD="P@ssw0rd123!"

# SQL Server 作成
az sql server create \
  --name $SQL_SERVER_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --location $LOCATION \
  --admin-user $SQL_ADMIN_USER \
  --admin-password $SQL_ADMIN_PASSWORD

# ファイアウォール規則設定（Azure サービスからのアクセス許可）
az sql server firewall-rule create \
  --resource-group $RESOURCE_GROUP_NAME \
  --server $SQL_SERVER_NAME \
  --name "AllowAzureServices" \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

### 4.2 SQL Database 作成
```bash
# 環境変数設定
export SQL_DATABASE_NAME="sqldb-factory-data"

# データベース作成（Basic tier）
az sql db create \
  --resource-group $RESOURCE_GROUP_NAME \
  --server $SQL_SERVER_NAME \
  --name $SQL_DATABASE_NAME \
  --service-objective Basic \
  --max-size 2GB

# 作成確認
az sql db show \
  --resource-group $RESOURCE_GROUP_NAME \
  --server $SQL_SERVER_NAME \
  --name $SQL_DATABASE_NAME
```

## 5. Azure Cosmos DB の構築

### 5.1 Cosmos DB アカウント作成
```bash
# 環境変数設定
export COSMOS_ACCOUNT_NAME="cosmos-factory-iot-$(date +%s)"

# Cosmos DB アカウント作成（SQL API）
az cosmosdb create \
  --name $COSMOS_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --locations regionName=$LOCATION \
  --kind GlobalDocumentDB \
  --consistency-policy consistencyLevel=Session

# 作成確認
az cosmosdb show \
  --name $COSMOS_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME
```

### 5.2 Cosmos DB データベースとコンテナ作成
```bash
# データベース名設定
export COSMOS_DATABASE_NAME="FactoryIoTData"
export COSMOS_CONTAINER_NAME="SensorData"

# データベース作成
az cosmosdb sql database create \
  --account-name $COSMOS_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $COSMOS_DATABASE_NAME

# コンテナ作成（パーティションキー: /deviceId）
az cosmosdb sql container create \
  --account-name $COSMOS_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --database-name $COSMOS_DATABASE_NAME \
  --name $COSMOS_CONTAINER_NAME \
  --partition-key-path "/deviceId" \
  --throughput 400
```

## 6. Azure Functions の構築

### 6.1 ストレージアカウント作成
```bash
# 環境変数設定
export STORAGE_ACCOUNT_NAME="stfactory$(date +%s | tail -c 10)"

# ストレージアカウント作成
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2

# 作成確認
az storage account show \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME
```

### 6.2 Function App 作成
```bash
# 環境変数設定
export FUNCTION_APP_NAME="func-factory-management-$(date +%s)"

# Function App 作成（Python 3.9）
az functionapp create \
  --resource-group $RESOURCE_GROUP_NAME \
  --consumption-plan-location $LOCATION \
  --runtime python \
  --runtime-version 3.9 \
  --functions-version 4 \
  --name $FUNCTION_APP_NAME \
  --storage-account $STORAGE_ACCOUNT_NAME \
  --os-type Linux

# 作成確認
az functionapp show \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP_NAME
```

## 7. Application Insights の構築

### 7.1 Application Insights 作成
```bash
# 環境変数設定
export APP_INSIGHTS_NAME="appi-factory-management"

# Application Insights 作成
az monitor app-insights component create \
  --app $APP_INSIGHTS_NAME \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP_NAME \
  --kind web

# インストルメンテーションキー取得
export INSTRUMENTATION_KEY=$(az monitor app-insights component show \
  --app $APP_INSIGHTS_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --query "instrumentationKey" -o tsv)

echo "Instrumentation Key: $INSTRUMENTATION_KEY"
```

## 8. 接続文字列とキーの取得

### 8.1 SQL Database 接続文字列
```bash
# SQL Database 接続文字列取得
az sql db show-connection-string \
  --server $SQL_SERVER_NAME \
  --name $SQL_DATABASE_NAME \
  --client ado.net
```

### 8.2 Cosmos DB 接続情報
```bash
# Cosmos DB 接続文字列取得
az cosmosdb keys list \
  --name $COSMOS_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --type connection-strings

# Cosmos DB エンドポイント取得
az cosmosdb show \
  --name $COSMOS_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --query "documentEndpoint" -o tsv
```

### 8.3 ストレージアカウント接続文字列
```bash
# ストレージアカウント接続文字列取得
az storage account show-connection-string \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME
```

## 9. Function App の構成設定

### 9.1 アプリケーション設定の構成
```bash
# SQL Database 接続文字列設定
SQL_CONNECTION_STRING="Server=tcp:${SQL_SERVER_NAME}.database.windows.net,1433;Initial Catalog=${SQL_DATABASE_NAME};Persist Security Info=False;User ID=${SQL_ADMIN_USER};Password=${SQL_ADMIN_PASSWORD};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

az functionapp config appsettings set \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --settings "SqlConnectionString=$SQL_CONNECTION_STRING"

# Cosmos DB 設定
COSMOS_ENDPOINT=$(az cosmosdb show \
  --name $COSMOS_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --query "documentEndpoint" -o tsv)

COSMOS_KEY=$(az cosmosdb keys list \
  --name $COSMOS_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --query "primaryMasterKey" -o tsv)

az functionapp config appsettings set \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --settings "CosmosDbEndpoint=$COSMOS_ENDPOINT" "CosmosDbKey=$COSMOS_KEY"

# Application Insights設定
az functionapp config appsettings set \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --settings "APPINSIGHTS_INSTRUMENTATIONKEY=$INSTRUMENTATION_KEY"
```

## 10. セキュリティ設定

### 10.1 Key Vault の作成（オプション）
```bash
# 環境変数設定
export KEY_VAULT_NAME="kv-factory-$(date +%s | tail -c 10)"

# Key Vault 作成
az keyvault create \
  --name $KEY_VAULT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --location $LOCATION \
  --sku standard

# Function App にマネージド ID を有効化
az functionapp identity assign \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP_NAME

# マネージド ID の Principal ID 取得
PRINCIPAL_ID=$(az functionapp identity show \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --query "principalId" -o tsv)

# Key Vault アクセスポリシー設定
az keyvault set-policy \
  --name $KEY_VAULT_NAME \
  --object-id $PRINCIPAL_ID \
  --secret-permissions get list
```

## 11. リソース確認とクリーンアップ

### 11.1 作成されたリソースの確認
```bash
# リソースグループ内の全リソース表示
az resource list \
  --resource-group $RESOURCE_GROUP_NAME \
  --output table
```

### 11.2 クリーンアップ（必要に応じて）
```bash
# 注意: このコマンドはリソースグループとその中の全リソースを削除します
# az group delete --name $RESOURCE_GROUP_NAME --yes --no-wait
```

## 12. 次のステップ

1. **開発環境の設定**: DEVELOPMENT_GUIDE.md を参照
2. **アプリケーションのデプロイ**: DEPLOYMENT_GUIDE.md を参照
3. **Power BI の設定**: データソース接続とレポート作成
4. **監視とアラートの設定**: Azure Monitor と Application Insights の構成

## 注意事項

- パスワードや接続文字列などの機密情報は、Azure Key Vault に保存することを推奨
- 本番環境では、より厳格なセキュリティ設定が必要
- コスト最適化のため、不要なリソースは定期的に見直し
- リソース名にタイムスタンプを付加しているため、実行のたびに一意な名前が生成される