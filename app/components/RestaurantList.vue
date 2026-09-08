<script setup lang="ts">
import { Heart, ArrowUpRight, MapPin, Check } from 'lucide-vue-next'
import { priceLabel, type Restaurant } from '../../shared/domain'
defineProps<{restaurants:Restaurant[]}>();const app=useApp()
</script>
<template><div class="restaurant-grid"><article v-for="r in restaurants" :key="r.id" class="list-card"><NuxtLink :to="`/restaurants/${r.slug}`"><img :src="r.coverImageUrl" :alt="`${r.name}の料理イメージ`" loading="lazy"/><div class="list-card-content"><span class="muted location"><MapPin :size="13"/>{{r.area}}</span><h2>{{r.name}} <ArrowUpRight :size="18"/></h2><p>{{r.recommendationText}}</p><strong>{{priceLabel(r)}}</strong></div></NuxtLink><div class="list-card-actions"><button @click="app.favorite(r)"><Heart :size="17" :fill="app.history.value.favorites.includes(r.id)?'currentColor':'none'"/>{{app.history.value.favorites.includes(r.id)?'保存解除':'気になる'}}</button><button @click="navigateTo(`/feedback/${app.visit(r)}`)"><Check :size="17"/>行った</button></div></article></div></template>
