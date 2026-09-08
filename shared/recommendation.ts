import { attributeLabels, genres, type Restaurant, type Conditions, type History, type Recommendation } from './domain'
const goodMap:Record<string,string[]>={atmosphere:['quiet','date_friendly'],quiet:['quiet','date_friendly']}
const badMap:Record<string,string[]>={expensive:['good_value'],crowded:['lively'],noisy:['lively'],slow:['quick_service'],small_portions:['large_portions'],too_much:['large_portions'],not_solo:['solo_friendly'],far:['near_station'],taste:['taste'],service:['service']}
export function preferenceWeights(history:History,restaurants:Restaurant[]) {
 const weights:Record<string,number>={}; const add=(key:string,v:number)=>{weights[key]=(weights[key]||0)+v}; const addRestaurant=(id:string,amount:number)=>{const r=restaurants.find(r=>r.id===id);if(r)Object.entries(r.attributes).forEach(([key,strength])=>add(key,amount*strength))}
 history.actions.filter(a=>!a.undone).forEach(a=>addRestaurant(a.restaurantId,({like:2,skip:-.2,detail:.3,undo:0})[a.action]));history.visits.forEach(v=>addRestaurant(v.restaurantId,1))
 history.feedback.forEach(f=>{const weight=({1:-3,2:-1.5,3:0,4:1.5,5:3})[f.satisfaction as 1|2|3|4|5];if(weight>0)f.goodTags.forEach(t=>(goodMap[t]||[t]).forEach(k=>add(k,weight)));if(weight<0)f.badTags.forEach(t=>(badMap[t]||[t]).forEach(k=>add(k,weight)))})
 return weights
}
export function rankRestaurants(restaurants:Restaurant[],conditions:Conditions,history:History,excluded:string[]=[],quality:Record<string,{count:number;mean:number}>={}):Recommendation[]{
 const weights=preferenceWeights(history,restaurants)
 const ranked=restaurants.filter(r=>r.citySlug===conditions.citySlug&&r.status==='published'&&!excluded.includes(r.id)&&!history.blocked.includes(r.id)).map(r=>{
 const genreMatch=conditions.genres.some(g=>r.genres.includes(g));const partyMatch=r.partySizes.includes(conditions.partySize);const occasionMatch=!!conditions.occasion&&r.occasions.includes(conditions.occasion);const budgetMatch=(conditions.budgetMin===null||r.priceMax>=conditions.budgetMin)&&(conditions.budgetMax===null||r.priceMin<=conditions.budgetMax); const personal=Object.entries(r.attributes).reduce((s,[k,v])=>s+(weights[k]||0)*v,0);const q=quality[r.id];const aggregate=q?((q.mean*q.count+3.5*5)/(q.count+5)):0
 const recentSkip=history.actions.some(a=>a.restaurantId===r.id&&a.action==='skip'&&!a.undone&&Date.now()-Date.parse(a.createdAt)<7*86400000)?.2:0
 const reasons:string[]=[];const best=Object.keys(r.attributes).filter(k=>(weights[k]||0)>0).sort((a,b)=>(weights[b]||0)-(weights[a]||0))[0];if(best)reasons.push(`あなたが気に入った「${attributeLabels[best]||best}」の特徴があります`);if(partyMatch)reasons.push(conditions.partySize===1?'一人でも入りやすいお店です':`${conditions.partySize===4?'3〜4':conditions.partySize===5?'5人以上':conditions.partySize+'人'}での食事に向いています`);if(genreMatch)reasons.push(`食べたい${genres.find(g=>r.genres.includes(g.key)&&conditions.genres.includes(g.key))?.label}にぴったり`);if(budgetMatch&&(conditions.budgetMin!==null||conditions.budgetMax!==null))reasons.push('選択した予算に合っています');if(!reasons.length)reasons.push('編集部が選んだ、大阪で出会いたい一軒です')
 return {...r,score:r.editorialScore*2+Number(genreMatch)*4+Number(partyMatch)*3+Number(occasionMatch)*3+Number(budgetMatch)*2+personal+aggregate*2-recentSkip,recommendationReasons:reasons.slice(0,2),exploration:false}
 }).sort((a,b)=>b.score-a.score||a.id.localeCompare(b.id))
 // Every eighth card is an eligible discovery. Stable ordering keeps pagination deterministic.
 for(let i=7;i<ranked.length;i+=8){const j=ranked.findIndex((r,j)=>j>i&&(!conditions.genres.length||!r.genres.some(g=>conditions.genres.includes(g)))&&(conditions.budgetMax===null||r.priceMin<=conditions.budgetMax*1.5)&&(conditions.budgetMin===null||r.priceMax>=conditions.budgetMin*.5));if(j>i){const [r]=ranked.splice(j,1);if(r){r.exploration=true;r.recommendationReasons=['いつもと少し違う、おいしい発見を'];ranked.splice(i,0,r)}}}
 return ranked
}
