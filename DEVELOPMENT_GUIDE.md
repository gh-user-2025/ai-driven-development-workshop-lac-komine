# 開発手順とガイドライン

## 1. 開発環境セットアップ

### 1.1 前提条件
- Azure CLI がインストール済み（AZURE_SETUP.md で設定）
- Visual Studio Code
- Python 3.9 以上
- Node.js 16 以上（フロントエンド開発用）
- Git

### 1.2 ローカル開発環境の構築

#### Python環境セットアップ
```bash
# 仮想環境の作成
python -m venv factory-management-env

# 仮想環境の有効化（Windows）
factory-management-env\Scripts\activate

# 仮想環境の有効化（macOS/Linux）
source factory-management-env/bin/activate

# 必要なパッケージのインストール
pip install azure-functions
pip install azure-cosmos
pip install pyodbc
pip install flask
pip install pandas
pip install numpy
pip install azure-monitor-opentelemetry-exporter
pip install python-dotenv
```

#### Node.js環境セットアップ（フロントエンド）
```bash
# Vue CLI のインストール
npm install -g @vue/cli

# プロジェクトディレクトリの作成
vue create factory-management-frontend

# 必要なパッケージのインストール
cd factory-management-frontend
npm install axios
npm install chart.js
npm install vue-chartjs
npm install vuetify
```

### 1.3 Azure Functions Core Tools
```bash
# Azure Functions Core Tools のインストール
npm install -g azure-functions-core-tools@4 --unsafe-perm true
```

## 2. プロジェクト構造

```
factory-management/
├── backend/
│   ├── functions/
│   │   ├── data-processor/         # データ処理関数
│   │   ├── sensor-data-receiver/   # センサーデータ受信
│   │   ├── maintenance-scheduler/  # メンテナンス管理
│   │   └── analytics-engine/       # データ分析
│   ├── shared/
│   │   ├── database/              # データベース接続
│   │   ├── models/                # データモデル
│   │   └── utils/                 # ユーティリティ
│   ├── requirements.txt
│   └── host.json
├── frontend/
│   ├── src/
│   │   ├── components/            # Vue コンポーネント
│   │   ├── views/                 # ページビュー
│   │   ├── store/                 # Vuex ストア
│   │   └── services/              # API サービス
│   ├── public/
│   └── package.json
├── data/
│   ├── sample-data/               # サンプルデータ
│   └── sql-scripts/               # SQL スクリプト
├── docs/
│   ├── api/                       # API ドキュメント
│   └── architecture/              # アーキテクチャ図
└── deploy/
    ├── azure-pipelines.yml
    └── terraform/                 # Infrastructure as Code
```

## 3. 開発フロー

### 3.1 Git ワークフロー

#### ブランチ戦略
```bash
# 新機能開発用ブランチ作成
git checkout -b feature/sensor-data-processing

# 開発完了後のマージ
git checkout main
git merge feature/sensor-data-processing
```

#### コミットメッセージ規約
```
feat: 新機能追加
fix: バグ修正
docs: ドキュメント更新
style: コードスタイル修正
refactor: リファクタリング
test: テスト追加・修正
chore: その他のタスク
```

### 3.2 AI-Driven Development プロセス

#### GitHub Copilot 活用指針
1. **機能実装時**
   - コメントで実装したい機能を詳細に記述
   - 関数名と引数を明確に定義してから実装
   - エラーハンドリングも含めて提案を受ける

2. **テスト作成時**
   - テストケースをコメントで列挙
   - 境界値テストやエラーケースも含める
   - モックを使った単体テストを作成

3. **ドキュメント作成時**
   - コードの意図を自然言語で説明
   - API仕様書の自動生成を活用

#### コード品質管理
```bash
# Python コード品質チェック
pip install flake8 black pytest

# コードフォーマット
black backend/

# リンター実行
flake8 backend/

# テスト実行
pytest backend/tests/
```

## 4. 各層の開発ガイドライン

### 4.1 Backend（Azure Functions）開発

