from typing import List, Dict, Any, Optional
import json
import logging
from ..models.equipment import Equipment

class SampleDataService:
    """サンプルデータを提供するサービスクラス"""
    
    def __init__(self):
        """サンプルデータの初期化"""
        self.sample_equipment_data = [
            {
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
                "nextMaintenanceDate": "2024-04-15"
            },
            {
                "equipmentId": 2,
                "equipmentName": "第2製造ライン組立ロボット",
                "equipmentType": "Robot",
                "serialNumber": "ROB-002-2023",
                "manufacturer": "三菱電機",
                "model": "RV-20F",
                "location": "第1工場1階B区画",
                "installationDate": "2023-02-20",
                "maintenanceCycleHours": 1440,
                "responsiblePerson": "佐藤花子",
                "status": "Active",
                "currentTemperature": 45.8,
                "currentVibration": 0.08,
                "operatingHours": 2134,
                "efficiency": 98.1,
                "lastMaintenanceDate": "2024-02-01",
                "nextMaintenanceDate": "2024-05-01"
            },
            {
                "equipmentId": 3,
                "equipmentName": "空圧コンプレッサー1号機",
                "equipmentType": "Compressor",
                "serialNumber": "COM-003-2023",
                "manufacturer": "日立産機システム",
                "model": "OSP-37.5B",
                "location": "第1工場地下1階機械室",
                "installationDate": "2023-03-10",
                "maintenanceCycleHours": 2160,
                "responsiblePerson": "鈴木一郎",
                "status": "Active",
                "currentTemperature": 68.5,
                "currentVibration": 0.12,
                "operatingHours": 1789,
                "efficiency": 92.7,
                "lastMaintenanceDate": "2024-01-25",
                "nextMaintenanceDate": "2024-07-25"
            },
            {
                "equipmentId": 4,
                "equipmentName": "品質検査装置",
                "equipmentType": "Inspection",
                "serialNumber": "INS-004-2023",
                "manufacturer": "キーエンス",
                "model": "IV-X3000",
                "location": "第1工場2階品質管理室",
                "installationDate": "2023-04-05",
                "maintenanceCycleHours": 8760,
                "responsiblePerson": "高橋美咲",
                "status": "Active",
                "currentTemperature": 23.1,
                "currentVibration": 0.02,
                "operatingHours": 987,
                "efficiency": 99.5,
                "lastMaintenanceDate": "2024-04-01",
                "nextMaintenanceDate": "2025-04-01"
            },
            {
                "equipmentId": 5,
                "equipmentName": "包装機械ライン",
                "equipmentType": "Packaging",
                "serialNumber": "PKG-005-2023",
                "manufacturer": "東洋自動機",
                "model": "TJP-500",
                "location": "第1工場1階C区画",
                "installationDate": "2023-05-12",
                "maintenanceCycleHours": 1080,
                "responsiblePerson": "山田次郎",
                "status": "Active",
                "currentTemperature": 35.4,
                "currentVibration": 0.06,
                "operatingHours": 1234,
                "efficiency": 96.8,
                "lastMaintenanceDate": "2024-05-01",
                "nextMaintenanceDate": "2024-07-01"
            },
            {
                "equipmentId": 6,
                "equipmentName": "プレス機1号機",
                "equipmentType": "Press",
                "serialNumber": "PRS-006-2022",
                "manufacturer": "アマダ",
                "model": "HFP-1703",
                "location": "第2工場1階A区画",
                "installationDate": "2022-11-15",
                "maintenanceCycleHours": 480,
                "responsiblePerson": "渡辺恵子",
                "status": "Maintenance",
                "currentTemperature": 0,
                "currentVibration": 0,
                "operatingHours": 3456,
                "efficiency": 0,
                "lastMaintenanceDate": "2024-06-25",
                "nextMaintenanceDate": "2024-06-26"
            },
            {
                "equipmentId": 7,
                "equipmentName": "切削加工機CNC",
                "equipmentType": "CNC",
                "serialNumber": "CNC-007-2023",
                "manufacturer": "DMG森精機",
                "model": "NHX-5500",
                "location": "第2工場1階B区画",
                "installationDate": "2023-06-20",
                "maintenanceCycleHours": 720,
                "responsiblePerson": "伊藤誠",
                "status": "Active",
                "currentTemperature": 58.7,
                "currentVibration": 0.18,
                "operatingHours": 876,
                "efficiency": 94.3,
                "lastMaintenanceDate": "2024-06-15",
                "nextMaintenanceDate": "2024-09-15"
            },
            {
                "equipmentId": 8,
                "equipmentName": "搬送ベルトコンベア",
                "equipmentType": "Conveyor",
                "serialNumber": "CNV-008-2023",
                "manufacturer": "椿本チエイン",
                "model": "TCC-3000",
                "location": "第1工場1階全域",
                "installationDate": "2023-07-01",
                "maintenanceCycleHours": 4320,
                "responsiblePerson": "加藤健一",
                "status": "Active",
                "currentTemperature": 28.3,
                "currentVibration": 0.04,
                "operatingHours": 654,
                "efficiency": 97.2,
                "lastMaintenanceDate": "2024-07-01",
                "nextMaintenanceDate": "2024-12-01"
            }
        ]
        
        logging.info(f'サンプルデータを初期化しました - 設備数: {len(self.sample_equipment_data)}')
    
    def get_equipment_status(self, filters: Optional[Dict[str, str]] = None) -> List[Dict[str, Any]]:
        """
        設備稼働状況データを取得（フィルタリング機能付き）
        
        Args:
            filters: フィルタリング条件
                - status: ステータスでフィルタ
                - equipmentType: 設備タイプでフィルタ
                - location: 場所でフィルタ（部分一致）
        
        Returns:
            フィルタリングされた設備データのリスト
        """
        filtered_data = self.sample_equipment_data.copy()
        
        if filters:
            # ステータスフィルタ
            if filters.get('status'):
                filtered_data = [eq for eq in filtered_data if eq['status'] == filters['status']]
                logging.info(f'ステータスフィルタ適用: {filters["status"]} - 結果件数: {len(filtered_data)}')
            
            # 設備タイプフィルタ
            if filters.get('equipmentType'):
                filtered_data = [eq for eq in filtered_data if eq['equipmentType'] == filters['equipmentType']]
                logging.info(f'設備タイプフィルタ適用: {filters["equipmentType"]} - 結果件数: {len(filtered_data)}')
            
            # 場所フィルタ（部分一致）
            if filters.get('location'):
                location_filter = filters['location'].lower()
                filtered_data = [eq for eq in filtered_data 
                               if location_filter in eq['location'].lower()]
                logging.info(f'場所フィルタ適用: {filters["location"]} - 結果件数: {len(filtered_data)}')
        
        return filtered_data
    
    def get_equipment_statistics(self, equipment_data: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        設備統計情報を計算
        
        Args:
            equipment_data: 設備データのリスト
        
        Returns:
            統計情報の辞書
        """
        if not equipment_data:
            return {
                "totalEquipment": 0,
                "activeEquipment": 0,
                "maintenanceEquipment": 0,
                "inactiveEquipment": 0,
                "averageEfficiency": 0.0,
                "totalOperatingHours": 0
            }
        
        active_equipment = [eq for eq in equipment_data if eq['status'] == 'Active']
        maintenance_equipment = [eq for eq in equipment_data if eq['status'] == 'Maintenance']
        inactive_equipment = [eq for eq in equipment_data if eq['status'] == 'Inactive']
        
        # 平均効率の計算（稼働中設備のみ）
        if active_equipment:
            total_efficiency = sum(eq.get('efficiency', 0) for eq in active_equipment)
            average_efficiency = total_efficiency / len(active_equipment)
        else:
            average_efficiency = 0.0
        
        # 総稼働時間の計算
        total_operating_hours = sum(eq.get('operatingHours', 0) for eq in equipment_data)
        
        statistics = {
            "totalEquipment": len(equipment_data),
            "activeEquipment": len(active_equipment),
            "maintenanceEquipment": len(maintenance_equipment),
            "inactiveEquipment": len(inactive_equipment),
            "averageEfficiency": round(average_efficiency, 1),
            "totalOperatingHours": total_operating_hours
        }
        
        logging.info(f'統計情報を計算しました: {statistics}')
        return statistics
    
    def get_equipment_types(self) -> List[str]:
        """設備タイプ一覧を取得"""
        types = list(set(eq['equipmentType'] for eq in self.sample_equipment_data))
        return sorted(types)
    
    def get_locations(self) -> List[str]:
        """設置場所一覧を取得"""
        locations = list(set(eq['location'] for eq in self.sample_equipment_data))
        return sorted(locations)