# データモデルと API 設計書

## 1. データモデル設計

### 1.1 Azure SQL Database（構造化データ）

#### 設備マスターテーブル（Equipment）
```sql
CREATE TABLE Equipment (
    EquipmentId INT PRIMARY KEY IDENTITY(1,1),
    EquipmentName NVARCHAR(100) NOT NULL,
    EquipmentType NVARCHAR(50) NOT NULL,
    SerialNumber NVARCHAR(50) UNIQUE,
    Manufacturer NVARCHAR(100),
    Model NVARCHAR(100),
    Location NVARCHAR(100) NOT NULL,
    InstallationDate DATE NOT NULL,
    MaintenanceCycleHours INT NOT NULL,
    ResponsiblePerson NVARCHAR(100),
    Status NVARCHAR(20) DEFAULT 'Active', -- Active, Maintenance, Retired
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE()
);
```

#### メンテナンス履歴テーブル（MaintenanceHistory）
```sql
CREATE TABLE MaintenanceHistory (
    MaintenanceId INT PRIMARY KEY IDENTITY(1,1),
    EquipmentId INT FOREIGN KEY REFERENCES Equipment(EquipmentId),
    MaintenanceType NVARCHAR(50) NOT NULL, -- Scheduled, Emergency, Preventive
    MaintenanceDate DATETIME2 NOT NULL,
    WorkDescription NVARCHAR(MAX),
    Worker NVARCHAR(100),
    DurationMinutes INT,
    NextScheduledDate DATE,
    Cost DECIMAL(10,2),
    Priority NVARCHAR(20), -- Low, Medium, High, Critical
    Status NVARCHAR(20) DEFAULT 'Completed', -- Scheduled, InProgress, Completed
    CreatedAt DATETIME2 DEFAULT GETDATE()
);
```

#### アラート定義テーブル（AlertRules）
```sql
CREATE TABLE AlertRules (
    AlertRuleId INT PRIMARY KEY IDENTITY(1,1),
    EquipmentId INT FOREIGN KEY REFERENCES Equipment(EquipmentId),
    SensorType NVARCHAR(50) NOT NULL,
    AlertType NVARCHAR(20) NOT NULL, -- Warning, Critical
    ThresholdOperator NVARCHAR(10) NOT NULL, -- >, <, >=, <=, =
    ThresholdValue DECIMAL(10,3) NOT NULL,
    IsEnabled BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE()
);
```

#### アラート履歴テーブル（AlertHistory）
```sql
CREATE TABLE AlertHistory (
    AlertId INT PRIMARY KEY IDENTITY(1,1),
    EquipmentId INT FOREIGN KEY REFERENCES Equipment(EquipmentId),
    AlertRuleId INT FOREIGN KEY REFERENCES AlertRules(AlertRuleId),
    AlertType NVARCHAR(20) NOT NULL,
    SensorType NVARCHAR(50) NOT NULL,
    ActualValue DECIMAL(10,3) NOT NULL,
    ThresholdValue DECIMAL(10,3) NOT NULL,
    AlertMessage NVARCHAR(MAX),
    IsAcknowledged BIT DEFAULT 0,
    AcknowledgedBy NVARCHAR(100),
    AcknowledgedAt DATETIME2,
    IsResolved BIT DEFAULT 0,
    ResolvedAt DATETIME2,
    CreatedAt DATETIME2 DEFAULT GETDATE()
);
```

### 1.2 Azure Cosmos DB（IoT データ）

