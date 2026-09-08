<script setup lang="ts">
import { Heart } from 'lucide-vue-next'
import type { Restaurant } from '../../shared/domain'
const app=useApp();const {data,error,refresh}=await useFetch<Restaurant[]>('/api/catalog');const saved=computed(()=>(data.value||[]).filter(r=>app.history.value.favorites.includes(r.id)));useHead({title:'気になるお店 | ひとくち大阪',meta:[{name:'robots',content:'noindex'}]})
</script>
<template><section class="page"><div class="section-heading"><div><div class="eyebrow">YOUR DELICIOUS WISHLIST</div><h1>気になるお店<span class="count-badge">{{saved.length}}</span></h1><p>次の「食べたい」を、ここに。</p></div></div><div v-if="error" class="error">店舗を取得できませんでした。<button @click="refresh()">再試行</button></div><ClientOnly><RestaurantList v-if="saved.length" :restaurants="saved"/><div v-else class="empty-state"><Heart :size="40"/><h2>おいしい出会いを、保存しよう。</h2><p>右にスワイプしたお店が、ここに並びます。</p><NuxtLink to="/" class="button primary">お店を見つける</NuxtLink></div><p v-if="!app.email.value&&saved.length" class="login-note">この端末に保存しています。<NuxtLink to="/account">ログイン</NuxtLink>すると、別の端末でも確認できます。</p></ClientOnly></section></template>
