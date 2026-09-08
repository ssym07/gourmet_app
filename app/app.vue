<script setup lang="ts">
import { Compass, Heart, BookOpen, UserRound, ArrowUpRight, Utensils } from 'lucide-vue-next'
const {demo,email,syncError,sync}=useApp()
</script>
<template>
 <div class="site-shell">
  <header class="site-header"><NuxtLink to="/" class="brand"><span class="brand-icon"><Utensils :size="22"/></span><span>ひとくち<span class="brand-city">大阪</span></span></NuxtLink><nav class="desktop-nav" aria-label="メインナビゲーション"><NuxtLink to="/">お店を見つける</NuxtLink><NuxtLink to="/favorites">気になるお店</NuxtLink><NuxtLink to="/visits">食べた記録</NuxtLink></nav><NuxtLink to="/account" class="account-link"><UserRound :size="17"/><span>{{email?'マイページ':'ログイン'}}</span><ArrowUpRight :size="15"/></NuxtLink></header>
  <div v-if="demo" class="demo-bar">DEMO <span>掲載店舗は架空のサンプルです。料理写真はイメージです。</span></div>
  <div v-if="syncError" class="error global-error" role="alert">{{syncError}} <button @click="sync">再試行</button></div>
  <main id="main"><NuxtPage/></main>
  <footer class="site-footer"><NuxtLink to="/" class="brand small">ひとくち 大阪</NuxtLink><span>おいしい出会いを、ひとつずつ。</span><div><NuxtLink to="/privacy">プライバシー</NuxtLink><NuxtLink to="/terms">利用規約</NuxtLink><NuxtLink to="/admin">管理画面</NuxtLink></div><small>© {{new Date().getFullYear()}} HITOKUCHI OSAKA</small></footer>
  <nav class="mobile-nav" aria-label="モバイルナビゲーション"><NuxtLink to="/"><Compass/>見つける</NuxtLink><NuxtLink to="/favorites"><Heart/>気になる</NuxtLink><NuxtLink to="/visits"><BookOpen/>食べた記録</NuxtLink><NuxtLink to="/account"><UserRound/>マイページ</NuxtLink></nav>
 </div>
</template>