#### センサーデータ ドキュメント
```json
{
  "id": "sensor-{equipmentId}-{timestamp}",
  "deviceId": "equipment-001",
  "equipmentName": "Production Line 1 Motor",
  "timestamp": "2024-01-01T10:00:00.000Z",
  "data": {
    "temperature": {
      "value": 75.5,
      "unit": "celsius",
      "status": "normal"
    },
    "vibration": {
      "value": 2.3,
      "unit": "mm/s",
      "status": "normal"
    },
    "pressure": {
      "value": 4.2,
      "unit": "bar",
      "status": "warning"
    },
    "current": {
      "value": 12.5,
      "unit": "ampere",
      "status": "normal"
    }
  },
  "location": {
    "area": "production-floor-1",
    "coordinates": {
      "x": 15.5,
      "y": 23.1
    }
  },
  "metadata": {
    "firmwareVersion": "1.2.3",
    "lastCalibration": "2024-01-01T00:00:00.000Z",
    "sensorModel": "MultiSensor-Pro-v2"
  },
  "ttl": 7776000,
  "_ts": 1640995200
}
```

#### 設備稼働統計 ドキュメント
```json
{
  "id": "stats-{equipmentId}-{date}",
  "deviceId": "equipment-001",
  "date": "2024-01-01",
  "statistics": {
    "operatingHours": 22.5,
    "downtime": 1.5,
    "efficiency": 93.75,
    "averageTemperature": 74.2,
    "maxTemperature": 78.9,
    "minTemperature": 69.1,
    "alertCount": 3,
    "criticalAlertCount": 0
  },
  "hourlyData": [
    {
      "hour": 0,
      "status": "running",
      "avgTemperature": 72.1,
      "avgVibration": 2.1
    }
  ],
  "type": "daily-statistics",
  "_ts": 1640995200
}
```

## 2. API 設計

### 2.1 RESTful API エンドポイント設計

#### 基本 URL 構造
```
https://{function-app-name}.azurewebsites.net/api/v1/
```

#### 認証ヘッダー
```
Authorization: Bearer {JWT-token}
Content-Type: application/json
```

### 2.2 設備管理 API

#### 設備一覧取得
```http
GET /api/v1/equipment
Query Parameters:
  - status: string (Active, Maintenance, Retired)
  - location: string
  - type: string
  - page: integer (default: 1)
  - limit: integer (default: 20)

Response 200:
{
  "data": [
    {
      "equipmentId": 1,
      "equipmentName": "Production Line 1 Motor",
      "equipmentType": "Motor",
      "location": "Production Floor 1",
      "status": "Active",
      "lastMaintenanceDate": "2024-01-01T10:00:00Z",
      "nextMaintenanceDate": "2024-02-01T10:00:00Z",
      "currentStatus": {
        "temperature": 75.5,
        "vibration": 2.3,
        "lastUpdate": "2024-01-15T14:30:00Z"
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "totalPages": 8
  }
}
```

#### 設備詳細取得
```http
GET /api/v1/equipment/{equipmentId}

Response 200:
{
  "equipmentId": 1,
  "equipmentName": "Production Line 1 Motor",
  "equipmentType": "Motor",
  "serialNumber": "MOT-2024-001",
  "manufacturer": "Industrial Motors Inc.",
  "model": "IM-3000",
  "location": "Production Floor 1",
  "installationDate": "2023-01-15",
  "maintenanceCycleHours": 720,
  "responsiblePerson": "田中太郎",
  "status": "Active",
  "specifications": {
    "power": "30kW",
    "voltage": "400V",
    "maxTemperature": 85
  }
}
```

#### 設備登録
```http
POST /api/v1/equipment
Request Body:
{
  "equipmentName": "New Production Motor",
  "equipmentType": "Motor",
  "serialNumber": "MOT-2024-002",
  "manufacturer": "Industrial Motors Inc.",
  "model": "IM-3000",
  "location": "Production Floor 2",
  "installationDate": "2024-01-20",
  "maintenanceCycleHours": 720,
  "responsiblePerson": "佐藤花子"
}

Response 201:
{
  "equipmentId": 151,
  "message": "設備が正常に登録されました"
}
```

### 2.3 センサーデータ API

#### リアルタイムセンサーデータ取得
```http
GET /api/v1/equipment/{equipmentId}/sensor-data/latest

Response 200:
{
  "equipmentId": 1,
  "timestamp": "2024-01-15T14:30:00Z",
  "sensors": {
    "temperature": {
      "value": 75.5,
      "unit": "celsius",
      "status": "normal"
    },
    "vibration": {
      "value": 2.3,
      "unit": "mm/s",
      "status": "normal"
    },
    "pressure": {
      "value": 4.2,
      "unit": "bar",
      "status": "warning"
    }
  }
}
```

