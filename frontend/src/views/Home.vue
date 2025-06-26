<template>
  <div class="home-page">
    <!-- ヘロセクション -->
    <section class="hero-section">
      <div class="hero-content">
        <h1>🏭 工場設備管理システム</h1>
        <p>リアルタイムで設備状況を監視し、効率的なメンテナンス管理を実現</p>
        <div class="quick-actions">
          <router-link to="/equipment-status" class="btn btn-primary">
            設備状況を確認
          </router-link>
        </div>
      </div>
    </section>

    <!-- 統計カードセクション -->
    <section class="stats-section">
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-icon">🏭</div>
          <div class="stat-content">
            <h3>{{ statistics.totalEquipment }}</h3>
            <p>総設備数</p>
          </div>
        </div>
        
        <div class="stat-card active">
          <div class="stat-icon">✅</div>
          <div class="stat-content">
            <h3>{{ statistics.activeEquipment }}</h3>
            <p>稼働中設備</p>
          </div>
        </div>
        
        <div class="stat-card maintenance">
          <div class="stat-icon">🔧</div>
          <div class="stat-content">
            <h3>{{ statistics.maintenanceEquipment }}</h3>
            <p>メンテナンス中</p>
          </div>
        </div>
        
        <div class="stat-card efficiency">
          <div class="stat-icon">📊</div>
          <div class="stat-content">
            <h3>{{ averageEfficiency }}%</h3>
            <p>平均稼働率</p>
          </div>
        </div>
      </div>
    </section>

    <!-- 主要機能セクション -->
    <section class="features-section">
      <h2>主要機能</h2>
      <div class="features-grid">
        <div class="feature-card">
          <div class="feature-icon">📈</div>
          <h3>リアルタイム監視</h3>
          <p>設備の状況をリアルタイムで監視し、異常を素早く検知します。</p>
        </div>
        
        <div class="feature-card">
          <div class="feature-icon">🔧</div>
          <h3>メンテナンス管理</h3>
          <p>予防保全を効率化し、設備の長寿命化とコスト削減を実現します。</p>
        </div>
        
        <div class="feature-card">
          <div class="feature-icon">📊</div>
          <h3>データ分析</h3>
          <p>蓄積されたデータを分析し、改善提案や予測保全を支援します。</p>
        </div>
        
        <div class="feature-card">
          <div class="feature-icon">⚠️</div>
          <h3>アラート通知</h3>
          <p>重要な異常や予定されたメンテナンスを適切なタイミングで通知します。</p>
        </div>
      </div>
    </section>

    <!-- 最近の活動セクション -->
    <section class="recent-activity-section">
      <h2>最近の活動</h2>
      <div class="activity-list">
        <div class="activity-item">
          <div class="activity-icon">🔧</div>
          <div class="activity-content">
            <h4>プレス機1号機 - メンテナンス開始</h4>
            <p>定期メンテナンスが開始されました</p>
            <span class="activity-time">2時間前</span>
          </div>
        </div>
        
        <div class="activity-item">
          <div class="activity-icon">✅</div>
          <div class="activity-content">
            <h4>第1製造ライン主モーター - 正常稼働</h4>
            <p>温度・振動値が正常範囲内です</p>
            <span class="activity-time">1時間前</span>
          </div>
        </div>
        
        <div class="activity-item">
          <div class="activity-icon">📊</div>
          <div class="activity-content">
            <h4>品質検査装置 - 高効率稼働</h4>
            <p>稼働率99.5%を記録しています</p>
            <span class="activity-time">30分前</span>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script>
import { equipmentService } from '../services/equipmentService.js'

export default {
  name: 'Home',
  data() {
    return {
      statistics: {
        totalEquipment: 0,
        activeEquipment: 0,
        maintenanceEquipment: 0,
        averageEfficiency: 0
      }
    }
  },
  computed: {
    averageEfficiency() {
      return this.statistics.averageEfficiency ? this.statistics.averageEfficiency.toFixed(1) : '0.0'
    }
  },
  async mounted() {
    await this.loadStatistics()
  },
  methods: {
    async loadStatistics() {
      try {
        this.statistics = await equipmentService.getStatistics()
      } catch (error) {
        console.error('統計データの読み込みに失敗しました:', error)
      }
    }
  }
}
</script>

<style scoped>
.home-page {
  min-height: calc(100vh - 200px);
}

/* ヘロセクション */
.hero-section {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 4rem 2rem;
  text-align: center;
  margin: -2rem -2rem 2rem -2rem;
}

.hero-content h1 {
  font-size: 2.5rem;
  margin-bottom: 1rem;
  font-weight: bold;
}

.hero-content p {
  font-size: 1.1rem;
  margin-bottom: 2rem;
  opacity: 0.9;
}

.quick-actions {
  margin-top: 2rem;
}

.btn {
  display: inline-block;
  padding: 1rem 2rem;
  border-radius: 6px;
  text-decoration: none;
  font-weight: bold;
  transition: all 0.3s;
  border: none;
  cursor: pointer;
}

.btn-primary {
  background-color: #fff;
  color: #667eea;
}

.btn-primary:hover {
  background-color: #f8f9fa;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

/* 統計セクション */
.stats-section {
  margin-bottom: 3rem;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
}

.stat-card {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  display: flex;
  align-items: center;
  gap: 1rem;
  transition: transform 0.3s;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
}

.stat-card.active {
  border-left: 4px solid #28a745;
}

.stat-card.maintenance {
  border-left: 4px solid #ffc107;
}

.stat-card.efficiency {
  border-left: 4px solid #17a2b8;
}

.stat-icon {
  font-size: 2rem;
}

.stat-content h3 {
  font-size: 2rem;
  margin-bottom: 0.3rem;
  color: #2c3e50;
}

.stat-content p {
  color: #6c757d;
  margin: 0;
}

/* 機能セクション */
.features-section {
  margin-bottom: 3rem;
}

.features-section h2 {
  text-align: center;
  margin-bottom: 2rem;
  color: #2c3e50;
  font-size: 2rem;
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 2rem;
}

.feature-card {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  text-align: center;
  transition: transform 0.3s;
}

.feature-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15);
}

.feature-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.feature-card h3 {
  color: #2c3e50;
  margin-bottom: 1rem;
}

.feature-card p {
  color: #6c757d;
  line-height: 1.6;
}

/* 最近の活動セクション */
.recent-activity-section h2 {
  color: #2c3e50;
  margin-bottom: 1.5rem;
  font-size: 1.8rem;
}

.activity-list {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.activity-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.5rem;
  border-bottom: 1px solid #e9ecef;
}

.activity-item:last-child {
  border-bottom: none;
}

.activity-icon {
  font-size: 1.5rem;
  flex-shrink: 0;
}

.activity-content {
  flex: 1;
}

.activity-content h4 {
  color: #2c3e50;
  margin-bottom: 0.3rem;
}

.activity-content p {
  color: #6c757d;
  margin-bottom: 0.3rem;
}

.activity-time {
  color: #adb5bd;
  font-size: 0.9rem;
}

/* レスポンシブ対応 */
@media (max-width: 768px) {
  .hero-content h1 {
    font-size: 2rem;
  }
  
  .stats-grid {
    grid-template-columns: 1fr;
  }
  
  .features-grid {
    grid-template-columns: 1fr;
  }
  
  .hero-section {
    padding: 2rem 1rem;
    margin: -1rem -1rem 1rem -1rem;
  }
}
</style>