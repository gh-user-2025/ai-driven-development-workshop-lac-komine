import json
import logging
import azure.functions as func
from typing import Dict, List, Optional
from ..shared.models.equipment import Equipment
from ..shared.database.sample_data import SampleDataService
from ..shared.database.cosmos_client import CosmosDbService

def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    設備稼働状況API
    GET /api/v1/equipment-status
    
    Query Parameters:
      - status: string (Active, Maintenance, Inactive)
      - equipmentType: string (Motor, Robot, Compressor, etc.)
      - location: string (部分一致検索)
      - limit: integer (取得件数制限)
    """
    logging.info('設備稼働状況API が呼び出されました')
    
    try:
        # リクエストパラメータの取得
        status = req.params.get('status')
        equipment_type = req.params.get('equipmentType')
        location = req.params.get('location')
        limit = req.params.get('limit')
        
        # パラメータのログ出力
        logging.info(f'受信パラメータ - status: {status}, equipmentType: {equipment_type}, location: {location}, limit: {limit}')
        
        # Cosmos DB サービスの初期化
        cosmos_service = CosmosDbService()
        
        # フィルタリング条件の構築
        filters = {}
        if status:
            filters['status'] = status
        if equipment_type:
            filters['equipmentType'] = equipment_type
        if location:
            filters['location'] = location
        
        # データの取得（Cosmos DB 優先、フォールバックでサンプルデータ）
        try:
            if cosmos_service.is_connected():
                logging.info('Cosmos DB からデータを取得します')
                equipment_data = await cosmos_service.get_equipment_data(filters)
            else:
                logging.info('Cosmos DB に接続できません。サンプルデータを使用します')
                raise Exception('Cosmos DB 接続なし')
        except Exception as e:
            logging.warning(f'Cosmos DB取得エラー: {str(e)}。サンプルデータを使用します')
            # フォールバック: サンプルデータサービスを使用
            data_service = SampleDataService()
            equipment_data = data_service.get_equipment_status(filters)
        
        # 件数制限の適用
        if limit:
            try:
                limit_num = int(limit)
                equipment_data = equipment_data[:limit_num]
            except ValueError:
                logging.warning(f'無効なlimitパラメータ: {limit}')
        
        # 統計情報の計算
        if cosmos_service.is_connected():
            # Cosmos DB データの場合は統計計算
            statistics = calculate_statistics(equipment_data)
        else:
            # サンプルデータの場合は既存メソッドを使用
            data_service = SampleDataService()
            statistics = data_service.get_equipment_statistics(equipment_data)
        
        # レスポンスデータの構築
        response_data = {
            "status": "success",
            "timestamp": func.datetime.utcnow().isoformat() + "Z",
            "statistics": statistics,
            "data": equipment_data,
            "count": len(equipment_data),
            "filters_applied": filters
        }
        
        logging.info(f'正常に完了 - 取得件数: {len(equipment_data)}')
        
        return func.HttpResponse(
            json.dumps(response_data, ensure_ascii=False, indent=2),
            status_code=200,
            headers={
                'Content-Type': 'application/json; charset=utf-8',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            }
        )
        
    except Exception as e:
        logging.error(f'API実行中にエラーが発生しました: {str(e)}')
        
        error_response = {
            "status": "error",
            "message": "内部サーバーエラーが発生しました",
            "timestamp": func.datetime.utcnow().isoformat() + "Z",
            "error_details": str(e) if logging.getLogger().isEnabledFor(logging.DEBUG) else None
        }
        
        return func.HttpResponse(
            json.dumps(error_response, ensure_ascii=False, indent=2),
            status_code=500,
            headers={
                'Content-Type': 'application/json; charset=utf-8',
                'Access-Control-Allow-Origin': '*'
            }
        )

def handle_options(req: func.HttpRequest) -> func.HttpResponse:
    """CORS プリフライトリクエストの処理"""
    return func.HttpResponse(
        "",
        status_code=200,
        headers={
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        }
    )

# メイン関数
def main_handler(req: func.HttpRequest) -> func.HttpResponse:
    """HTTPリクエストの処理"""
    if req.method == "OPTIONS":
        return handle_options(req)
    elif req.method == "GET":
        return main(req)
    else:
        return func.HttpResponse(
            json.dumps({"error": "Method not allowed"}, ensure_ascii=False),
            status_code=405,
            headers={'Content-Type': 'application/json; charset=utf-8'}
        )

def calculate_statistics(equipment_data: List[Dict]) -> Dict:
    """統計情報を計算（Cosmos DB データ用）"""
    if not equipment_data:
        return {
            "totalEquipment": 0,
            "activeEquipment": 0,
            "maintenanceEquipment": 0,
            "inactiveEquipment": 0,
            "averageEfficiency": 0.0,
            "totalOperatingHours": 0
        }
    
    active_equipment = [eq for eq in equipment_data if eq.get('status') == 'Active']
    maintenance_equipment = [eq for eq in equipment_data if eq.get('status') == 'Maintenance']
    inactive_equipment = [eq for eq in equipment_data if eq.get('status') == 'Inactive']
    
    # 平均効率の計算（稼働中設備のみ）
    if active_equipment:
        total_efficiency = sum(eq.get('efficiency', 0) for eq in active_equipment)
        average_efficiency = total_efficiency / len(active_equipment)
    else:
        average_efficiency = 0.0
    
    # 総稼働時間の計算
    total_operating_hours = sum(eq.get('operatingHours', 0) for eq in equipment_data)
    
    return {
        "totalEquipment": len(equipment_data),
        "activeEquipment": len(active_equipment),
        "maintenanceEquipment": len(maintenance_equipment),
        "inactiveEquipment": len(inactive_equipment),
        "averageEfficiency": round(average_efficiency, 1),
        "totalOperatingHours": total_operating_hours
    }