#### 履歴センサーデータ取得
```http
GET /api/v1/equipment/{equipmentId}/sensor-data/history
Query Parameters:
  - startDate: string (ISO 8601 format)
  - endDate: string (ISO 8601 format)
  - sensorType: string (temperature, vibration, pressure)
  - interval: string (minute, hour, day)

Response 200:
{
  "equipmentId": 1,
  "sensorType": "temperature",
  "interval": "hour",
  "data": [
    {
      "timestamp": "2024-01-15T10:00:00Z",
      "value": 74.2,
      "status": "normal"
    },
    {
      "timestamp": "2024-01-15T11:00:00Z",
      "value": 75.8,
      "status": "normal"
    }
  ]
}
```

#### センサーデータ投稿（IoT デバイス用）
```http
POST /api/v1/sensor-data
Request Body:
{
  "deviceId": "equipment-001",
  "timestamp": "2024-01-15T14:30:00Z",
  "sensors": {
    "temperature": 75.5,
    "vibration": 2.3,
    "pressure": 4.2,
    "current": 12.5
  }
}

Response 201:
{
  "message": "センサーデータが正常に保存されました",
  "recordId": "sensor-equipment-001-1640995200"
}
```

### 2.4 メンテナンス管理 API

#### メンテナンススケジュール取得
```http
GET /api/v1/maintenance/schedule
Query Parameters:
  - startDate: string
  - endDate: string
  - equipmentId: integer
  - status: string (Scheduled, InProgress, Completed)

Response 200:
{
  "data": [
    {
      "maintenanceId": 101,
      "equipmentId": 1,
      "equipmentName": "Production Line 1 Motor",
      "maintenanceType": "Scheduled",
      "scheduledDate": "2024-02-01T10:00:00Z",
      "estimatedDuration": 180,
      "worker": "田中太郎",
      "priority": "Medium",
      "status": "Scheduled"
    }
  ]
}
```

#### メンテナンス履歴取得
```http
GET /api/v1/equipment/{equipmentId}/maintenance/history

Response 200:
{
  "equipmentId": 1,
  "maintenanceHistory": [
    {
      "maintenanceId": 100,
      "maintenanceType": "Scheduled",
      "maintenanceDate": "2024-01-01T10:00:00Z",
      "workDescription": "定期点検および清掃作業",
      "worker": "田中太郎",
      "durationMinutes": 120,
      "cost": 15000,
      "status": "Completed"
    }
  ]
}
```

#### メンテナンス予約
```http
POST /api/v1/maintenance/schedule
Request Body:
{
  "equipmentId": 1,
  "maintenanceType": "Scheduled",
  "scheduledDate": "2024-02-15T09:00:00Z",
  "workDescription": "月次定期点検",
  "estimatedDuration": 150,
  "worker": "佐藤花子",
  "priority": "Medium"
}

Response 201:
{
  "maintenanceId": 102,
  "message": "メンテナンスが正常に予約されました"
}
```

### 2.5 アラート管理 API

#### アクティブアラート取得
```http
GET /api/v1/alerts/active
Query Parameters:
  - severity: string (Warning, Critical)
  - equipmentId: integer
  - acknowledged: boolean

Response 200:
{
  "data": [
    {
      "alertId": 501,
      "equipmentId": 1,
      "equipmentName": "Production Line 1 Motor",
      "alertType": "Critical",
      "sensorType": "temperature",
      "message": "温度が危険レベルに達しています",
      "actualValue": 95.5,
      "thresholdValue": 85.0,
      "createdAt": "2024-01-15T14:30:00Z",
      "isAcknowledged": false
    }
  ]
}
```

