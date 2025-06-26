# 工場設備管理システム - データモデル設計書

## 1. データモデル概要

### 1.1 データベース構成概要

```mermaid
graph TB
    %% Azure SQL Database（構造化データ）
    subgraph "Azure SQL Database（構造化データ）"
        Equipment[設備マスター<br/>Equipment]
        MaintenanceHistory[メンテナンス履歴<br/>MaintenanceHistory]
        AlertRules[アラート定義<br/>AlertRules]
        AlertHistory[アラート履歴<br/>AlertHistory]
        Users[ユーザーマスター<br/>Users]
        Roles[ロールマスター<br/>Roles]
        WorkOrders[作業指示<br/>WorkOrders]
        Parts[部品マスター<br/>Parts]
        PartUsage[部品使用履歴<br/>PartUsage]
        Reports[レポート定義<br/>Reports]
    end

    %% Azure Cosmos DB（NoSQLデータ）
    subgraph "Azure Cosmos DB（IoTデータ）"
        SensorData[センサーデータ<br/>SensorData]
        EquipmentStats[設備稼働統計<br/>EquipmentStats]
        AlertEvents[アラートイベント<br/>AlertEvents]
        AuditLogs[監査ログ<br/>AuditLogs]
    end

    %% Azure Storage（ファイルデータ）
    subgraph "Azure Storage（ファイル）"
        Documents[ドキュメント<br/>Manuals/Reports]
        Images[画像<br/>Equipment Photos]
        Videos[動画<br/>Maintenance Videos]
        Backups[バックアップ<br/>Historical Data]
    end

    %% データ関連性
    Equipment --> MaintenanceHistory
    Equipment --> SensorData
    Equipment --> AlertRules
    AlertRules --> AlertHistory
    AlertHistory --> AlertEvents
    Users --> Roles
    WorkOrders --> MaintenanceHistory
    Parts --> PartUsage
    PartUsage --> MaintenanceHistory
    Equipment --> EquipmentStats
    Users --> AuditLogs
```

### 1.2 データベース選択理由

#### Azure SQL Database
- **ACID特性**: トランザクション整合性が重要なマスタデータ
- **複雑なクエリ**: JOINを多用する分析クエリに最適
- **レポート機能**: Power BIとの親和性が高い

#### Azure Cosmos DB
- **高スループット**: 大量のIoTデータ取り込み
- **水平スケーリング**: データ量増加に対応
- **低遅延**: リアルタイム監視要件に対応

#### Azure Storage
- **コスト効率**: 大容量ファイルの安価な保存
- **アクセス頻度**: 低頻度アクセスデータの長期保管

## 2. Azure SQL Database - 構造化データモデル

### 2.1 設備マスターテーブル（Equipment）

```mermaid
erDiagram
    Equipment {
        int EquipmentId PK
        string EquipmentName
        string EquipmentType
        string SerialNumber UK
        string Manufacturer
        string Model
        string Location
        date InstallationDate
        int MaintenanceCycleHours
        string ResponsiblePerson
        string Status
        datetime CreatedAt
        datetime UpdatedAt
    }
    
    Equipment ||--o{ MaintenanceHistory : "1対多"
    Equipment ||--o{ AlertRules : "1対多"
    Equipment ||--o{ WorkOrders : "1対多"
```

**テーブル仕様**:
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

### 2.2 メンテナンス関連テーブル

```mermaid
erDiagram
    MaintenanceHistory {
        int MaintenanceId PK
        int EquipmentId FK
        datetime MaintenanceDate
        string MaintenanceType
        string Description
        string Technician
        int DurationMinutes
        string Result
        decimal Cost
        datetime NextScheduledDate
        string Notes
    }
    
    WorkOrders {
        int WorkOrderId PK
        int EquipmentId FK
        string WorkOrderNumber UK
        string Title
        string Description
        string Priority
        string Status
        datetime ScheduledDate
        datetime StartDate
        datetime CompletionDate
        string AssignedTechnician
        decimal EstimatedCost
        decimal ActualCost
    }
    
    Parts {
        int PartId PK
        string PartNumber UK
        string PartName
        string Description
        string Category
        decimal UnitCost
        int StockQuantity
        int MinStockLevel
        string Supplier
        string Location
    }
    
    PartUsage {
        int UsageId PK
        int MaintenanceId FK
        int PartId FK
        int QuantityUsed
        decimal UnitCost
        decimal TotalCost
        datetime UsageDate
    }
    
    MaintenanceHistory ||--o{ PartUsage : "1対多"
    Parts ||--o{ PartUsage : "1対多"
    Equipment ||--o{ MaintenanceHistory : "1対多"
    Equipment ||--o{ WorkOrders : "1対多"
```

