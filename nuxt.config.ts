export default defineNuxtConfig({
  compatibilityDate: '2026-09-08',
  devtools: { enabled: false },
  css: ['~/assets/css/main.css'],
  runtimeConfig: {
    supabaseSecretKey: '', googlePlacesApiKey: '',
    public: { supabaseUrl: '', supabaseAnonKey: '', googleMapsApiKey: '', siteUrl: 'http://localhost:3000' },
  },
  app: { head: { htmlAttrs: { lang: 'ja' }, title: 'ひとくち大阪 | 今日の「食べたい」に、出会おう。', meta: [{ name: 'description', content: '気分にぴったりの大阪のお店を、一枚ずつ。あなたのための外食レコメンド。' }] } },
  routeRules: { '/admin/**': { headers: { 'X-Robots-Tag': 'noindex' } }, '/favorites': { headers: { 'X-Robots-Tag': 'noindex' } }, '/visits': { headers: { 'X-Robots-Tag': 'noindex' } }, '/feedback/**': { headers: { 'X-Robots-Tag': 'noindex' } }, '/account': { headers: { 'X-Robots-Tag': 'noindex' } } },
})