#### 基本的なFunction構造
```python
# 例: センサーデータ処理関数の基本構造
import logging
import json
import azure.functions as func
from shared.database.cosmos_client import CosmosClient

def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    センサーデータを受信して処理する関数
    """
    logging.info('センサーデータ処理関数が開始されました')
    
    try:
        # リクエストデータの取得
        req_body = req.get_json()
        
        # データ検証
        if not validate_sensor_data(req_body):
            return func.HttpResponse(
                "無効なデータです",
                status_code=400
            )
        
        # データ処理・保存
        cosmos_client = CosmosClient()
        result = cosmos_client.save_sensor_data(req_body)
        
        return func.HttpResponse(
            json.dumps({"status": "success", "id": result}),
            status_code=200
        )
        
    except Exception as e:
        logging.error(f'エラーが発生しました: {str(e)}')
        return func.HttpResponse(
            "内部サーバーエラー",
            status_code=500
        )
```

#### ローカルでのFunction実行
```bash
# Functions プロジェクト初期化
cd backend
func init factory-management-functions --python

# Function 作成
func new --name sensor-data-receiver --template "HTTP trigger"

# ローカル実行
func start
```

### 4.2 Frontend（Vue.js）開発

#### コンポーネント設計原則
1. **単一責任の原則**: 各コンポーネントは一つの責任のみ
2. **再利用性**: 汎用的なコンポーネントは共通化
3. **データの流れ**: Props down, Events up パターン

#### サンプル：ダッシュボードコンポーネント
```javascript
// Dashboard.vue の基本構造
<template>
  <div class="dashboard">
    <equipment-status-card 
      v-for="equipment in equipments" 
      :key="equipment.id"
      :equipment="equipment"
      @alert="handleAlert"
    />
  </div>
</template>

<script>
import EquipmentStatusCard from '@/components/EquipmentStatusCard.vue'
import { equipmentService } from '@/services/equipmentService'

export default {
  name: 'Dashboard',
  components: {
    EquipmentStatusCard
  },
  data() {
    return {
      equipments: []
    }
  },
  async mounted() {
    await this.loadEquipments()
  },
  methods: {
    async loadEquipments() {
      try {
        this.equipments = await equipmentService.getAll()
      } catch (error) {
        console.error('設備データの読み込みに失敗しました:', error)
      }
    },
    handleAlert(alertData) {
      // アラート処理
      this.$emit('alert', alertData)
    }
  }
}
</script>
```

#### フロントエンド開発・ビルド
```bash
# 開発サーバー起動
cd frontend
npm run serve

# プロダクションビルド
npm run build

# テスト実行
npm run test:unit
```

### 4.3 データベース開発

#### SQL Database スキーマ作成
```sql
-- 設備マスターテーブル
CREATE TABLE Equipment (
    EquipmentId INT PRIMARY KEY IDENTITY(1,1),
    EquipmentName NVARCHAR(100) NOT NULL,
    EquipmentType NVARCHAR(50) NOT NULL,
    Location NVARCHAR(100) NOT NULL,
    InstallationDate DATE NOT NULL,
    MaintenanceCycle INT NOT NULL, -- 日数
    ResponsiblePerson NVARCHAR(100),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE()
);

-- メンテナンス履歴テーブル
CREATE TABLE MaintenanceHistory (
    MaintenanceId INT PRIMARY KEY IDENTITY(1,1),
    EquipmentId INT FOREIGN KEY REFERENCES Equipment(EquipmentId),
    MaintenanceDate DATETIME2 NOT NULL,
    WorkDescription NVARCHAR(MAX),
    Worker NVARCHAR(100),
    Duration INT, -- 分
    NextScheduledDate DATE,
    CreatedAt DATETIME2 DEFAULT GETDATE()
);
```

#### Cosmos DB データ構造
```json
{
  "id": "sensor-data-{timestamp}",
  "deviceId": "equipment-001",
  "timestamp": "2024-01-01T10:00:00Z",
  "sensorType": "temperature",
  "value": 75.5,
  "unit": "celsius",
  "status": "normal",
  "location": "production-line-1",
  "metadata": {
    "calibrationDate": "2024-01-01",
    "sensorModel": "TMP-001"
  }
}
```