### 2.3 アラート・通知テーブル

```mermaid
erDiagram
    AlertRules {
        int AlertRuleId PK
        int EquipmentId FK
        string MetricName
        string Operator
        decimal ThresholdValue
        int DurationMinutes
        string Severity
        boolean IsEnabled
        string NotificationMethod
        string Recipients
    }
    
    AlertHistory {
        int AlertId PK
        int AlertRuleId FK
        int EquipmentId FK
        datetime AlertTime
        string MetricName
        decimal ActualValue
        decimal ThresholdValue
        string Severity
        string Status
        datetime AcknowledgedTime
        string AcknowledgedBy
        string Resolution
        datetime ResolvedTime
    }
    
    Equipment ||--o{ AlertRules : "1対多"
    AlertRules ||--o{ AlertHistory : "1対多"
```

### 2.4 ユーザー・権限管理テーブル

```mermaid
erDiagram
    Users {
        int UserId PK
        string Username UK
        string Email UK
        string FullName
        string Department
        string Position
        boolean IsActive
        datetime LastLoginDate
        datetime CreatedAt
    }
    
    Roles {
        int RoleId PK
        string RoleName UK
        string Description
        string Permissions
        boolean IsActive
    }
    
    UserRoles {
        int UserRoleId PK
        int UserId FK
        int RoleId FK
        datetime AssignedDate
        datetime ExpiryDate
        boolean IsActive
    }
    
    Users ||--o{ UserRoles : "1対多"
    Roles ||--o{ UserRoles : "1対多"
```

## 3. Azure Cosmos DB - NoSQLデータモデル

### 3.1 センサーデータコレクション

```mermaid
graph TB
    subgraph "SensorData Collection"
        subgraph "Document Structure"
            A[id: sensor-equipmentId-timestamp]
            B[deviceId: equipment-001]
            C[equipmentName: Production Line 1 Motor]
            D[timestamp: 2024-01-01T10:00:00.000Z]
            E[data: センサー測定値オブジェクト]
            F[location: 設置場所情報]
            G[metadata: センサーメタデータ]
            H[ttl: データ保持期間]
        end
        
        subgraph "Data Object"
            E1[temperature: 温度データ]
            E2[vibration: 振動データ]
            E3[pressure: 圧力データ]  
            E4[current: 電流データ]
        end
        
        subgraph "Sensor Value"
            V1[value: 測定値]
            V2[unit: 単位]
            V3[status: ステータス]
            V4[quality: データ品質]
        end
        
        E --> E1
        E --> E2
        E --> E3
        E --> E4
        
        E1 --> V1
        E1 --> V2
        E1 --> V3
        E1 --> V4
    end
```

**ドキュメント例**:
```json
{
  "id": "sensor-equipment-001-20240101100000",
  "deviceId": "equipment-001",
  "equipmentName": "Production Line 1 Motor",
  "timestamp": "2024-01-01T10:00:00.000Z",
  "data": {
    "temperature": {
      "value": 75.5,
      "unit": "celsius",
      "status": "normal",
      "quality": "good"
    },
    "vibration": {
      "value": 2.3,
      "unit": "mm/s",
      "status": "normal",
      "quality": "good"
    },
    "pressure": {
      "value": 4.2,
      "unit": "bar",
      "status": "warning",
      "quality": "fair"
    },
    "current": {
      "value": 12.5,
      "unit": "ampere",
      "status": "normal",
      "quality": "good"
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
  "_ts": 1704110400
}
```

### 3.2 設備稼働統計コレクション

