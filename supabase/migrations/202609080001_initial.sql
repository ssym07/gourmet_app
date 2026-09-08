-- Run in a Supabase project. UTC timestamps; private records cascade on account deletion.
create extension if not exists pgcrypto;
create table public.cities(id uuid primary key default gen_random_uuid(),name text not null,slug text unique not null,country_code char(2) not null,default_locale text not null,currency char(3) not null,timezone text not null,is_active boolean not null default false);
create table public.areas(id uuid primary key default gen_random_uuid(),city_id uuid not null references public.cities(id),parent_id uuid references public.areas(id),name text not null,slug text not null,sort_order integer not null default 0,unique(city_id,name));
create table public.restaurants(id uuid primary key default gen_random_uuid(),city_id uuid not null references public.cities(id),area_id uuid not null references public.areas(id),slug text unique not null,display_name text not null,description text not null default '',recommendation_text text not null default '',price_min integer not null default 0 check(price_min>=0),price_max integer not null default 0 check(price_max>=price_min),currency char(3) not null default 'JPY',editorial_score numeric not null default 3 check(editorial_score between 0 and 5),cover_image_url text not null,status text not null default 'draft' check(status in ('draft','published','closed')),party_sizes jsonb not null default '[1,2]',occasions jsonb not null default '[]',is_demo boolean not null default false,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table public.restaurant_places(id uuid primary key default gen_random_uuid(),restaurant_id uuid not null references public.restaurants(id) on delete cascade,provider text not null default 'google',external_place_id text not null,external_url text,is_primary boolean not null default true,last_refreshed_at timestamptz,unique(restaurant_id,provider));
create table public.attributes(id uuid primary key default gen_random_uuid(),key text unique not null,label text not null,category text not null);
create table public.restaurant_attributes(restaurant_id uuid not null references public.restaurants(id) on delete cascade,attribute_id uuid not null references public.attributes(id),strength numeric not null check(strength between 0 and 1),primary key(restaurant_id,attribute_id));
create table public.recommendation_sessions(id uuid primary key default gen_random_uuid(),user_id uuid references auth.users(id) on delete cascade,city_id uuid not null references public.cities(id),selected_genres jsonb not null default '[]',party_size integer not null default 1,occasion text,budget_min integer,budget_max integer,created_at timestamptz not null default now(),unique(id,user_id));
create table public.swipe_actions(id uuid primary key default gen_random_uuid(),session_id uuid not null,user_id uuid not null references auth.users(id) on delete cascade,restaurant_id uuid not null references public.restaurants(id),action text not null check(action in ('like','skip','detail','undo')),score_at_display numeric,undone boolean not null default false,was_favorite boolean not null default false,created_at timestamptz not null default now(),foreign key(session_id,user_id) references public.recommendation_sessions(id,user_id) on delete cascade);
create table public.favorites(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,restaurant_id uuid not null references public.restaurants(id),created_at timestamptz not null default now(),unique(user_id,restaurant_id));
create table public.visits(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,restaurant_id uuid not null references public.restaurants(id),visited_at date,created_at timestamptz not null default now(),unique(id,user_id,restaurant_id));
create table public.visit_feedback(id uuid primary key default gen_random_uuid(),visit_id uuid unique not null,user_id uuid not null references auth.users(id) on delete cascade,restaurant_id uuid not null references public.restaurants(id),satisfaction integer not null check(satisfaction between 1 and 5),revisit_intention text not null check(revisit_intention in ('yes','maybe','no')),actual_party_type text not null check(actual_party_type in ('solo','friends','partner','family','business','other')),good_tags jsonb not null default '[]',bad_tags jsonb not null default '[]',private_note text check(length(private_note)<=2000),time_slot text,actual_budget text,created_at timestamptz not null default now(),foreign key(visit_id,user_id,restaurant_id) references public.visits(id,user_id,restaurant_id) on delete cascade);
create table public.user_preference_weights(user_id uuid not null references auth.users(id) on delete cascade,attribute_id uuid not null references public.attributes(id),weight numeric not null default 0,updated_at timestamptz not null default now(),primary key(user_id,attribute_id));
create table public.restaurant_images(id uuid primary key default gen_random_uuid(),restaurant_id uuid not null references public.restaurants(id) on delete cascade,storage_path text not null,image_type text not null check(image_type in ('food','interior','exterior','menu')),alt_text text not null,credit_text text,usage_rights_note text,sort_order integer not null default 0);
-- Synchronization envelope retains anonymous event IDs and blocked IDs while normalized tables support analysis.
create table public.account_history(user_id uuid primary key references auth.users(id) on delete cascade,payload jsonb not null,updated_at timestamptz not null default now());
create index restaurants_public_city on public.restaurants(city_id,status);
create index swipe_user_session on public.swipe_actions(user_id,session_id);
create index feedback_restaurant on public.visit_feedback(restaurant_id);
create index visits_user on public.visits(user_id);
create function public.is_admin() returns boolean language sql stable set search_path='' as $$select coalesce(auth.jwt()->'app_metadata'->>'role','')='admin'$$;

do $$declare t text;begin
 foreach t in array array['cities','areas','restaurants','restaurant_places','attributes','restaurant_attributes','recommendation_sessions','swipe_actions','favorites','visits','visit_feedback','user_preference_weights','restaurant_images','account_history'] loop execute format('alter table public.%I enable row level security',t);end loop;
 foreach t in array array['recommendation_sessions','swipe_actions','favorites','visits','visit_feedback','user_preference_weights','account_history'] loop execute format('create policy owner_all on public.%I for all to authenticated using (user_id=(select auth.uid())) with check (user_id=(select auth.uid()))',t);end loop;
 foreach t in array array['cities','areas','restaurants','restaurant_places','attributes','restaurant_attributes','restaurant_images'] loop execute format('create policy admin_all on public.%I for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()))',t);end loop;
end$$;
create policy cities_read on public.cities for select using(is_active);
create policy areas_read on public.areas for select using(exists(select 1 from public.cities where id=city_id and is_active));
create policy restaurants_read on public.restaurants for select using(status='published' and exists(select 1 from public.cities where id=city_id and is_active));
create policy attributes_read on public.attributes for select using(true);
create policy places_read on public.restaurant_places for select using(exists(select 1 from public.restaurants where id=restaurant_id and status='published'));
create policy restaurant_attributes_read on public.restaurant_attributes for select using(exists(select 1 from public.restaurants where id=restaurant_id and status='published'));
create policy images_read on public.restaurant_images for select using(exists(select 1 from public.restaurants where id=restaurant_id and status='published'));
grant usage on schema public to anon,authenticated;
grant select on all tables in schema public to anon,authenticated;
grant insert,update,delete on all tables in schema public to authenticated;

insert into public.cities(id,name,slug,country_code,default_locale,currency,timezone,is_active) values('00000000-0000-4000-8000-000000000001','大阪','osaka','JP','ja','JPY','Asia/Tokyo',true);
insert into public.attributes(key,label,category) values
('ramen','ラーメン','genre'),('seafood','寿司・海鮮','genre'),('yakiniku','焼肉','genre'),('izakaya','居酒屋','genre'),('cafe','カフェ','genre'),('western','洋食','genre'),('chinese','中華','genre'),('korean','韓国料理','genre'),
('quiet','落ち着いて話せる','atmosphere'),('lively','にぎやか','atmosphere'),('solo_friendly','一人向け','occasion'),('counter_seats','カウンター席','atmosphere'),('good_value','コスパが良い','quality'),('large_portions','量が多い','quality'),('quick_service','提供が早い','quality'),('date_friendly','デート向き','occasion'),('group_friendly','グループ向き','occasion'),('near_station','駅近','location'),('photogenic','写真映え','atmosphere'),('spicy','辛い','taste'),('taste','味','quality'),('service','接客','quality');

create function public.save_restaurant(payload jsonb) returns void language plpgsql security invoker set search_path='' as $$
declare rid uuid := (payload->>'id')::uuid; aid uuid; cid uuid; item jsonb; k text; v jsonb;begin
 if not public.is_admin() then raise exception 'admin required' using errcode='42501';end if;
 select id into cid from public.cities where slug=payload->>'citySlug';if cid is null then raise exception 'invalid city';end if;
 insert into public.areas(city_id,name,slug) values(cid,payload->>'area',substr(md5(payload->>'area'),1,16)) on conflict(city_id,name) do update set name=excluded.name returning id into aid;
 insert into public.restaurants(id,city_id,area_id,slug,display_name,description,recommendation_text,price_min,price_max,editorial_score,cover_image_url,status,party_sizes,occasions,is_demo)
 values(rid,cid,aid,payload->>'slug',payload->>'name',payload->>'description',payload->>'recommendationText',(payload->>'priceMin')::integer,(payload->>'priceMax')::integer,(payload->>'editorialScore')::numeric,payload->>'coverImageUrl',payload->>'status',payload->'partySizes',payload->'occasions',coalesce((payload->>'demo')::boolean,false))
 on conflict(id) do update set area_id=excluded.area_id,slug=excluded.slug,display_name=excluded.display_name,description=excluded.description,recommendation_text=excluded.recommendation_text,price_min=excluded.price_min,price_max=excluded.price_max,editorial_score=excluded.editorial_score,cover_image_url=excluded.cover_image_url,status=excluded.status,party_sizes=excluded.party_sizes,occasions=excluded.occasions,is_demo=excluded.is_demo,updated_at=now();
 delete from public.restaurant_attributes where restaurant_id=rid;
 for k in select jsonb_array_elements_text(payload->'genres') loop insert into public.restaurant_attributes select rid,id,1 from public.attributes where key=k and category='genre';end loop;
 for k,v in select * from jsonb_each(payload->'attributes') loop insert into public.restaurant_attributes select rid,id,(v::text)::numeric from public.attributes where key=k and category<>'genre';end loop;
 delete from public.restaurant_places where restaurant_id=rid and provider='google';
 if coalesce(payload->>'placeId','')<>'' then insert into public.restaurant_places(restaurant_id,provider,external_place_id) values(rid,'google',payload->>'placeId');end if;
 delete from public.restaurant_images where restaurant_id=rid;
 for item in select * from jsonb_array_elements(payload->'images') loop insert into public.restaurant_images(restaurant_id,storage_path,image_type,alt_text,credit_text,usage_rights_note) values(rid,item->>'url',item->>'type',item->>'alt',item->>'credit',item->>'rights');end loop;
end$$;

create function public.read_history() returns jsonb language sql stable security invoker set search_path='' as $$select coalesce((select payload from public.account_history where user_id=auth.uid()),'{"favorites":[],"actions":[],"visits":[],"feedback":[],"blocked":[]}'::jsonb)$$;
create function public.write_history(payload jsonb,weights jsonb default '{}') returns void language plpgsql security invoker set search_path='' as $$
declare uid uuid:=auth.uid(); city uuid; item jsonb; vid uuid; rid uuid; sid uuid; k text; v jsonb;begin
 if uid is null then raise exception 'authentication required' using errcode='42501';end if;
 if pg_column_size(payload)>2097152 then raise exception 'history too large';end if;
 perform pg_advisory_xact_lock(hashtextextended(uid::text,0));
 select id into city from public.cities where slug='osaka';
 -- All writes form one transaction; invalid IDs or feedback ownership roll back the entire sync.
 delete from public.visit_feedback where user_id=uid;delete from public.visits where user_id=uid;delete from public.favorites where user_id=uid;delete from public.swipe_actions where user_id=uid;delete from public.recommendation_sessions where user_id=uid;delete from public.user_preference_weights where user_id=uid;
 for item in select * from jsonb_array_elements(payload->'actions') loop
 sid=(item->>'sessionId')::uuid;
 insert into public.recommendation_sessions(id,user_id,city_id) values(sid,uid,city) on conflict(id) do nothing;
 insert into public.swipe_actions(id,session_id,user_id,restaurant_id,action,undone,was_favorite,created_at) values((item->>'id')::uuid,sid,uid,(item->>'restaurantId')::uuid,item->>'action',coalesce((item->>'undone')::boolean,false),coalesce((item->>'wasFavorite')::boolean,false),(item->>'createdAt')::timestamptz);
 end loop;
 for k in select jsonb_array_elements_text(payload->'favorites') loop insert into public.favorites(user_id,restaurant_id) values(uid,k::uuid) on conflict(user_id,restaurant_id) do nothing;end loop;
 for item in select * from jsonb_array_elements(payload->'visits') loop insert into public.visits(id,user_id,restaurant_id,visited_at,created_at) values((item->>'id')::uuid,uid,(item->>'restaurantId')::uuid,(item->>'visitedAt')::date,(item->>'createdAt')::timestamptz);end loop;
 for item in select * from jsonb_array_elements(payload->'feedback') loop
 vid=(item->>'visitId')::uuid;select restaurant_id into rid from public.visits where id=vid and user_id=uid;if rid is null then raise exception 'visit not owned';end if;
 insert into public.visit_feedback(visit_id,user_id,restaurant_id,satisfaction,revisit_intention,actual_party_type,good_tags,bad_tags,private_note,time_slot,actual_budget) values(vid,uid,rid,(item->>'satisfaction')::integer,item->>'revisitIntention',item->>'actualPartyType',item->'goodTags',item->'badTags',item->>'privateNote',item->>'timeSlot',item->>'actualBudget');
 end loop;
 for k,v in select * from jsonb_each(weights) loop insert into public.user_preference_weights(user_id,attribute_id,weight) select uid,id,(v::text)::numeric from public.attributes where key=k;end loop;
 insert into public.account_history(user_id,payload) values(uid,payload) on conflict(user_id) do update set payload=excluded.payload,updated_at=now();
end$$;
-- Expose only aggregates, never private notes. A single user's repeat visits count once per restaurant.
create function public.restaurant_quality() returns table(restaurant_id uuid,answer_count bigint,mean numeric) language sql stable security definer set search_path='' as $$
 select f.restaurant_id,count(*),avg(f.score) from (select vf.restaurant_id,vf.user_id,avg(vf.satisfaction)::numeric as score from public.visit_feedback vf join public.restaurants r on r.id=vf.restaurant_id where r.status='published' group by vf.restaurant_id,vf.user_id) f group by f.restaurant_id having count(*)>=5 or public.is_admin()
$$;
revoke all on function public.save_restaurant(jsonb), public.write_history(jsonb,jsonb),public.read_history() from public,anon;
grant execute on function public.save_restaurant(jsonb),public.write_history(jsonb,jsonb),public.read_history() to authenticated;
revoke all on function public.restaurant_quality() from public;
grant execute on function public.restaurant_quality() to anon,authenticated;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('restaurant-images','restaurant-images',true,5242880,array['image/jpeg','image/png','image/webp']) on conflict(id) do nothing;
create policy food_images_read on storage.objects for select using(bucket_id='restaurant-images');
create policy food_images_admin on storage.objects for all to authenticated using(bucket_id='restaurant-images' and public.is_admin()) with check(bucket_id='restaurant-images' and public.is_admin());
