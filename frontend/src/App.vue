<template>
  <div id="app">
    <header class="app-header">
      <div class="header-container">
        <div class="logo-section">
          <h1>🏭 FactoryManagement</h1>
          <p>工場設備管理システム</p>
        </div>
        <nav class="main-navigation">
          <router-link to="/" class="nav-link">ホーム</router-link>
          <router-link to="/equipment-status" class="nav-link">設備稼働状況</router-link>
        </nav>
      </div>
    </header>
    
    <main class="main-content">
      <router-view />
    </main>
    
    <footer class="app-footer">
      <p>&copy; 2024 FactoryManagement System. All rights reserved.</p>
    </footer>
  </div>
</template>

<script>
export default {
  name: 'App'
}
</script>

<style>
/* グローバルスタイル */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Arial', 'Hiragino Sans', 'Yu Gothic', sans-serif;
  line-height: 1.6;
  color: #333;
  background-color: #f5f5f5;
}

#app {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

/* ヘッダースタイル */
.app-header {
  background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
  color: white;
  padding: 1rem 0;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.header-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.logo-section h1 {
  font-size: 1.8rem;
  margin-bottom: 0.2rem;
}

.logo-section p {
  font-size: 0.9rem;
  opacity: 0.8;
}

.main-navigation {
  display: flex;
  gap: 2rem;
}

.nav-link {
  color: white;
  text-decoration: none;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  transition: background-color 0.3s;
}

.nav-link:hover,
.nav-link.router-link-active {
  background-color: rgba(255, 255, 255, 0.2);
}

/* メインコンテンツ */
.main-content {
  flex: 1;
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
  width: 100%;
}

/* フッター */
.app-footer {
  background-color: #2c3e50;
  color: white;
  text-align: center;
  padding: 1rem;
  margin-top: auto;
}

/* レスポンシブ対応 */
@media (max-width: 768px) {
  .header-container {
    flex-direction: column;
    gap: 1rem;
    text-align: center;
  }
  
  .main-navigation {
    justify-content: center;
  }
  
  .main-content {
    padding: 1rem;
  }
}
</style>