## 5. テスト戦略

### 5.1 単体テスト
```python
# pytest を使用した単体テスト例
import pytest
from unittest.mock import Mock, patch
from functions.sensor_data_receiver import main

class TestSensorDataReceiver:
    def test_valid_sensor_data(self):
        """有効なセンサーデータの処理テスト"""
        # テストデータ準備
        mock_req = Mock()
        mock_req.get_json.return_value = {
            "deviceId": "equipment-001",
            "temperature": 75.5,
            "timestamp": "2024-01-01T10:00:00Z"
        }
        
        # テスト実行
        response = main(mock_req)
        
        # 検証
        assert response.status_code == 200
        
    def test_invalid_sensor_data(self):
        """無効なセンサーデータの処理テスト"""
        mock_req = Mock()
        mock_req.get_json.return_value = {}
        
        response = main(mock_req)
        
        assert response.status_code == 400
```

### 5.2 統合テスト
```bash
# Azure Functions の統合テスト
cd backend
pytest tests/integration/ -v

# フロントエンドの統合テスト
cd frontend
npm run test:integration
```

## 6. デバッグとトラブルシューティング

### 6.1 ローカルデバッグ
```bash
# Azure Functions のデバッグ
func start --debug

# Vue.js のデバッグ
npm run serve -- --mode development
```

### 6.2 ログ監視
```bash
# Azure Functions のログ確認
az functionapp log tail --name <function-app-name> --resource-group <resource-group>

# Application Insights クエリ例
traces
| where cloud_RoleName == "factory-management-functions"
| where severityLevel >= 2
| order by timestamp desc
```

## 7. パフォーマンス最適化

### 7.1 バックエンド最適化
- Cosmos DB のパーティション設計
- Azure Functions のコールドスタート対策
- データベース接続の最適化

### 7.2 フロントエンド最適化
- コンポーネントの遅延読み込み
- 画像とアセットの最適化
- API レスポンスのキャッシュ

## 8. セキュリティ考慮事項

### 8.1 認証・認可
- Azure Active Directory 統合
- JWTトークンの検証
- ロールベースアクセス制御

### 8.2 データ保護
- 機密データの暗号化
- SQL インジェクション対策
- CORS 設定

## 9. 継続的インテグレーション/デプロイメント

### 9.1 Azure DevOps パイプライン
```yaml
# azure-pipelines.yml の基本構造
trigger:
  branches:
    include:
    - main

pool:
  vmImage: 'ubuntu-latest'

stages:
- stage: Build
  jobs:
  - job: BuildBackend
    steps:
    - task: UsePythonVersion@0
      inputs:
        versionSpec: '3.9'
    - script: |
        pip install -r backend/requirements.txt
        pytest backend/tests/
    
  - job: BuildFrontend
    steps:
    - task: NodeTool@0
      inputs:
        versionSpec: '16.x'
    - script: |
        cd frontend
        npm install
        npm run build

- stage: Deploy
  dependsOn: Build
  jobs:
  - deployment: DeployToAzure
    environment: 'production'
```

## 10. 次のステップ

1. **API 設計の詳細化**: API_DESIGN.md を参照
2. **デプロイメント設定**: DEPLOYMENT_GUIDE.md を参照
3. **Power BI レポート作成**: データ可視化の実装
4. **監視・アラート設定**: 運用監視体制の構築

## 推奨リソース

- [Azure Functions Python 開発者ガイド](https://docs.microsoft.com/ja-jp/azure/azure-functions/functions-reference-python)
- [Vue.js 公式ドキュメント](https://vuejs.org/guide/)
- [Azure Cosmos DB ベストプラクティス](https://docs.microsoft.com/ja-jp/azure/cosmos-db/best-practice-guide)
- [GitHub Copilot ベストプラクティス](https://docs.github.com/ja/copilot)