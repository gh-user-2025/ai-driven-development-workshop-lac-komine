// API クライアントサービス
import axios from 'axios'

class ApiService {
  constructor() {
    // Azure Functions のURL（開発時はローカル、本番時は実際のURL）
    this.baseURL = process.env.VUE_APP_API_URL || 'http://localhost:7071/api'
    
    // Axiosインスタンスの作成
    this.api = axios.create({
      baseURL: this.baseURL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json'
      }
    })
    
    // リクエストインターセプター
    this.api.interceptors.request.use(
      config => {
        console.log(`API Request: ${config.method?.toUpperCase()} ${config.url}`)
        return config
      },
      error => {
        console.error('API Request Error:', error)
        return Promise.reject(error)
      }
    )
    
    // レスポンスインターセプター
    this.api.interceptors.response.use(
      response => {
        console.log(`API Response: ${response.status} ${response.config.url}`)
        return response
      },
      error => {
        console.error('API Response Error:', error.response?.data || error.message)
        return Promise.reject(error)
      }
    )
  }
  
  // 設備稼働状況データを取得
  async getEquipmentStatus(filters = {}) {
    try {
      const params = new URLSearchParams()
      
      // フィルターパラメータの設定
      if (filters.status) params.append('status', filters.status)
      if (filters.equipmentType) params.append('equipmentType', filters.equipmentType)
      if (filters.location) params.append('location', filters.location)
      if (filters.limit) params.append('limit', filters.limit.toString())
      
      const response = await this.api.get(`/v1/equipment-status?${params.toString()}`)
      return response.data
    } catch (error) {
      console.error('設備稼働状況の取得に失敗しました:', error)
      throw error
    }
  }
  
  // 健全性チェック
  async healthCheck() {
    try {
      const response = await this.api.get('/health')
      return response.data
    } catch (error) {
      console.error('ヘルスチェックに失敗しました:', error)
      throw error
    }
  }
}

// シングルトンインスタンス
export const apiService = new ApiService()

// 設備データサービス（API統合版）
export const equipmentServiceWithApi = {
  // APIから設備データを取得（フォールバック付き）
  async getAll() {
    try {
      // まずAPIを試行
      const response = await apiService.getEquipmentStatus()
      return response.data || []
    } catch (error) {
      console.warn('API呼び出しに失敗しました。サンプルデータを使用します:', error.message)
      
      // フォールバック: ローカルサンプルデータを使用
      const { equipmentService } = await import('./equipmentService.js')
      return equipmentService.getAll()
    }
  },
  
  // フィルタリング機能（API統合版）
  async getFiltered(filters = {}) {
    try {
      // まずAPIを試行
      const response = await apiService.getEquipmentStatus(filters)
      return response.data || []
    } catch (error) {
      console.warn('API呼び出しに失敗しました。ローカルフィルタリングを使用します:', error.message)
      
      // フォールバック: ローカルデータでフィルタリング
      const { equipmentService } = await import('./equipmentService.js')
      return equipmentService.getFiltered(filters)
    }
  },
  
  // 統計データを取得（API統合版）
  async getStatistics() {
    try {
      // APIから統計データを取得
      const response = await apiService.getEquipmentStatus()
      return response.statistics || {}
    } catch (error) {
      console.warn('API呼び出しに失敗しました。ローカル統計を使用します:', error.message)
      
      // フォールバック: ローカル計算
      const { equipmentService } = await import('./equipmentService.js')
      return equipmentService.getStatistics()
    }
  },
  
  // 設備タイプ一覧（ローカル）
  getEquipmentTypes() {
    return ['Motor', 'Robot', 'Compressor', 'Inspection', 'Packaging', 'Press', 'CNC', 'Conveyor', 'Cooling', 'Electrical']
  },
  
  // ステータス一覧（ローカル）
  getStatuses() {
    return ['Active', 'Maintenance', 'Inactive']
  },
  
  // 接続テスト
  async testConnection() {
    try {
      await apiService.healthCheck()
      return { connected: true, message: 'APIサーバーとの接続が確認できました' }
    } catch (error) {
      return { connected: false, message: `API接続エラー: ${error.message}` }
    }
  }
}