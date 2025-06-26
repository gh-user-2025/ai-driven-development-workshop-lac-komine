<template>
  <div class="equipment-status-page">
    <!-- ページヘッダー -->
    <div class="page-header">
      <h1>🏭 設備稼働状況</h1>
      <p>工場内全設備のリアルタイム稼働状況を監視</p>
      <div class="api-status" :class="{ 'api-active': apiMode, 'api-offline': !apiMode }">
        <span v-if="apiMode">🌐 API連携モード</span>
        <span v-else>💾 オフラインモード</span>
      </div>
    </div>

    <!-- フィルター・検索セクション -->
    <div class="filter-section">
      <div class="filter-controls">
        <div class="filter-group">
          <label for="status-filter">ステータス:</label>
          <select 
            id="status-filter" 
            v-model="filters.status" 
            @change="applyFilters"
            class="filter-select"
          >
            <option value="">全て</option>
            <option value="Active">稼働中</option>
            <option value="Maintenance">メンテナンス中</option>
            <option value="Inactive">停止中</option>
          </select>
        </div>
        
        <div class="filter-group">
          <label for="type-filter">設備タイプ:</label>
          <select 
            id="type-filter" 
            v-model="filters.equipmentType" 
            @change="applyFilters"
            class="filter-select"
          >
            <option value="">全て</option>
            <option v-for="type in equipmentTypes" :key="type" :value="type">
              {{ type }}
            </option>
          </select>
        </div>
        
        <div class="filter-group">
          <label for="location-filter">場所:</label>
          <input 
            id="location-filter"
            type="text" 
            v-model="filters.location" 
            @input="applyFilters"
            placeholder="場所で検索..."
            class="filter-input"
          >
        </div>
        
        <button @click="clearFilters" class="btn btn-secondary">
          フィルターをクリア
        </button>
      </div>
    </div>

    <!-- ローディング表示 -->
    <div v-if="loading" class="loading-section">
      <div class="loading-spinner">🔄</div>
      <p>設備データを読み込み中...</p>
    </div>

    <!-- 設備一覧表示 -->
    <div v-else class="equipment-grid">
      <div 
        v-for="equipment in filteredEquipments" 
        :key="equipment.equipmentId"
        class="equipment-card"
        :class="getCardClass(equipment.status)"
      >
        <!-- カードヘッダー -->
        <div class="card-header">
          <div class="equipment-info">
            <h3>{{ equipment.equipmentName }}</h3>
            <p class="equipment-type">{{ equipment.equipmentType }}</p>
          </div>
          <div class="status-badge" :class="getStatusClass(equipment.status)">
            {{ getStatusText(equipment.status) }}
          </div>
        </div>

        <!-- 設備詳細情報 -->
        <div class="card-content">
          <div class="info-grid">
            <div class="info-item">
              <span class="info-label">場所:</span>
              <span class="info-value">{{ equipment.location }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">責任者:</span>
              <span class="info-value">{{ equipment.responsiblePerson }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">稼働時間:</span>
              <span class="info-value">{{ equipment.operatingHours }}h</span>
            </div>
            <div class="info-item">
              <span class="info-label">効率:</span>
              <span class="info-value efficiency-value">{{ equipment.efficiency }}%</span>
            </div>
          </div>

          <!-- センサーデータ（稼働中の場合のみ表示） -->
          <div v-if="equipment.status === 'Active'" class="sensor-data">
            <h4>リアルタイムデータ</h4>
            <div class="sensor-grid">
              <div class="sensor-item">
                <span class="sensor-icon">🌡️</span>
                <div class="sensor-info">
                  <span class="sensor-label">温度</span>
                  <span class="sensor-value">{{ equipment.currentTemperature }}°C</span>
                </div>
              </div>
              <div class="sensor-item">
                <span class="sensor-icon">📳</span>
                <div class="sensor-info">
                  <span class="sensor-label">振動</span>
                  <span class="sensor-value">{{ equipment.currentVibration }}mm/s</span>
                </div>
              </div>
            </div>
          </div>

          <!-- メンテナンス情報（メンテナンス中の場合） -->
          <div v-if="equipment.status === 'Maintenance'" class="maintenance-info">
            <h4>メンテナンス情報</h4>
            <p>🔧 定期メンテナンス実施中</p>
            <p>予定完了: 本日 17:00</p>
          </div>
        </div>

        <!-- カードフッター -->
        <div class="card-footer">
          <button class="btn btn-outline" @click="viewDetails(equipment)">
            詳細を見る
          </button>
          <button 
            v-if="equipment.status === 'Active'" 
            class="btn btn-warning" 
            @click="scheduleMaintenane(equipment)"
          >
            メンテナンス予約
          </button>
        </div>
      </div>
    </div>

    <!-- データが見つからない場合 -->
    <div v-if="!loading && filteredEquipments.length === 0" class="no-data">
      <div class="no-data-icon">📭</div>
      <h3>該当する設備が見つかりません</h3>
      <p>フィルター条件を変更して再度お試しください。</p>
    </div>
  </div>
</template>

<script>
import { equipmentServiceWithApi } from '../services/apiService.js'

export default {
  name: 'EquipmentStatus',
  data() {
    return {
      equipments: [],
      filteredEquipments: [],
      equipmentTypes: [],
      filters: {
        status: '',
        equipmentType: '',
        location: ''
      },
      loading: true,
      apiMode: false
    }
  },
  async mounted() {
    await this.loadData()
  },
  methods: {
    async loadData() {
      try {
        this.loading = true
        
        // API統合サービスを使用（自動的にフォールバック）
        this.equipments = await equipmentServiceWithApi.getAll()
        this.filteredEquipments = [...this.equipments]
        this.equipmentTypes = equipmentServiceWithApi.getEquipmentTypes()
        
        // API接続確認
        const connectionTest = await equipmentServiceWithApi.testConnection()
        this.apiMode = connectionTest.connected
        
      } catch (error) {
        console.error('設備データの読み込みに失敗しました:', error)
      } finally {
        this.loading = false
      }
    },

    async applyFilters() {
      try {
        this.loading = true
        
        // API統合サービスを使用
        this.filteredEquipments = await equipmentServiceWithApi.getFiltered(this.filters)
        
      } catch (error) {
        console.error('フィルタリング処理に失敗しました:', error)
      } finally {
        this.loading = false
      }
    },

    clearFilters() {
      this.filters = {
        status: '',
        equipmentType: '',
        location: ''
      }
      this.filteredEquipments = [...this.equipments]
    },

    getCardClass(status) {
      return {
        'card-active': status === 'Active',
        'card-maintenance': status === 'Maintenance',
        'card-inactive': status === 'Inactive'
      }
    },

    getStatusClass(status) {
      return {
        'status-active': status === 'Active',
        'status-maintenance': status === 'Maintenance',
        'status-inactive': status === 'Inactive'
      }
    },

    getStatusText(status) {
      const statusMap = {
        'Active': '稼働中',
        'Maintenance': 'メンテナンス中',
        'Inactive': '停止中'
      }
      return statusMap[status] || status
    },

    viewDetails(equipment) {
      alert(`${equipment.equipmentName}の詳細画面を表示します。\n\nシリアル番号: ${equipment.serialNumber}\nメーカー: ${equipment.manufacturer}\nモデル: ${equipment.model}`)
    },

    scheduleMaintenane(equipment) {
      alert(`${equipment.equipmentName}のメンテナンス予約画面を表示します。`)
    }
  }
}
</script>

<style scoped>
.equipment-status-page {
  min-height: calc(100vh - 200px);
}

/* ページヘッダー */
.page-header {
  text-align: center;
  margin-bottom: 2rem;
}

.page-header h1 {
  color: #2c3e50;
  font-size: 2.2rem;
  margin-bottom: 0.5rem;
}

.page-header p {
  color: #6c757d;
  font-size: 1.1rem;
  margin-bottom: 1rem;
}

.api-status {
  display: inline-block;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-size: 0.9rem;
  font-weight: bold;
}

.api-status.api-active {
  background-color: #d4edda;
  color: #155724;
  border: 1px solid #c3e6cb;
}

.api-status.api-offline {
  background-color: #fff3cd;
  color: #856404;
  border: 1px solid #ffeaa7;
}

/* フィルターセクション */
.filter-section {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  margin-bottom: 2rem;
}

.filter-controls {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  align-items: end;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.filter-group label {
  font-weight: bold;
  color: #2c3e50;
}

.filter-select,
.filter-input {
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  min-width: 150px;
}

.filter-select:focus,
.filter-input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 2px rgba(102, 126, 234, 0.2);
}

/* ボタンスタイル */
.btn {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: bold;
  transition: all 0.3s;
  text-decoration: none;
  display: inline-block;
  text-align: center;
}

.btn-secondary {
  background-color: #6c757d;
  color: white;
}

.btn-secondary:hover {
  background-color: #5a6268;
}

.btn-outline {
  background-color: transparent;
  color: #667eea;
  border: 1px solid #667eea;
}

.btn-outline:hover {
  background-color: #667eea;
  color: white;
}

.btn-warning {
  background-color: #ffc107;
  color: #212529;
}

.btn-warning:hover {
  background-color: #e0a800;
}

/* ローディング */
.loading-section {
  text-align: center;
  padding: 3rem;
}

.loading-spinner {
  font-size: 2rem;
  animation: spin 1s linear infinite;
  margin-bottom: 1rem;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

/* 設備グリッド */
.equipment-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
  gap: 1.5rem;
}

/* 設備カード */
.equipment-card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  overflow: hidden;
  transition: transform 0.3s, box-shadow 0.3s;
}

.equipment-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
}

