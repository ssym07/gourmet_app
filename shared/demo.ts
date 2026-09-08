import type { Restaurant } from './domain'
const rows = [
 ['umeda-shoyu','中華そば こむぎ','梅田','ramen',900,1400,['solo_friendly','counter_seats','quick_service'],'香り立つ醤油と、つるりとした細麺。','澄んだスープをひと口。忙しい日にも、ほっとできる一杯です。','ramen'],
 ['namba-sushi','鮨と小皿 なぎ','難波','seafood',2000,3800,['quiet','date_friendly','counter_seats'],'一貫ずつ、ゆっくり楽しむご褒美。','季節の魚を使った握りと小皿料理。肩ひじ張らずに楽しめるカウンターです。','sushi'],
 ['tenma-yakiniku','焼肉 まると','天満','yakiniku',2800,4500,['lively','group_friendly','good_value'],'おいしいお肉を、気の合う人と。','焼きたてのお肉を囲んで、会話が弾む夜に。シェアできる盛り合わせが主役です。','meat'],
 ['fukushima-izakaya','酒と肴 よりみち','福島','izakaya',2000,3500,['group_friendly','lively','near_station'],'今日の終わりに、ちょうどいい一軒。','丁寧な小鉢と温かい料理を少しずつ。友人との気軽な食事におすすめです。','table'],
 ['nakazakicho-cafe','喫茶 こもれび','中崎町','cafe',800,1600,['quiet','photogenic','date_friendly'],'ひと息つける、コーヒーと甘い時間。','焼き菓子とコーヒーを楽しむ、ゆったりした午後のための喫茶店です。','cafe'],
 ['shinsaibashi-pasta','食堂 オリーブ','心斎橋','western',1300,2200,['date_friendly','quiet','good_value'],'旬の野菜を、ひと皿に。','ソースが絡んだパスタと彩り豊かな前菜。気取らない洋食を楽しめます。','pasta'],
 ['namba-gyoza','餃子日和','難波','chinese',800,1500,['solo_friendly','quick_service','good_value'],'ぱりっと、じゅわっと。幸せなひと口。','焼きたて餃子をメインにした定食。さっと食べたい日にもぴったりです。','gyoza'],
 ['tsuruhashi-korean','韓国ごはん ソダム','鶴橋','korean',1400,2600,['spicy','group_friendly','large_portions'],'熱々の韓国ごはんで、元気をチャージ。','野菜たっぷりのビビンバと旨辛料理。友人とシェアする食事にも。','korean'],
 ['honmachi-ramen','だし麺 しずく','本町','ramen',850,1200,['solo_friendly','quiet','counter_seats'],'だしの余韻まで、おいしい一杯。','やさしい風味のスープと丁寧な一杯。お昼のひとりごはんに。','ramen'],
 ['umeda-seafood','海鮮食堂 みなと','梅田','seafood',1000,1900,['good_value','large_portions','near_station'],'彩り豊かな海鮮丼を、気軽に。','いろいろな魚を一度に味わう海鮮丼。しっかり食べたい日のランチに。','sushi'],
 ['tennoji-western','洋食 キッチン日々','天王寺','western',1100,1900,['group_friendly','good_value','large_portions'],'いつもの日を、少し特別に。','家族で囲む温かい洋食。みんなで選べるメニューを用意した食堂です。','meat'],
 ['kitahama-cafe','北浜 リバーカフェ','北浜','cafe',1200,2100,['photogenic','quiet','date_friendly'],'水辺の気分で、ゆっくりランチ。','会話を楽しみながら過ごす、カフェごはんとスイーツの時間です。','cafe'],
] as const
export const demoRestaurants:Restaurant[]=rows.map((r,i)=>({id:`10000000-0000-4000-8000-${String(i+1).padStart(12,'0')}`,slug:r[0],name:r[1],area:r[2],genres:[r[3]],priceMin:r[4],priceMax:r[5],attributes:Object.fromEntries(r[6].map(k=>[k,1])),recommendationText:r[7],description:r[8],coverImageUrl:r[9]==='sushi'?'/images/sushi.jpeg':r[9]==='gyoza'?'/images/tyuuka.webp':`/images/${r[9]}.webp`,citySlug:'osaka',editorialScore:4+(i%4)*.2,partySizes:r[6].includes('group_friendly' as never)?[2,4,5]:[1,2],occasions:r[6].includes('date_friendly' as never)?['date','friends']:['casual_meal','friends','family','sightseeing'],status:'published',placeId:'',images:[],demo:true}))
