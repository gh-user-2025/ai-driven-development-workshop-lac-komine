# 工場設備管理システム - アプリケーションアーキテクチャ設計書

## 1. システム全体アーキテクチャ

### 1.1 システム構成概要

```mermaid
graph TB
    %% データ収集層
    subgraph "データ収集層"
        IoT[IoTセンサー<br/>温度・振動・圧力・電流]
        Legacy[既存SCADA<br/>システム]
        Manual[手動入力<br/>データ]
    end

    %% データ処理層
    subgraph "Azure クラウド環境"
        subgraph "データ取り込み"
            EventHub[Azure Event Hubs<br/>IoTデータストリーミング]
            API[データ取り込みAPI<br/>Azure Functions]
        end
        
        subgraph "データ保存"
            CosmosDB[Azure Cosmos DB<br/>IoTデータ/時系列データ]
            SqlDB[Azure SQL Database<br/>マスタデータ/分析結果]
        end
        
        subgraph "データ処理・分析"
            Functions[Azure Functions<br/>リアルタイム処理]
            Analytics[AI分析エンジン<br/>予知保全・異常検知]
            Batch[Azure Data Factory<br/>バッチ処理]
        end
        
        subgraph "認証・セキュリティ"
            AAD[Azure Active Directory<br/>統合認証]
            KeyVault[Azure Key Vault<br/>秘密情報管理]
        end
    end

    %% アプリケーション層
    subgraph "アプリケーション層"
        WebApp[Vue.js フロントエンド<br/>レスポンシブUI]
        RestAPI[REST API<br/>Azure Functions]
        GraphQL[GraphQL API<br/>データクエリ最適化]
    end

    %% 可視化・レポート層
    subgraph "可視化・レポート層"
        PowerBI[Power BI<br/>分析レポート]
        Dashboard[リアルタイム<br/>ダッシュボード]
        Mobile[モバイルアプリ<br/>現場監視]
    end

    %% 外部システム連携
    subgraph "外部システム"
        ERP[ERP システム<br/>生産計画連携]
        CMMS[CMMS<br/>保守管理システム]
        Email[メール<br/>通知システム]
        SMS[SMS<br/>緊急通知]
    end

    %% データフロー
    IoT --> EventHub
    Legacy --> API
    Manual --> WebApp
    
    EventHub --> Functions
    API --> CosmosDB
    API --> SqlDB
    
    Functions --> CosmosDB
    Functions --> SqlDB
    Functions --> Analytics
    
    CosmosDB --> RestAPI
    SqlDB --> RestAPI
    Analytics --> SqlDB
    
    Batch --> SqlDB
    Batch --> CosmosDB
    
    RestAPI --> WebApp
    GraphQL --> WebApp
    WebApp --> Dashboard
    
    SqlDB --> PowerBI
    CosmosDB --> PowerBI
    
    AAD --> WebApp
    AAD --> RestAPI
    KeyVault --> Functions
    
    RestAPI --> ERP
    RestAPI --> CMMS
    Functions --> Email
    Functions --> SMS
    
    Dashboard --> Mobile
```

### 1.2 アーキテクチャの特徴

#### マイクロサービスアーキテクチャ
- 各機能を独立したサービスとして実装
- スケーラビリティと保守性を向上
- 障害の局所化とシステム全体の可用性向上

#### サーバーレスアーキテクチャ
- Azure Functionsによる自動スケーリング
- 使用量に応じた課金でコスト最適化
- 運用管理の簡素化

#### イベントドリブンアーキテクチャ
- リアルタイムデータ処理
- 非同期処理による高いスループット
- システム間の疎結合

## 2. データアーキテクチャ

### 2.1 データフロー詳細

