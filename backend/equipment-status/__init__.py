import json
import logging
import azure.functions as func
from typing import Dict, List, Optional
from ..shared.models.equipment import Equipment
from ..shared.database.sample_data import SampleDataService

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
        
        # サンプルデータサービスの初期化
        data_service = SampleDataService()
        
        # フィルタリング条件の構築
        filters = {}
        if status:
            filters['status'] = status
        if equipment_type:
            filters['equipmentType'] = equipment_type
        if location:
            filters['location'] = location
            
        # データの取得とフィルタリング
        equipment_data = data_service.get_equipment_status(filters)
        
        # 件数制限の適用
        if limit:
            try:
                limit_num = int(limit)
                equipment_data = equipment_data[:limit_num]
            except ValueError:
                logging.warning(f'無効なlimitパラメータ: {limit}')
        
        # 統計情報の計算
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