.equipment-card.card-active {
  border-left: 4px solid #28a745;
}

.equipment-card.card-maintenance {
  border-left: 4px solid #ffc107;
}

.equipment-card.card-inactive {
  border-left: 4px solid #dc3545;
}

/* カードヘッダー */
.card-header {
  padding: 1.5rem;
  display: flex;
  justify-content: space-between;
  align-items: start;
  background-color: #f8f9fa;
}

.equipment-info h3 {
  color: #2c3e50;
  margin-bottom: 0.3rem;
  font-size: 1.1rem;
}

.equipment-type {
  color: #6c757d;
  margin: 0;
  font-size: 0.9rem;
}

.status-badge {
  padding: 0.4rem 0.8rem;
  border-radius: 20px;
  font-size: 0.8rem;
  font-weight: bold;
}

.status-badge.status-active {
  background-color: #d4edda;
  color: #155724;
}

.status-badge.status-maintenance {
  background-color: #fff3cd;
  color: #856404;
}

.status-badge.status-inactive {
  background-color: #f8d7da;
  color: #721c24;
}

/* カードコンテンツ */
.card-content {
  padding: 1.5rem;
}

.info-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
  margin-bottom: 1rem;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 0.2rem;
}

.info-label {
  font-size: 0.9rem;
  color: #6c757d;
  font-weight: bold;
}