```mermaid
flowchart LR
    %% データ源
    subgraph "データソース"
        S1[IoTセンサー]
        S2[SCADA]
        S3[手動入力]
        S4[外部システム]
    end

    %% 取り込み層
    subgraph "データ取り込み"
        I1[Event Hubs<br/>ストリーミング]
        I2[REST API<br/>バッチ/リアルタイム]
        I3[Azure Data Factory<br/>ETLパイプライン]
    end

    %% 変換・処理層
    subgraph "データ変換・処理"
        T1[Stream Analytics<br/>リアルタイム変換]
        T2[Azure Functions<br/>データ検証・補完]
        T3[Machine Learning<br/>異常検知・予測]
    end

    %% 保存層
    subgraph "データ保存"
        D1[Cosmos DB<br/>RAWデータ/時系列]
        D2[SQL Database<br/>マスタ/分析結果]
        D3[Azure Storage<br/>ファイル/ログ]
    end

    %% 配信層
    subgraph "データ配信"
        O1[REST API<br/>アプリ向け]
        O2[GraphQL<br/>複雑クエリ]
        O3[Power BI<br/>BI分析]
        O4[Event Grid<br/>通知配信]
    end

    %% データフロー接続
    S1 --> I1
    S2 --> I2
    S3 --> I2
    S4 --> I3

    I1 --> T1
    I2 --> T2
    I3 --> T2

    T1 --> D1
    T2 --> D1
    T2 --> D2
    T3 --> D2

    D1 --> O1
    D2 --> O1
    D1 --> O2
    D2 --> O2
    D2 --> O3
    
    T1 --> O4
    T3 --> O4
```

### 2.2 データ保存戦略

#### ホット・ウォーム・コールドデータ分離
- **ホットデータ**: 直近24時間のリアルタイムデータ（Cosmos DB）
- **ウォームデータ**: 過去30日の分析用データ（SQL Database）
- **コールドデータ**: 3年保管の履歴データ（Azure Storage）

#### データパーティション戦略
- 時間ベースパーティション（日・月単位）
- 設備IDベースパーティション
- 地理的分散によるパフォーマンス最適化

## 3. セキュリティアーキテクチャ

### 3.1 セキュリティ層別構成

```mermaid
graph TB
    %% 認証・認可層
    subgraph "認証・認可層"
        AAD[Azure Active Directory<br/>統合認証]
        MFA[多要素認証<br/>MFA]
        RBAC[ロールベースアクセス制御<br/>RBAC]
        SAML[SAML認証<br/>Enterprise SSO]
    end

    %% ネットワークセキュリティ層
    subgraph "ネットワークセキュリティ"
        Firewall[Azure Firewall<br/>ネットワーク制御]
        WAF[Web Application Firewall<br/>アプリ保護]
        VPN[Site-to-Site VPN<br/>工場ネットワーク接続]
        PrivateLink[Private Link<br/>プライベート接続]
    end

    %% データ保護層
    subgraph "データ保護"
        Encryption[Azure暗号化<br/>保存時・転送時]
        TDE[Transparent Data Encryption<br/>DB暗号化]
        KeyVault[Azure Key Vault<br/>キー管理]
        DLP[Data Loss Prevention<br/>データ漏洩防止]
    end

    %% 監視・監査層
    subgraph "監視・監査"
        Sentinel[Azure Sentinel<br/>SIEM]
        Monitor[Azure Monitor<br/>ログ監視]
        Compliance[コンプライアンス<br/>規制対応]
        Audit[監査ログ<br/>操作記録]
    end

    %% アプリケーション
    subgraph "アプリケーション"
        Web[Webアプリケーション]
        API[REST API]
        Mobile[モバイルアプリ]
    end

    %% セキュリティフロー
    Web --> AAD
    API --> AAD
    Mobile --> AAD
    
    AAD --> MFA
    AAD --> RBAC
    AAD --> SAML
    
    Web --> WAF
    API --> WAF
    WAF --> Firewall
    
    Firewall --> VPN
    API --> PrivateLink
    
    Web --> Encryption
    API --> Encryption
    Encryption --> TDE
    TDE --> KeyVault
    
    Web --> Monitor
    API --> Monitor
    Monitor --> Sentinel
    Monitor --> Audit
    Sentinel --> Compliance
```

### 3.2 セキュリティ要件

#### 認証・認可
- Azure Active Directory統合によるSSO
- 多要素認証（MFA）必須
- ロールベースアクセス制御（RBAC）
- 最小権限の原則

#### データ保護
- AES-256による暗号化（保存時・転送時）
- Azure Key Vaultによるキー管理
- データマスキング（非本番環境）
- PII（個人識別情報）の適切な管理

#### ネットワークセキュリティ
- Web Application Firewall（WAF）
- Network Security Groups（NSG）
- DDoS Protection
- Private Linkによるプライベート接続

## 4. 運用・監視アーキテクチャ

### 4.1 監視・ロギング構成