```mermaid
graph TB
    subgraph "EquipmentStats Collection"
        subgraph "Aggregated Data"
            A[id: stats-equipmentId-date]
            B[equipmentId: equipment-001]
            C[date: 2024-01-01]
            D[period: daily/hourly/monthly]
            E[operatingStats: 稼働統計]
            F[alarmSummary: アラーム集計]
            G[maintenanceEvents: メンテナンス情報]
        end
        
        subgraph "Operating Stats"
            E1[totalRuntime: 総稼働時間]
            E2[downtime: 停止時間]
            E3[efficiency: 稼働率]
            E4[productionOutput: 生産量]
            E5[energyConsumption: 消費電力]
        end
        
        subgraph "Alarm Summary"
            F1[totalAlarms: 総アラーム数]
            F2[criticalAlarms: 重要アラーム数]
            F3[warningAlarms: 警告アラーム数]
            F4[avgResolutionTime: 平均解決時間]
        end
        
        E --> E1
        E --> E2
        E --> E3
        E --> E4
        E --> E5
        
        F --> F1
        F --> F2
        F --> F3
        F --> F4
    end
```

### 3.3 アラートイベントコレクション

```mermaid
graph TB
    subgraph "AlertEvents Collection"
        subgraph "Event Document"
            A[id: alert-alertId-timestamp]
            B[alertId: アラートID]
            C[equipmentId: 設備ID]
            D[timestamp: 発生時刻]
            E[eventType: イベント種別]
            F[severity: 重要度]
            G[details: 詳細情報]
            H[context: コンテキスト情報]
        end
        
        subgraph "Event Types"
            E1[TRIGGERED: アラート発生]
            E2[ACKNOWLEDGED: 確認済み]
            E3[RESOLVED: 解決済み]
            E4[ESCALATED: エスカレーション]
        end
        
        subgraph "Context Info"
            H1[user: 操作ユーザー]
            H2[action: 実行アクション]
            H3[previousState: 前の状態]
            H4[additionalData: 追加データ]
        end
        
        E --> E1
        E --> E2
        E --> E3
        E --> E4
        
        H --> H1
        H --> H2
        H --> H3
        H --> H4
    end
```

## 4. データ分散・パーティション戦略

### 4.1 Cosmos DB パーティション設計

```mermaid
graph TB
    subgraph "Partition Strategy"
        subgraph "SensorData"
            S1[Partition Key: /equipmentId]
            S2[Time-based partitioning]
            S3[Hot: 24時間以内]
            S4[Warm: 30日以内] 
            S5[Cold: 3年保管]
        end
        
        subgraph "EquipmentStats"
            E1[Partition Key: /equipmentId]
            E2[Date-based partitioning]
            E3[Daily aggregation]
            E4[Monthly rollup]
        end
        
        subgraph "AlertEvents"
        A1[Partition Key: /equipmentId]
        A2[Severity-based indexing]
        A3[Time-series optimization]
        A4[Event correlation]
        end
    end

    subgraph "Data Lifecycle"
        L1[Real-time: Cosmos DB]
        L2[Analytics: SQL Database]
        L3[Archive: Azure Storage]
        
        L1 --> L2
        L2 --> L3
    end
```

### 4.2 データアーカイブ戦略

#### データ階層化
- **ホットデータ（0-24時間）**: Cosmos DB（高性能SSD）
- **ウォームデータ（1-30日）**: SQL Database（標準SSD）
- **コールドデータ（30日-3年）**: Azure Storage（低コストHDD）

#### 自動アーカイブ
```mermaid
sequenceDiagram
    participant CD as Cosmos DB
    participant AF as Azure Functions
    participant SQL as SQL Database  
    participant AS as Azure Storage
    
    Note over CD,AS: 日次バッチ処理
    
    AF->>CD: 24時間経過データ抽出
    CD-->>AF: センサーデータ
    AF->>SQL: 集計データ保存
    AF->>AS: RAWデータアーカイブ
    AF->>CD: 古いデータ削除
```

## 5. データ品質・バリデーション

### 5.1 データ検証ルール

