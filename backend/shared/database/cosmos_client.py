import os
import logging
from azure.cosmos import CosmosClient, PartitionKey
from azure.cosmos.exceptions import CosmosResourceNotFoundError, CosmosHttpResponseError
from typing import List, Dict, Any, Optional

class CosmosDbService:
    """Azure Cosmos DB サービスクラス"""
    
    def __init__(self):
        """Azure Cosmos DB クライアントの初期化"""
        # 環境変数から接続情報を取得
        self.endpoint = os.environ.get('COSMOS_DB_ENDPOINT', '')
        self.key = os.environ.get('COSMOS_DB_KEY', '')
        self.database_name = os.environ.get('COSMOS_DB_DATABASE', 'FactoryIoTData')
        self.container_name = os.environ.get('COSMOS_DB_CONTAINER', 'Equipment')
        
        self.client = None
        self.database = None
        self.container = None
        
        # 接続情報が設定されている場合のみ初期化
        if self.endpoint and self.key:
            self._initialize_client()
        else:
            logging.warning('Cosmos DB の接続情報が設定されていません。サンプルデータモードで動作します。')
    
    def _initialize_client(self):
        """Cosmos DB クライアントの初期化"""
        try:
            self.client = CosmosClient(self.endpoint, self.key)
            self.database = self.client.get_database_client(self.database_name)
            self.container = self.database.get_container_client(self.container_name)
            logging.info(f'Cosmos DB に正常に接続しました: {self.database_name}/{self.container_name}')
        except Exception as e:
            logging.error(f'Cosmos DB の初期化に失敗しました: {str(e)}')
            self.client = None
    
    def is_connected(self) -> bool:
        """Cosmos DB への接続状態を確認"""
        return self.client is not None and self.container is not None
    
    async def get_equipment_data(self, filters: Optional[Dict[str, str]] = None) -> List[Dict[str, Any]]:
        """
        Cosmos DB から設備データを取得
        
        Args:
            filters: フィルタリング条件
        
        Returns:
            設備データのリスト
        """
        if not self.is_connected():
            raise Exception('Cosmos DB への接続が確立されていません')
        
        try:
            # SQLクエリの構築
            query = "SELECT * FROM c WHERE c.documentType = 'equipment'"
            parameters = []
            
            # フィルター条件の追加
            if filters:
                if filters.get('status'):
                    query += " AND c.status = @status"
                    parameters.append({"name": "@status", "value": filters['status']})
                
                if filters.get('equipmentType'):
                    query += " AND c.equipmentType = @equipmentType"
                    parameters.append({"name": "@equipmentType", "value": filters['equipmentType']})
                
                if filters.get('location'):
                    query += " AND CONTAINS(LOWER(c.location), LOWER(@location))"
                    parameters.append({"name": "@location", "value": filters['location']})
            
            # 並び順の指定
            query += " ORDER BY c.equipmentId"
            
            logging.info(f'実行クエリ: {query}')
            logging.info(f'パラメータ: {parameters}')
            
            # クエリの実行
            items = list(self.container.query_items(
                query=query,
                parameters=parameters,
                enable_cross_partition_query=True
            ))
            
            logging.info(f'Cosmos DB から {len(items)} 件の設備データを取得しました')
            return items
            
        except CosmosHttpResponseError as e:
            logging.error(f'Cosmos DB クエリエラー: {e.message}')
            raise Exception(f'データベースクエリに失敗しました: {e.message}')
        except Exception as e:
            logging.error(f'設備データ取得エラー: {str(e)}')
            raise Exception(f'設備データの取得に失敗しました: {str(e)}')
    
    async def get_maintenance_equipment(self) -> List[Dict[str, Any]]:
        """
        メンテナンス中の設備を取得（サンプルクエリ）
        
        Returns:
            メンテナンス中の設備データのリスト
        """
        if not self.is_connected():
            raise Exception('Cosmos DB への接続が確立されていません')
        
        try:
            # メンテナンス中の設備を検索するクエリ
            query = """
            SELECT 
                c.equipmentId,
                c.equipmentName,
                c.equipmentType,
                c.location,
                c.status,
                c.responsiblePerson,
                c.lastMaintenanceDate,
                c.nextMaintenanceDate
            FROM c 
            WHERE c.documentType = 'equipment' 
            AND c.status = 'Maintenance'
            ORDER BY c.equipmentName
            """
            
            items = list(self.container.query_items(
                query=query,
                enable_cross_partition_query=True
            ))
            
            logging.info(f'メンテナンス中の設備: {len(items)} 件')
            return items
            
        except Exception as e:
            logging.error(f'メンテナンス設備取得エラー: {str(e)}')
            raise Exception(f'メンテナンス設備の取得に失敗しました: {str(e)}')
    
    async def create_equipment(self, equipment_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        新しい設備データを作成
        
        Args:
            equipment_data: 設備データ
        
        Returns:
            作成された設備データ
        """
        if not self.is_connected():
            raise Exception('Cosmos DB への接続が確立されていません')
        
        try:
            # ドキュメントタイプの設定
            equipment_data['documentType'] = 'equipment'
            equipment_data['id'] = f"equipment_{equipment_data.get('equipmentId', 'unknown')}"
            
            # パーティションキーの設定
            equipment_data['partitionKey'] = equipment_data.get('equipmentType', 'unknown')
            
            # Cosmos DB に挿入
            created_item = self.container.create_item(body=equipment_data)
            logging.info(f'設備データを作成しました: ID={created_item["id"]}')
            
            return created_item
            
        except Exception as e:
            logging.error(f'設備作成エラー: {str(e)}')
            raise Exception(f'設備データの作成に失敗しました: {str(e)}')
    
    async def update_equipment_status(self, equipment_id: int, new_status: str) -> Dict[str, Any]:
        """
        設備のステータスを更新
        
        Args:
            equipment_id: 設備ID
            new_status: 新しいステータス
        
        Returns:
            更新された設備データ
        """
        if not self.is_connected():
            raise Exception('Cosmos DB への接続が確立されていません')
        
        try:
            # 既存データの取得
            item_id = f"equipment_{equipment_id}"
            
            # パーティションキーを取得するために先にアイテムを検索
            query = f"SELECT * FROM c WHERE c.id = '{item_id}'"
            items = list(self.container.query_items(
                query=query,
                enable_cross_partition_query=True
            ))
            
            if not items:
                raise Exception(f'設備ID {equipment_id} が見つかりません')
            
            item = items[0]
            partition_key = item.get('partitionKey', item.get('equipmentType', 'unknown'))
            
            # ステータスの更新
            item['status'] = new_status
            item['lastUpdated'] = func.datetime.utcnow().isoformat() + "Z"
            
            # 更新の実行
            updated_item = self.container.upsert_item(body=item)
            logging.info(f'設備ステータスを更新しました: ID={equipment_id}, Status={new_status}')
            
            return updated_item
            
        except Exception as e:
            logging.error(f'ステータス更新エラー: {str(e)}')
            raise Exception(f'設備ステータスの更新に失敗しました: {str(e)}')
    
    def get_sample_queries(self) -> Dict[str, str]:
        """
        よく使用されるクエリのサンプルを取得
        
        Returns:
            クエリサンプルの辞書
        """
        return {
            "メンテナンス中の設備": """
                SELECT c.equipmentId, c.equipmentName, c.equipmentType, c.location, c.responsiblePerson
                FROM c 
                WHERE c.documentType = 'equipment' AND c.status = 'Maintenance'
                ORDER BY c.equipmentName
            """,
            
            "高効率設備（95%以上）": """
                SELECT c.equipmentId, c.equipmentName, c.efficiency
                FROM c 
                WHERE c.documentType = 'equipment' 
                AND c.status = 'Active' 
                AND c.efficiency >= 95
                ORDER BY c.efficiency DESC
            """,
            
            "設備タイプ別集計": """
                SELECT c.equipmentType, COUNT(1) as count, AVG(c.efficiency) as avgEfficiency
                FROM c 
                WHERE c.documentType = 'equipment' AND c.status = 'Active'
                GROUP BY c.equipmentType
                ORDER BY count DESC
            """,
            
            "メンテナンス予定設備": """
                SELECT c.equipmentId, c.equipmentName, c.nextMaintenanceDate
                FROM c 
                WHERE c.documentType = 'equipment' 
                AND c.nextMaintenanceDate >= GETCURRENTDATETIME()
                AND c.nextMaintenanceDate <= DATEADD('day', 7, GETCURRENTDATETIME())
                ORDER BY c.nextMaintenanceDate
            """
        }