```mermaid
graph TB
    %% アプリケーション層
    subgraph "アプリケーション"
        App[Vue.js App]
        API[REST API]
        Functions[Azure Functions]
        DB[Database]
    end

    %% 監視・ログ収集
    subgraph "監視・ログ収集"
        AppInsights[Application Insights<br/>APM監視]
        LogAnalytics[Log Analytics<br/>ログ集約]
        Metrics[Azure Metrics<br/>メトリクス収集]
    end

    %% 分析・アラート
    subgraph "分析・アラート"
        Monitor[Azure Monitor<br/>統合監視]
        Alerts[Azure Alerts<br/>アラート管理]
        Workbook[Azure Workbooks<br/>ダッシュボード]
    end

    %% 通知・対応
    subgraph "通知・対応"
        ActionGroup[Action Groups<br/>通知ルール]
        Logic[Logic Apps<br/>自動対応]
        Teams[Microsoft Teams<br/>チーム通知]
        Email[Email通知]
    end

    %% 監視フロー
    App --> AppInsights
    API --> AppInsights
    Functions --> AppInsights
    DB --> Metrics
    
    AppInsights --> LogAnalytics
    Metrics --> LogAnalytics
    
    LogAnalytics --> Monitor
    Monitor --> Alerts
    Monitor --> Workbook
    
    Alerts --> ActionGroup
    ActionGroup --> Logic
    ActionGroup --> Teams
    ActionGroup --> Email
    
    Logic --> Functions
```

### 4.2 監視項目

#### パフォーマンス監視
- API応答時間（95%tile < 500ms）
- データベースクエリ性能
- Function実行時間
- リアルタイムデータ遅延

#### 可用性監視
- エンドポイント生存監視
- サービス稼働率（99.9%以上）
- 依存サービス監視
- 自動フェイルオーバー

#### セキュリティ監視
- 認証失敗監視
- 異常アクセスパターン検知
- データアクセス監査
- セキュリティインシデント対応

## 5. 災害復旧・事業継続計画

### 5.1 バックアップ・復旧戦略

```mermaid
graph LR
    %% 本番環境
    subgraph "本番環境（Primary Region）"
        P1[Azure SQL Database<br/>自動バックアップ]
        P2[Cosmos DB<br/>継続バックアップ]
        P3[Azure Storage<br/>GRS複製]
        P4[Application<br/>Blue-Green Deploy]
    end

    %% 災害復旧環境
    subgraph "災害復旧環境（Secondary Region）"
        S1[SQL Database<br/>Geo-Replica]
        S2[Cosmos DB<br/>Multi-Region]
        S3[Storage<br/>Read-Access GRS]
        S4[Application<br/>Standby]
    end

    %% バックアップフロー
    P1 --> S1
    P2 --> S2
    P3 --> S3
    P4 --> S4

    %% フェイルオーバー
    S1 -.-> |自動フェイルオーバー| P1
    S2 -.-> |手動フェイルオーバー| P2
    S4 -.-> |Traffic Manager| P4
```

### 5.2 復旧目標

#### RTO（Recovery Time Objective）
- **Critical Systems**: 30分以内
- **Core Applications**: 2時間以内
- **Reporting Systems**: 4時間以内

#### RPO（Recovery Point Objective）
- **Transaction Data**: 15分以内
- **IoT Sensor Data**: 1時間以内
- **Configuration Data**: 24時間以内

## 6. パフォーマンス最適化

### 6.1 スケーリング戦略

#### 水平スケーリング
- Azure Functions の自動スケール
- Cosmos DB の自動パーティション
- Application Gateway の負荷分散

#### 垂直スケーリング  
- SQL Database のDTU調整
- App Service のインスタンスサイズ
- 需要に応じたリソース調整

### 6.2 キャッシュ戦略

#### 多層キャッシュ
- **L1**: ブラウザキャッシュ（静的リソース）
- **L2**: CDNキャッシュ（グローバル配信）
- **L3**: Azure Redis Cache（セッション・API）
- **L4**: アプリケーションキャッシュ（インメモリ）

#### キャッシュ更新戦略
- リアルタイムデータ：TTL短縮（30秒）
- マスタデータ：長期キャッシュ（1時間）
- 分析結果：定期更新（15分）

---

この設計書は工場設備管理システムの全体的なアーキテクチャを示しており、スケーラブルで可用性が高く、セキュアなシステムの実現を目指しています。