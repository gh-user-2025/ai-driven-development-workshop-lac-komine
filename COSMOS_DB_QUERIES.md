# Azure Cosmos DB サンプルクエリ集

## 概要
工場設備管理システムで使用するAzure Cosmos DBに対するSQLクエリのサンプル集です。

## データ構造
設備データは以下の構造で格納されています：

```json
{
  "id": "equipment_1",
  "equipmentId": 1,
  "equipmentName": "第1製造ライン主モーター",
  "equipmentType": "Motor",
  "serialNumber": "MOT-001-2023",
  "manufacturer": "東洋電機製造",
  "model": "TDK-3000",
  "location": "第1工場1階A区画",
  "installationDate": "2023-01-15",
  "maintenanceCycleHours": 720,
  "responsiblePerson": "田中太郎",
  "status": "Active",
  "currentTemperature": 74.2,
  "currentVibration": 0.15,
  "operatingHours": 1456,
  "efficiency": 95.2,
  "lastMaintenanceDate": "2024-01-15",
  "nextMaintenanceDate": "2024-04-15",
  "documentType": "equipment",
  "partitionKey": "Motor"
}
```

## クエリサンプル

### 1. メンテナンス中の設備を検索
**質問**: メンテナンス中のある設備はどれですか？

```sql
SELECT 
    c.equipmentId,
    c.equipmentName,
    c.equipmentType,
    c.location,
    c.responsiblePerson,
    c.lastMaintenanceDate,
    c.nextMaintenanceDate
FROM c 
WHERE c.documentType = 'equipment' 
AND c.status = 'Maintenance'
ORDER BY c.equipmentName
```

**期待される結果**:
```json
[
  {
    "equipmentId": 6,
    "equipmentName": "プレス機1号機",
    "equipmentType": "Press",
    "location": "第2工場1階A区画",
    "responsiblePerson": "渡辺恵子",
    "lastMaintenanceDate": "2024-06-25",
    "nextMaintenanceDate": "2024-06-26"
  }
]
```

### 2. 稼働中の高効率設備を検索
```sql
SELECT 
    c.equipmentId,
    c.equipmentName,
    c.equipmentType,
    c.efficiency,
    c.operatingHours
FROM c 
WHERE c.documentType = 'equipment' 
AND c.status = 'Active' 
AND c.efficiency >= 95
ORDER BY c.efficiency DESC
```

### 3. 設備タイプ別の統計情報
```sql
SELECT 
    c.equipmentType,
    COUNT(1) as totalCount,
    SUM(CASE WHEN c.status = 'Active' THEN 1 ELSE 0 END) as activeCount,
    SUM(CASE WHEN c.status = 'Maintenance' THEN 1 ELSE 0 END) as maintenanceCount,
    AVG(CASE WHEN c.status = 'Active' THEN c.efficiency ELSE null END) as avgEfficiency
FROM c 
WHERE c.documentType = 'equipment'
GROUP BY c.equipmentType
ORDER BY totalCount DESC
```

### 4. 温度異常の設備を検索
```sql
SELECT 
    c.equipmentId,
    c.equipmentName,
    c.currentTemperature,
    c.equipmentType,
    c.responsiblePerson
FROM c 
WHERE c.documentType = 'equipment' 
AND c.status = 'Active'
AND c.currentTemperature > 70
ORDER BY c.currentTemperature DESC
```

### 5. メンテナンス予定の設備（7日以内）
```sql
SELECT 
    c.equipmentId,
    c.equipmentName,
    c.nextMaintenanceDate,
    c.responsiblePerson,
    c.location
FROM c 
WHERE c.documentType = 'equipment' 
AND c.nextMaintenanceDate >= GetCurrentDateTime()
AND c.nextMaintenanceDate <= DateTimeAdd('day', 7, GetCurrentDateTime())
ORDER BY c.nextMaintenanceDate
```

### 6. 場所別の設備稼働状況
```sql
SELECT 
    SUBSTRING(c.location, 0, INDEX_OF(c.location, '階')) as floor,
    COUNT(1) as totalEquipment,
    SUM(CASE WHEN c.status = 'Active' THEN 1 ELSE 0 END) as activeEquipment,
    AVG(CASE WHEN c.status = 'Active' THEN c.efficiency ELSE null END) as avgEfficiency
FROM c 
WHERE c.documentType = 'equipment'
GROUP BY SUBSTRING(c.location, 0, INDEX_OF(c.location, '階'))
ORDER BY floor
```

