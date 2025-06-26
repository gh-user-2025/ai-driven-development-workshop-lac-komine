from dataclasses import dataclass
from typing import Optional, Dict, Any
from datetime import datetime

@dataclass
class Equipment:
    """設備データモデル"""
    
    equipment_id: int
    equipment_name: str
    equipment_type: str
    serial_number: str
    manufacturer: str
    model: str
    location: str
    installation_date: str
    maintenance_cycle_hours: int
    responsible_person: str
    status: str  # Active, Maintenance, Inactive
    current_temperature: Optional[float] = None
    current_vibration: Optional[float] = None
    operating_hours: Optional[int] = None
    efficiency: Optional[float] = None
    last_maintenance_date: Optional[str] = None
    next_maintenance_date: Optional[str] = None
    
    def to_dict(self) -> Dict[str, Any]:
        """辞書形式に変換"""
        return {
            "equipmentId": self.equipment_id,
            "equipmentName": self.equipment_name,
            "equipmentType": self.equipment_type,
            "serialNumber": self.serial_number,
            "manufacturer": self.manufacturer,
            "model": self.model,
            "location": self.location,
            "installationDate": self.installation_date,
            "maintenanceCycleHours": self.maintenance_cycle_hours,
            "responsiblePerson": self.responsible_person,
            "status": self.status,
            "currentTemperature": self.current_temperature,
            "currentVibration": self.current_vibration,
            "operatingHours": self.operating_hours,
            "efficiency": self.efficiency,
            "lastMaintenanceDate": self.last_maintenance_date,
            "nextMaintenanceDate": self.next_maintenance_date
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Equipment':
        """辞書からEquipmentオブジェクトを作成"""
        return cls(
            equipment_id=data.get("equipmentId", 0),
            equipment_name=data.get("equipmentName", ""),
            equipment_type=data.get("equipmentType", ""),
            serial_number=data.get("serialNumber", ""),
            manufacturer=data.get("manufacturer", ""),
            model=data.get("model", ""),
            location=data.get("location", ""),
            installation_date=data.get("installationDate", ""),
            maintenance_cycle_hours=data.get("maintenanceCycleHours", 0),
            responsible_person=data.get("responsiblePerson", ""),
            status=data.get("status", ""),
            current_temperature=data.get("currentTemperature"),
            current_vibration=data.get("currentVibration"),
            operating_hours=data.get("operatingHours"),
            efficiency=data.get("efficiency"),
            last_maintenance_date=data.get("lastMaintenanceDate"),
            next_maintenance_date=data.get("nextMaintenanceDate")
        )
    
    def is_active(self) -> bool:
        """稼働中かどうかを判定"""
        return self.status == "Active"
    
    def is_maintenance_required(self) -> bool:
        """メンテナンスが必要かどうかを判定"""
        if self.status == "Maintenance":
            return True
        
        # 稼働時間がメンテナンス周期を超えているかチェック
        if self.operating_hours and self.maintenance_cycle_hours:
            return self.operating_hours >= self.maintenance_cycle_hours
        
        return False
    
    def get_status_ja(self) -> str:
        """日本語のステータスを取得"""
        status_map = {
            "Active": "稼働中",
            "Maintenance": "メンテナンス中",
            "Inactive": "停止中"
        }
        return status_map.get(self.status, self.status)