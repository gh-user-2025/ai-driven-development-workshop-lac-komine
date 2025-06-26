# 工場設備管理システム - ローカル実行手順書

## 概要
このドキュメントは、工場設備管理システムのフロントエンド（Vue.js）をオフラインのローカル環境で実行するための詳細な手順を説明します。

## 前提条件

### 必要なソフトウェア
- **Node.js**: バージョン 16.0.0 以上
- **npm**: バージョン 8.0.0 以上
- **Git**: バージョン 2.20.0 以上

### 動作確認済み環境
- Windows 10/11
- macOS 10.15以上  
- Ubuntu 18.04以上

## 初期セットアップ手順

### 1. Node.jsのインストール

#### Windows
```bash
# Chocolateyを使用する場合
choco install nodejs

# または公式サイトからダウンロード
# https://nodejs.org/en/download/
```

#### macOS
```bash
# Homebrewを使用する場合
brew install node

# または公式サイトからダウンロード
# https://nodejs.org/en/download/
```

#### Ubuntu
```bash
# aptを使用する場合
sudo apt update
sudo apt install nodejs npm

# またはnvmを使用する場合（推奨）
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install node
```

### 2. インストール確認
```bash
# バージョン確認
node --version
npm --version

# 期待される出力例:
# v18.17.0
# 9.6.7
```

## アプリケーション実行手順

### 1. リポジトリのクローン
```bash
# GitHubからクローン
git clone https://github.com/gh-user-2025/ai-driven-development-workshop-lac-komine.git

# プロジェクトディレクトリに移動
cd ai-driven-development-workshop-lac-komine
```

### 2. フロントエンドディレクトリに移動
```bash
cd frontend
```

### 3. 依存関係のインストール
```bash
# npmパッケージをインストール
npm install

# インストール完了まで2-3分程度かかります
```

### 4. 開発サーバーの起動
```bash
# 開発サーバーを起動
npm run serve

# または以下のコマンドでも可能
npm run dev
```

### 5. ブラウザでアクセス
アプリケーションが正常に起動すると、以下のメッセージが表示されます：

```
App running at:
- Local:   http://localhost:8080/
- Network: http://192.168.1.100:8080/

Note that the development build is not optimized.
To create a production build, run npm run build.
```

ブラウザで **http://localhost:8080/** にアクセスしてください。

## 画面機能の確認

### ホーム画面
- URLパス: `/`
- 機能: 
  - 工場設備の統計情報表示
  - 主要機能へのナビゲーション
  - 最近の活動表示

### 設備稼働状況画面  
- URLパス: `/equipment-status`
- 機能:
  - 全設備のリアルタイム状況表示
  - フィルタリング機能（ステータス、設備タイプ、場所）
  - 設備詳細情報表示
  - センサーデータ表示（稼働中設備）

## オフライン機能

### サンプルデータ
アプリケーションには以下のサンプルデータが組み込まれています：

- **設備データ**: 8種類の工場設備
- **センサーデータ**: 温度、振動値等のリアルタイムデータ
- **統計データ**: 稼働率、効率等の集計データ

### データ更新
- データは自動でモックデータから読み込まれます
- フィルタリング機能も完全にローカルで動作します
- インターネット接続は不要です

## トラブルシューティング

### よくある問題と解決方法

#### 1. ポート8080が使用中の場合
```bash
# 別のポートで起動
npm run serve -- --port 3000

# または環境変数で指定
PORT=3000 npm run serve
```

#### 2. npmインストールでエラーが発生する場合
```bash
# キャッシュをクリア
npm cache clean --force

# node_modulesを削除して再インストール
rm -rf node_modules package-lock.json
npm install
```

#### 3. Vue CLI Serviceが見つからない場合
```bash
# @vue/cli-serviceを明示的にインストール
npm install @vue/cli-service --save-dev
```

#### 4. メモリ不足エラーの場合
```bash
# Node.jsのメモリ制限を増加
export NODE_OPTIONS="--max-old-space-size=4096"
npm run serve
```

### ログの確認
開発サーバー実行中に問題が発生した場合、コンソールに表示されるエラーメッセージを確認してください：

```bash
# 詳細なログを表示
npm run serve --verbose
```

## プロダクションビルド

本番環境用の最適化されたビルドを作成する場合：

```bash
# プロダクションビルド
npm run build

# 出力先: dist/ディレクトリ
```

ビルド後のファイルは静的Webサーバーでホスティング可能です。

## 追加設定

### 環境変数
必要に応じて`.env`ファイルを作成して環境固有の設定を行うことができます：

```bash
# .env.local ファイルを作成
VUE_APP_API_BASE_URL=http://localhost:3000/api
VUE_APP_ENVIRONMENT=local
```

### プロキシ設定
開発中にAPIサーバーと連携する場合は、`vue.config.js`でプロキシを設定できます：

```javascript
// vue.config.js
module.exports = {
  devServer: {
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true
      }
    }
  }
}
```

## サポート

### ドキュメント参照
- [Vue.js 公式ドキュメント](https://vuejs.org/guide/)
- [Vue CLI 公式ドキュメント](https://cli.vuejs.org/guide/)

### 開発者向け情報
- 使用技術: Vue.js 3.3.0, Vue Router 4.2.0
- ビルドツール: Vue CLI Service 5.0.8
- スタイリング: 純粋CSS（フレームワーク不使用）

---

**注意**: このアプリケーションは開発環境での実行を想定しています。本番環境での使用時は適切なセキュリティ設定とパフォーマンス最適化を行ってください。