### 7. 稼働時間が長い設備（メンテナンス対象候補）
```sql
SELECT 
    c.equipmentId,
    c.equipmentName,
    c.operatingHours,
    c.maintenanceCycleHours,
    (c.operatingHours / c.maintenanceCycleHours * 100) as maintenanceProgress
FROM c 
WHERE c.documentType = 'equipment' 
AND c.status = 'Active'
AND c.operatingHours > (c.maintenanceCycleHours * 0.8)
ORDER BY maintenanceProgress DESC
```

### 8. 振動値が基準を超える設備
```sql
SELECT 
    c.equipmentId,
    c.equipmentName,
    c.currentVibration,
    c.equipmentType,
    c.location
FROM c 
WHERE c.documentType = 'equipment' 
AND c.status = 'Active'
AND c.currentVibration > 0.15
ORDER BY c.currentVibration DESC
```

### 9. 責任者別の設備管理状況
```sql
SELECT 
    c.responsiblePerson,
    COUNT(1) as totalEquipment,
    SUM(CASE WHEN c.status = 'Active' THEN 1 ELSE 0 END) as activeCount,
    SUM(CASE WHEN c.status = 'Maintenance' THEN 1 ELSE 0 END) as maintenanceCount,
    AVG(CASE WHEN c.status = 'Active' THEN c.efficiency ELSE null END) as avgEfficiency
FROM c 
WHERE c.documentType = 'equipment'
GROUP BY c.responsiblePerson
ORDER BY c.responsiblePerson
```

### 10. 設備導入年別の稼働状況
```sql
SELECT 
    SUBSTRING(c.installationDate, 0, 4) as installationYear,
    COUNT(1) as equipmentCount,
    AVG(CASE WHEN c.status = 'Active' THEN c.efficiency ELSE null END) as avgEfficiency,
    SUM(c.operatingHours) as totalOperatingHours
FROM c 
WHERE c.documentType = 'equipment'
GROUP BY SUBSTRING(c.installationDate, 0, 4)
ORDER BY installationYear DESC
```

## 実行方法

### Azure Portal での実行
1. Azure Portal にログイン
2. Cosmos DB アカウントに移動
3. Data Explorer を開く
4. データベース > コンテナを選択
5. "New SQL Query" をクリック
6. 上記のクエリをコピー＆ペースト
7. "Execute Query" をクリックして実行

### Azure CLI での実行例
```bash
# Cosmos DB SQL クエリの実行
az cosmosdb sql query \
  --account-name your-cosmos-account \
  --resource-group your-resource-group \
  --database-name FactoryIoTData \
  --container-name Equipment \
  --query-text "SELECT c.equipmentName FROM c WHERE c.status = 'Maintenance'"
```

### プログラムコードでの実行例
```python
from azure.cosmos import CosmosClient

# クライアント初期化
client = CosmosClient(endpoint, key)
database = client.get_database_client("FactoryIoTData")
container = database.get_container_client("Equipment")

# クエリ実行
query = "SELECT * FROM c WHERE c.status = 'Maintenance'"
items = list(container.query_items(
    query=query,
    enable_cross_partition_query=True
))

for item in items:
    print(f"設備名: {item['equipmentName']}, 場所: {item['location']}")
```

## パフォーマンス最適化のヒント

### 1. インデックスの活用
```sql
-- よく使用される検索条件にはコンポジットインデックスを設定
-- 例: status + equipmentType の組み合わせ検索
```

### 2. パーティションキーの活用
```sql
-- パーティションキー (equipmentType) を WHERE 句に含める
SELECT * FROM c 
WHERE c.equipmentType = 'Motor' 
AND c.status = 'Active'
```

### 3. 集約クエリの最適化
```sql
-- GROUP BY にパーティションキーを含める
SELECT c.equipmentType, COUNT(1) 
FROM c 
WHERE c.documentType = 'equipment'
GROUP BY c.equipmentType
```

## 注意事項
- Cross-partition クエリは RU 消費が多いため、可能な限りパーティションキーを指定する
- 大量データを扱う場合は、TOP 句や OFFSET/LIMIT を使用してページング処理を実装する
- 日時の比較には Cosmos DB の組み込み関数（GetCurrentDateTime等）を使用する