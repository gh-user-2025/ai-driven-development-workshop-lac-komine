// 設備データサービス（API統合前の基本版）
export const equipmentService = {
  // サンプル設備データ（既存のJSONファイルから）
  sampleData: [
    {
      equipmentId: 1,
      equipmentName: "第1製造ライン主モーター",
      equipmentType: "Motor",
      serialNumber: "MOT-001-2023",
      manufacturer: "東洋電機製造",
      model: "TDK-3000",
      location: "第1工場1階A区画",
      installationDate: "2023-01-15",
      maintenanceCycleHours: 720,
      responsiblePerson: "田中太郎",
      status: "Active",
      currentTemperature: 74.2,
      currentVibration: 0.15,
      operatingHours: 1456,
      efficiency: 95.2
    },
    {
      equipmentId: 2,
      equipmentName: "第2製造ライン組立ロボット",
      equipmentType: "Robot",
      serialNumber: "ROB-002-2023",
      manufacturer: "三菱電機",
      model: "RV-20F",
      location: "第1工場1階B区画",
      installationDate: "2023-02-20",
      maintenanceCycleHours: 1440,
      responsiblePerson: "佐藤花子",
      status: "Active",
      currentTemperature: 45.8,
      currentVibration: 0.08,
      operatingHours: 2134,
      efficiency: 98.1
    },
    {
      equipmentId: 3,
      equipmentName: "空圧コンプレッサー1号機",
      equipmentType: "Compressor",
      serialNumber: "COM-003-2023",
      manufacturer: "日立産機システム",
      model: "OSP-37.5B",
      location: "第1工場地下1階機械室",
      installationDate: "2023-03-10",
      maintenanceCycleHours: 2160,
      responsiblePerson: "鈴木一郎",
      status: "Active",
      currentTemperature: 68.5,
      currentVibration: 0.12,
      operatingHours: 1789,
      efficiency: 92.7
    },
    {
      equipmentId: 4,
      equipmentName: "品質検査装置",
      equipmentType: "Inspection",
      serialNumber: "INS-004-2023",
      manufacturer: "キーエンス",
      model: "IV-X3000",
      location: "第1工場2階品質管理室",
      installationDate: "2023-04-05",
      maintenanceCycleHours: 8760,
      responsiblePerson: "高橋美咲",
      status: "Active",
      currentTemperature: 23.1,
      currentVibration: 0.02,
      operatingHours: 987,
      efficiency: 99.5
    },
    {
      equipmentId: 5,
      equipmentName: "包装機械ライン",
      equipmentType: "Packaging",
      serialNumber: "PKG-005-2023",
      manufacturer: "東洋自動機",
      model: "TJP-500",
      location: "第1工場1階C区画",
      installationDate: "2023-05-12",
      maintenanceCycleHours: 1080,
      responsiblePerson: "山田次郎",
      status: "Active",
      currentTemperature: 35.4,
      currentVibration: 0.06,
      operatingHours: 1234,
      efficiency: 96.8
    },
    {
      equipmentId: 6,
      equipmentName: "プレス機1号機",
      equipmentType: "Press",
      serialNumber: "PRS-006-2022",
      manufacturer: "アマダ",
      model: "HFP-1703",
      location: "第2工場1階A区画",
      installationDate: "2022-11-15",
      maintenanceCycleHours: 480,
      responsiblePerson: "渡辺恵子",
      status: "Maintenance",
      currentTemperature: 0,
      currentVibration: 0,
      operatingHours: 3456,
      efficiency: 0
    },
    {
      equipmentId: 7,
      equipmentName: "切削加工機CNC",
      equipmentType: "CNC",
      serialNumber: "CNC-007-2023",
      manufacturer: "DMG森精機",
      model: "NHX-5500",
      location: "第2工場1階B区画",
      installationDate: "2023-06-20",
      maintenanceCycleHours: 720,
      responsiblePerson: "伊藤誠",
      status: "Active",
      currentTemperature: 58.7,
      currentVibration: 0.18,
      operatingHours: 876,
      efficiency: 94.3
    },
    {
      equipmentId: 8,
      equipmentName: "搬送ベルトコンベア",
      equipmentType: "Conveyor",
      serialNumber: "CNV-008-2023",
      manufacturer: "椿本チエイン",
      model: "TCC-3000",
      location: "第1工場1階全域",
      installationDate: "2023-07-01",
      maintenanceCycleHours: 4320,
      responsiblePerson: "加藤健一",
      status: "Active",
      currentTemperature: 28.3,
      currentVibration: 0.04,
      operatingHours: 654,
      efficiency: 97.2
    }
  ],

  // 全設備データを取得
  async getAll() {
    // APIコール（現在はサンプルデータを返す）
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve(this.sampleData)
      }, 500)
    })
  },

  // フィルタリング機能
  async getFiltered(filters = {}) {
    return new Promise((resolve) => {
      setTimeout(() => {
        let filteredData = [...this.sampleData]
        
        if (filters.status) {
          filteredData = filteredData.filter(eq => eq.status === filters.status)
        }
        
        if (filters.equipmentType) {
          filteredData = filteredData.filter(eq => eq.equipmentType === filters.equipmentType)
        }
        
        if (filters.location) {
          filteredData = filteredData.filter(eq => 
            eq.location.toLowerCase().includes(filters.location.toLowerCase())
          )
        }
        
        resolve(filteredData)
      }, 500)
    })
  },

  // 設備統計データを取得
  async getStatistics() {
    return new Promise((resolve) => {
      setTimeout(() => {
        const activeEquipment = this.sampleData.filter(eq => eq.status === 'Active')
        const maintenanceEquipment = this.sampleData.filter(eq => eq.status === 'Maintenance')
        
        const stats = {
          totalEquipment: this.sampleData.length,
          activeEquipment: activeEquipment.length,
          maintenanceEquipment: maintenanceEquipment.length,
          averageEfficiency: activeEquipment.reduce((sum, eq) => sum + eq.efficiency, 0) / activeEquipment.length,
          totalOperatingHours: this.sampleData.reduce((sum, eq) => sum + eq.operatingHours, 0)
        }
        
        resolve(stats)
      }, 300)
    })
  },

  // 設備タイプ一覧を取得
  getEquipmentTypes() {
    return [...new Set(this.sampleData.map(eq => eq.equipmentType))]
  },

  // ステータス一覧を取得
  getStatuses() {
    return ['Active', 'Maintenance', 'Inactive']
  }
}