.info-value {
  color: #2c3e50;
  font-weight: bold;
}

.efficiency-value {
  color: #28a745;
}

/* センサーデータ */
.sensor-data {
  background-color: #f8f9fa;
  padding: 1rem;
  border-radius: 6px;
  margin-top: 1rem;
}

.sensor-data h4 {
  color: #2c3e50;
  margin-bottom: 0.8rem;
  font-size: 1rem;
}

.sensor-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.sensor-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.sensor-icon {
  font-size: 1.2rem;
}

.sensor-info {
  display: flex;
  flex-direction: column;
}

.sensor-label {
  font-size: 0.8rem;
  color: #6c757d;
}

.sensor-value {
  font-weight: bold;
  color: #2c3e50;
}

/* メンテナンス情報 */
.maintenance-info {
  background-color: #fff3cd;
  padding: 1rem;
  border-radius: 6px;
  margin-top: 1rem;
}

.maintenance-info h4 {
  color: #856404;
  margin-bottom: 0.5rem;
  font-size: 1rem;
}

.maintenance-info p {
  color: #856404;
  margin: 0.3rem 0;
}

/* カードフッター */
.card-footer {
  padding: 1rem 1.5rem;
  background-color: #f8f9fa;
  display: flex;
  gap: 0.5rem;
  justify-content: flex-end;
}

/* データなし表示 */
.no-data {
  text-align: center;
  padding: 3rem;
  color: #6c757d;
}

.no-data-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}

.no-data h3 {
  margin-bottom: 0.5rem;
}

/* レスポンシブ対応 */
@media (max-width: 768px) {
  .equipment-grid {
    grid-template-columns: 1fr;
  }
  
  .filter-controls {
    flex-direction: column;
    align-items: stretch;
  }
  
  .card-header {
    flex-direction: column;
    gap: 1rem;
    align-items: stretch;
  }
  
  .info-grid {
    grid-template-columns: 1fr;
  }
  
  .sensor-grid {
    grid-template-columns: 1fr;
  }
  
  .card-footer {
    flex-direction: column;
  }
}
</style>