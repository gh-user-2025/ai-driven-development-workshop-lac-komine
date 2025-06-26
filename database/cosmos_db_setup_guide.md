# Azure Cosmos DB セットアップとデータインポート手順書

## 概要

この手順書では、工場設備管理システム用の Azure Cosmos DB NoSQL API データベースのセットアップとサンプルデータのインポート方法について説明します。

## 前提条件

- Azure サブスクリプションを持っていること
- Azure CLI がインストール済みであること
- 適切な権限（Contributor 以上）を持っていること

## 1. Azure CLI での Cosmos DB アカウント作成

### 1.1 Azure にログイン

```bash
# Azure にログイン
az login

# 使用するサブスクリプションを設定
az account set --subscription "your-subscription-id"
```

### 1.2 リソースグループの作成

```bash
# リソースグループを作成
az group create \
  --name "rg-factory-management" \
  --location "Japan East"
```

### 1.3 Cosmos DB アカウントの作成

```bash
# Cosmos DB アカウントを作成
az cosmosdb create \
  --name "cosmos-factory-management" \
  --resource-group "rg-factory-management" \
  --kind "GlobalDocumentDB" \
  --default-consistency-level "Session" \
  --locations regionName="Japan East" failoverPriority=0 isZoneRedundant=false \
  --enable-automatic-failover false \
  --enable-multiple-write-locations false \
  --backup-policy-type "Periodic"
```

**注意**: アカウント名は全世界で一意である必要があります。

### 1.4 データベースの作成

```bash
# データベースを作成
az cosmosdb sql database create \
  --account-name "cosmos-factory-management" \
  --resource-group "rg-factory-management" \
  --name "FactoryIoTData" \
  --throughput 400
```

## 2. コンテナ（コレクション）の作成

### 2.1 センサーデータコンテナの作成

```bash
# センサーデータコンテナを作成
az cosmosdb sql container create \
  --account-name "cosmos-factory-management" \
  --resource-group "rg-factory-management" \
  --database-name "FactoryIoTData" \
  --name "SensorData" \
  --partition-key-path "/deviceId" \
  --throughput 400
```

### 2.2 設備稼働統計コンテナの作成

```bash
# 設備稼働統計コンテナを作成
az cosmosdb sql container create \
  --account-name "cosmos-factory-management" \
  --resource-group "rg-factory-management" \
  --database-name "FactoryIoTData" \
  --name "EquipmentStats" \
  --partition-key-path "/deviceId" \
  --throughput 400
```

### 2.3 アラートイベントコンテナの作成

```bash
# アラートイベントコンテナを作成
az cosmosdb sql container create \
  --account-name "cosmos-factory-management" \
  --resource-group "rg-factory-management" \
  --database-name "FactoryIoTData" \
  --name "AlertEvents" \
  --partition-key-path "/equipmentId" \
  --throughput 400
```

## 3. インデックスポリシーの設定

### 3.1 センサーデータ用インデックスポリシー

```bash
# インデックスポリシーJSONファイルを作成
cat > sensor_data_index_policy.json << 'EOF'
{
  "indexingMode": "consistent",
  "automatic": true,
  "includedPaths": [
    {
      "path": "/deviceId/?",
      "indexes": [
        {
          "kind": "Hash"
        }
      ]
    },
    {
      "path": "/timestamp/?",
      "indexes": [
        {
          "kind": "Range"
        }
      ]
    },
    {
      "path": "/data/*/status/?",
      "indexes": [
        {
          "kind": "Hash"
        }
      ]
    },
    {
      "path": "/location/area/?",
      "indexes": [
        {
          "kind": "Hash"
        }
      ]
    }
  ],
  "excludedPaths": [
    {
      "path": "/metadata/*"
    },
    {
      "path": "/location/coordinates/*"
    }
  ]
}
EOF

# インデックスポリシーを適用
az cosmosdb sql container update \
  --account-name "cosmos-factory-management" \
  --resource-group "rg-factory-management" \
  --database-name "FactoryIoTData" \
  --name "SensorData" \
  --idx @sensor_data_index_policy.json
```

### 3.2 アラートイベント用インデックスポリシー