#### アラート確認
```http
PUT /api/v1/alerts/{alertId}/acknowledge
Request Body:
{
  "acknowledgedBy": "運用管理者",
  "comment": "現地確認を実施します"
}

Response 200:
{
  "message": "アラートが確認されました"
}
```

### 2.6 分析・レポート API

#### 設備稼働率取得
```http
GET /api/v1/analytics/equipment-efficiency
Query Parameters:
  - equipmentId: integer (optional)
  - startDate: string
  - endDate: string
  - groupBy: string (day, week, month)

Response 200:
{
  "data": [
    {
      "equipmentId": 1,
      "equipmentName": "Production Line 1 Motor",
      "period": "2024-01-15",
      "operatingHours": 22.5,
      "downtime": 1.5,
      "efficiency": 93.75,
      "alertCount": 3
    }
  ]
}
```

#### 故障予測データ取得
```http
GET /api/v1/analytics/predictive-maintenance/{equipmentId}

Response 200:
{
  "equipmentId": 1,
  "predictionDate": "2024-01-15T14:30:00Z",
  "riskScore": 0.35,
  "riskLevel": "Medium",
  "predictedFailureDate": "2024-03-15",
  "confidence": 0.78,
  "recommendedActions": [
    "ベアリングの点検を実施してください",
    "潤滑油の交換を検討してください"
  ],
  "keyIndicators": {
    "vibrationTrend": "increasing",
    "temperatureTrend": "stable",
    "powerConsumptionTrend": "increasing"
  }
}
```

## 3. エラーハンドリング

### 3.1 標準エラーレスポンス形式
```json
{
  "error": {
    "code": "EQUIPMENT_NOT_FOUND",
    "message": "指定された設備が見つかりません",
    "details": "Equipment ID 999 does not exist",
    "timestamp": "2024-01-15T14:30:00Z",
    "requestId": "req-12345"
  }
}
```

### 3.2 HTTPステータスコードとエラーコード
- **400 Bad Request**: 無効なリクエストパラメータ
- **401 Unauthorized**: 認証エラー
- **403 Forbidden**: 権限不足
- **404 Not Found**: リソースが見つからない
- **429 Too Many Requests**: レート制限
- **500 Internal Server Error**: サーバー内部エラー

## 4. データバリデーション

### 4.1 入力データ検証規則
```python
# センサーデータ検証例
sensor_data_schema = {
    "deviceId": {"type": "string", "required": True, "maxlength": 50},
    "timestamp": {"type": "datetime", "required": True},
    "sensors": {
        "type": "dict",
        "required": True,
        "schema": {
            "temperature": {"type": "float", "min": -50, "max": 200},
            "vibration": {"type": "float", "min": 0, "max": 100},
            "pressure": {"type": "float", "min": 0, "max": 50}
        }
    }
}
```

## 5. APIセキュリティ

### 5.1 認証方式
- **JWT Bearer Token**: API アクセス用
- **Azure Active Directory**: ユーザー認証
- **API キー**: IoT デバイス用

### 5.2 レート制限
```
一般ユーザー: 1000 requests/hour
管理者: 5000 requests/hour
IoT デバイス: 10000 requests/hour
```

## 6. API ドキュメント生成

### 6.1 OpenAPI 仕様書
```yaml
openapi: 3.0.0
info:
  title: 工場設備管理 API
  version: 1.0.0
  description: 工場設備の監視・管理を行うためのREST API

servers:
  - url: https://factory-management.azurewebsites.net/api/v1
    description: Production server

paths:
  /equipment:
    get:
      summary: 設備一覧取得
      parameters:
        - name: status
          in: query
          schema:
            type: string
            enum: [Active, Maintenance, Retired]
      responses:
        '200':
          description: 設備一覧
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/EquipmentList'
```

## 7. 次のステップ

1. **API 実装**: DEVELOPMENT_GUIDE.md の手順に従って実装
2. **デプロイメント**: DEPLOYMENT_GUIDE.md でデプロイ方法を確認
3. **テスト**: API の単体テスト・統合テストの実装
4. **ドキュメント**: Swagger UI での API ドキュメント公開