```mermaid
graph TB
    subgraph "Data Validation Pipeline"
        A[データ受信] --> B[基本検証]
        B --> C[範囲チェック]
        C --> D[整合性チェック]
        D --> E[品質評価]
        E --> F[データ保存]
        
        B --> G[エラーログ]
        C --> G
        D --> G
        E --> H[品質レポート]
    end
    
    subgraph "Validation Rules"
        V1[必須フィールド検証]
        V2[データ型検証]
        V3[値域範囲検証]
        V4[時系列連続性検証]
        V5[設備状態整合性検証]
    end
    
    subgraph "Quality Metrics"
        Q1[完全性: 欠損データ率]
        Q2[正確性: 異常値率]
        Q3[整合性: 矛盾データ率]
        Q4[適時性: 遅延データ率]
    end
```

### 5.2 データ補完・修復

#### 欠損データ補完
- **線形補間**: 短時間の欠損（< 5分）
- **統計的推定**: 中時間の欠損（5-30分）
- **機械学習予測**: 長時間の欠損（> 30分）

#### 異常値処理
- **統計的外れ値検出**: Z-score、IQR法
- **時系列異常検出**: 季節分解、LSTM
- **多変量異常検出**: 相関分析、クラスタリング

## 6. データセキュリティ・プライバシー

### 6.1 暗号化戦略

```mermaid
graph TB
    subgraph "Data at Rest"
        R1[SQL DB: TDE暗号化]
        R2[Cosmos DB: 自動暗号化]
        R3[Storage: SSE-AES256]
        R4[Key Vault: キー管理]
    end
    
    subgraph "Data in Transit"
        T1[HTTPS/TLS 1.3]
        T2[VPN接続]
        T3[Private Endpoint]
        T4[証明書管理]
    end
    
    subgraph "Data in Processing"
        P1[メモリ暗号化]
        P2[一時ファイル暗号化]
        P3[ログマスキング]
        P4[スクリーニング]
    end
```

### 6.2 アクセス制御

#### データ分類
- **Public**: 一般的な設備情報
- **Internal**: 運用データ・統計情報
- **Confidential**: 性能データ・分析結果
- **Restricted**: 個人情報・セキュリティ情報

#### 最小権限アクセス
- **読み取り専用**: レポート閲覧者
- **データ入力**: 現場オペレーター
- **データ管理**: システム管理者
- **フルアクセス**: データベース管理者

## 7. パフォーマンス最適化

### 7.1 インデックス戦略

#### SQL Database
```sql
-- 設備マスター: 複合インデックス
CREATE INDEX IX_Equipment_Type_Location 
ON Equipment (EquipmentType, Location);

-- メンテナンス履歴: 時系列インデックス
CREATE INDEX IX_MaintenanceHistory_Date_Equipment 
ON MaintenanceHistory (MaintenanceDate DESC, EquipmentId);

-- アラート履歴: 複合インデックス
CREATE INDEX IX_AlertHistory_Status_Severity_Time 
ON AlertHistory (Status, Severity, AlertTime DESC);
```

#### Cosmos DB
```json
{
  "indexingPolicy": {
    "indexingMode": "consistent",
    "automatic": true,
    "includedPaths": [
      {
        "path": "/equipmentId/?",
        "indexes": [{"kind": "Hash"}]
      },
      {
        "path": "/timestamp/?",
        "indexes": [{"kind": "Range"}]
      },
      {
        "path": "/data/*/status/?",
        "indexes": [{"kind": "Hash"}]
      }
    ],
    "excludedPaths": [
      {
        "path": "/metadata/*"
      }
    ]
  }
}
```

### 7.2 クエリ最適化

#### データアグリゲーション
- **リアルタイム集計**: Stream Analytics
- **定期集計**: Azure Functions（タイマートリガー）
- **オンデマンド集計**: SQL Serverストアドプロシージャ

#### キャッシュ戦略
- **Redis Cache**: よく使用されるマスターデータ
- **Application Cache**: 計算済み統計データ
- **CDN**: 静的コンテンツ（レポートPDF等）

---

このデータモデル設計書により、大規模IoTデータの効率的な管理と高性能なアクセスを実現し、工場設備管理システムの要求を満たすことができます。