```bash
# アラートイベント用インデックスポリシーJSONファイルを作成
cat > alert_events_index_policy.json << 'EOF'
{
  "indexingMode": "consistent",
  "automatic": true,
  "includedPaths": [
    {
      "path": "/equipmentId/?",
      "indexes": [
        {
          "kind": "Hash"
        }
      ]
    },
    {
      "path": "/alertId/?",
      "indexes": [
        {
          "kind": "Hash"
        }
      ]
    },
    {
      "path": "/timestamp/?",
      "indexes": [
        {
          "kind": "Range"
        }
      ]
    },
    {
      "path": "/eventType/?",
      "indexes": [
        {
          "kind": "Hash"
        }
      ]
    },
    {
      "path": "/severity/?",
      "indexes": [
        {
          "kind": "Hash"
        }
      ]
    }
  ],
  "excludedPaths": [
    {
      "path": "/context/additionalData/*"
    }
  ]
}
EOF

# インデックスポリシーを適用
az cosmosdb sql container update \
  --account-name "cosmos-factory-management" \
  --resource-group "rg-factory-management" \
  --database-name "FactoryIoTData" \
  --name "AlertEvents" \
  --idx @alert_events_index_policy.json
```

## 4. 接続文字列の取得

```bash
# 接続文字列を取得（安全な場所に保管してください）
az cosmosdb keys list \
  --name "cosmos-factory-management" \
  --resource-group "rg-factory-management" \
  --type connection-strings
```

## 5. サンプルデータのインポート

### 5.1 Azure Data Explorer を使用したインポート

1. Azure Portal で Cosmos DB アカウントにアクセス
2. 「Data Explorer」を選択
3. 各コンテナに移動してドキュメントを手動で追加

### 5.2 PowerShell を使用したバルクインポート

```powershell
# PowerShell用のCosmos DB モジュールをインストール
Install-Module -Name Az.CosmosDB -Force

# 接続文字列を設定
$connectionString = "YOUR_CONNECTION_STRING_HERE"
$databaseName = "FactoryIoTData"

# センサーデータのインポート
$sensorDataJson = Get-Content -Path "cosmos_sample_sensor_data.json" -Raw | ConvertFrom-Json
foreach ($document in $sensorDataJson) {
    # ドキュメントを挿入する処理
    # （実際の実装では Cosmos DB .NET SDK を使用）
}
```

### 5.3 Azure CLI を使用したインポート

```bash
# 個別ドキュメントの挿入例
az cosmosdb sql container item create \
  --account-name "cosmos-factory-management" \
  --resource-group "rg-factory-management" \
  --database-name "FactoryIoTData" \
  --container-name "SensorData" \
  --body '{
    "id": "sensor-equipment-001-20240226140000",
    "deviceId": "equipment-001",
    "equipmentName": "第1製造ライン主モーター",
    "timestamp": "2024-02-26T14:00:00.000Z",
    "data": {
      "temperature": {
        "value": 74.8,
        "unit": "celsius",
        "status": "normal",
        "quality": "good"
      }
    }
  }'
```

## 6. Python スクリプトを使用したバルクインポート

### 6.1 必要なライブラリのインストール

```bash
pip install azure-cosmos
```

### 6.2 インポートスクリプト

```python
# bulk_import.py
import json
from azure.cosmos import CosmosClient, PartitionKey, exceptions

# 接続情報
ENDPOINT = "https://cosmos-factory-management.documents.azure.com:443/"
KEY = "YOUR_PRIMARY_KEY_HERE"
DATABASE_NAME = "FactoryIoTData"

def import_sensor_data():
    """センサーデータをインポート"""
    client = CosmosClient(ENDPOINT, KEY)
    database = client.get_database_client(DATABASE_NAME)
    container = database.get_container_client("SensorData")
    
    # JSONファイルからデータを読み込み
    with open('cosmos_sample_sensor_data.json', 'r', encoding='utf-8') as f:
        sensor_data = json.load(f)
    
    # バルクインポート
    for item in sensor_data:
        try:
            container.create_item(body=item)
            print(f"センサーデータ挿入成功: {item['id']}")
        except exceptions.CosmosResourceExistsError:
            print(f"データ既存: {item['id']}")
        except Exception as e:
            print(f"エラー: {item['id']} - {str(e)}")

def import_equipment_stats():
    """設備稼働統計をインポート"""
    client = CosmosClient(ENDPOINT, KEY)
    database = client.get_database_client(DATABASE_NAME)
    container = database.get_container_client("EquipmentStats")
    
    with open('cosmos_sample_equipment_stats.json', 'r', encoding='utf-8') as f:
        stats_data = json.load(f)
    
    for item in stats_data:
        try:
            container.create_item(body=item)
            print(f"設備統計挿入成功: {item['id']}")
        except exceptions.CosmosResourceExistsError:
            print(f"データ既存: {item['id']}")
        except Exception as e:
            print(f"エラー: {item['id']} - {str(e)}")

def import_alert_events():
    """アラートイベントをインポート"""
    client = CosmosClient(ENDPOINT, KEY)
    database = client.get_database_client(DATABASE_NAME)
    container = database.get_container_client("AlertEvents")
    
    with open('cosmos_sample_alert_events.json', 'r', encoding='utf-8') as f:
        alert_data = json.load(f)
    
    for item in alert_data:
        try:
            container.create_item(body=item)
            print(f"アラートイベント挿入成功: {item['id']}")
        except exceptions.CosmosResourceExistsError:
            print(f"データ既存: {item['id']}")
        except Exception as e:
            print(f"エラー: {item['id']} - {str(e)}")

if __name__ == "__main__":
    print("Cosmos DB データインポート開始...")
    import_sensor_data()
    import_equipment_stats()
    import_alert_events()
    print("データインポート完了！")
```

