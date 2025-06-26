import { createApp } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import App from './App.vue'

// ビューコンポーネントのインポート
import Home from './views/Home.vue'
import EquipmentStatus from './views/EquipmentStatus.vue'

// ルーター設定
const routes = [
  {
    path: '/',
    name: 'Home',
    component: Home
  },
  {
    path: '/equipment-status',
    name: 'EquipmentStatus', 
    component: EquipmentStatus
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// アプリケーションの作成とマウント
createApp(App).use(router).mount('#app')