### 6.3 スクリプトの実行

```bash
# スクリプトを実行してデータをインポート
python bulk_import.py
```

## 7. データの確認

### 7.1 Azure Portal での確認

1. Azure Portal で Cosmos DB アカウントにアクセス
2. 「Data Explorer」を選択
3. 各コンテナでドキュメントを確認

### 7.2 クエリでの確認

```sql
-- センサーデータの確認
SELECT * FROM c WHERE c.deviceId = "equipment-001" ORDER BY c.timestamp DESC

-- アラートイベントの確認
SELECT * FROM c WHERE c.eventType = "TRIGGERED" ORDER BY c.timestamp DESC

-- 設備稼働統計の確認
SELECT * FROM c WHERE c.period = "daily" ORDER BY c.date DESC
```

## 8. パフォーマンス最適化

### 8.1 スループットの調整

```bash
# スループットを1000 RU/sに増加
az cosmosdb sql container throughput update \
  --account-name "cosmos-factory-management" \
  --resource-group "rg-factory-management" \
  --database-name "FactoryIoTData" \
  --name "SensorData" \
  --throughput 1000
```

### 8.2 自動スケールの有効化

```bash
# 自動スケールを有効化（最大4000 RU/s）
az cosmosdb sql container throughput update \
  --account-name "cosmos-factory-management" \
  --resource-group "rg-factory-management" \
  --database-name "FactoryIoTData" \
  --name "SensorData" \
  --max-throughput 4000
```

## 9. セキュリティ設定

### 9.1 ファイアウォール設定

```bash
# 特定のIPアドレスのみアクセス許可
az cosmosdb update \
  --name "cosmos-factory-management" \
  --resource-group "rg-factory-management" \
  --ip-range-filter "203.0.113.0/24,198.51.100.0/24"
```

### 9.2 仮想ネットワーク統合

```bash
# 仮想ネットワークエンドポイントを有効化
az cosmosdb update \
  --name "cosmos-factory-management" \
  --resource-group "rg-factory-management" \
  --enable-virtual-network true \
  --virtual-network-rules "/subscriptions/your-subscription/resourceGroups/your-rg/providers/Microsoft.Network/virtualNetworks/your-vnet/subnets/your-subnet"
```

## 10. 監視とアラート設定

### 10.1 診断ログの有効化

```bash
# 診断設定を作成
az monitor diagnostic-settings create \
  --name "cosmos-diagnostics" \
  --resource "/subscriptions/your-subscription/resourceGroups/rg-factory-management/providers/Microsoft.DocumentDB/databaseAccounts/cosmos-factory-management" \
  --logs '[{"category":"DataPlaneRequests","enabled":true},{"category":"QueryRuntimeStatistics","enabled":true}]' \
  --metrics '[{"category":"Requests","enabled":true}]' \
  --workspace "/subscriptions/your-subscription/resourceGroups/rg-factory-management/providers/Microsoft.OperationalInsights/workspaces/your-workspace"
```

## 11. バックアップと復旧

### 11.1 連続バックアップの有効化

```bash
# 連続バックアップを有効化
az cosmosdb update \
  --name "cosmos-factory-management" \
  --resource-group "rg-factory-management" \
  --backup-policy-type "Continuous"
```

## トラブルシューティング

### よくあるエラーと対処法

1. **スループット不足エラー**
   - RU/s を増加させる
   - パーティションキーの分散を確認

2. **インデックス作成エラー**
   - インデックスポリシーのJSON構文を確認
   - パスの指定方法を見直し

3. **接続エラー**
   - ファイアウォール設定を確認
   - 接続文字列の正確性を確認

## まとめ

この手順に従って Azure Cosmos DB のセットアップとサンプルデータのインポートが完了します。運用環境では、セキュリティ設定やバックアップ設定を適切に構成することが重要です。