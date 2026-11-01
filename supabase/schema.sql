-- 파크리오마당 전용 새 프로젝트에만 적용합니다.
create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nickname text not null check (char_length(nickname) between 2 and 30),
  full_name text check (full_name is null or char_length(full_name) <= 80),
  building text check (building is null or char_length(building) <= 20),
  unit text check (unit is null or char_length(unit) <= 20),
  created_at timestamptz not null default now()
);
create table public.restrictions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  reason text not null default '운영 규칙 위반',
  created_at timestamptz not null default now()
);
create table public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references auth.users(id) on delete cascade,
  author_label text not null check (char_length(author_label) between 2 and 30),
  kind text not null check (kind in ('notice','board','proposal')),
  title text not null check (char_length(trim(title)) between 1 and 120),
  body text not null default '' check (char_length(body) <= 5000),
  problem text not null default '' check (char_length(problem) <= 3000),
  solution text not null default '' check (char_length(solution) <= 3000),
  benefit text not null default '' check (char_length(benefit) <= 2000),
  image_path text,
  created_at timestamptz not null default now()
);
create index posts_kind_date on public.posts(kind, created_at desc);
create table public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  author_id uuid not null references auth.users(id) on delete cascade,
  author_label text not null check (char_length(author_label) between 2 and 30),
  body text not null check (char_length(trim(body)) between 1 and 2000),
  created_at timestamptz not null default now()
);
create index comments_post_date on public.comments(post_id, created_at);
alter table public.profiles enable row level security;
alter table public.restrictions enable row level security;
alter table public.posts enable row level security;
alter table public.comments enable row level security;

-- 관리자 자격은 사용자가 수정할 수 없는 Auth app_metadata에서만 부여합니다.
create policy profiles_read on public.profiles for select to authenticated
  using (user_id = (select auth.uid()) or (select auth.jwt()->'app_metadata'->>'site_role') = 'admin');
create policy profiles_insert on public.profiles for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy profiles_update on public.profiles for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy restrictions_read on public.restrictions for select to authenticated
  using (user_id = (select auth.uid()) or (select auth.jwt()->'app_metadata'->>'site_role') = 'admin');
create policy restrictions_insert on public.restrictions for insert to authenticated
  with check ((select auth.jwt()->'app_metadata'->>'site_role') = 'admin');
create policy restrictions_delete on public.restrictions for delete to authenticated
  using ((select auth.jwt()->'app_metadata'->>'site_role') = 'admin');
create policy posts_read on public.posts for select to anon using (kind = 'notice');
create policy posts_member_read on public.posts for select to authenticated using (true);
create policy posts_insert on public.posts for insert to authenticated
  with check (author_id = (select auth.uid()) and
    (kind in ('board','proposal') or (select auth.jwt()->'app_metadata'->>'site_role') = 'admin') and
    not exists (select 1 from public.restrictions r where r.user_id = (select auth.uid())));
create policy posts_update on public.posts for update to authenticated
  using (author_id = (select auth.uid()) or (select auth.jwt()->'app_metadata'->>'site_role') = 'admin')
  with check ((author_id = (select auth.uid()) and kind in ('board','proposal') or (select auth.jwt()->'app_metadata'->>'site_role') = 'admin') and
    not exists (select 1 from public.restrictions r where r.user_id = (select auth.uid())));
create policy posts_delete on public.posts for delete to authenticated
  using (author_id = (select auth.uid()) or (select auth.jwt()->'app_metadata'->>'site_role') = 'admin');
create policy comments_read on public.comments for select to authenticated using (true);
create policy comments_insert on public.comments for insert to authenticated
  with check (author_id = (select auth.uid()) and not exists (select 1 from public.restrictions r where r.user_id = (select auth.uid())));
create policy comments_delete on public.comments for delete to authenticated
  using (author_id = (select auth.uid()) or (select auth.jwt()->'app_metadata'->>'site_role') = 'admin');

grant select, insert on public.profiles to authenticated;
grant update (nickname, full_name, building, unit) on public.profiles to authenticated;
grant select, insert, delete on public.restrictions to authenticated;
grant select on public.posts to anon;
grant select, insert, update, delete on public.posts to authenticated;
grant select, insert, delete on public.comments to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('post-images','post-images',false,5242880,array['image/jpeg','image/png','image/webp']);
create policy post_images_read on storage.objects for select to authenticated using (bucket_id = 'post-images');
create policy post_images_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'post-images' and (storage.foldername(name))[1] = (select auth.uid())::text and
    not exists (select 1 from public.restrictions r where r.user_id = (select auth.uid())));
create policy post_images_delete on storage.objects for delete to authenticated
  using (bucket_id = 'post-images' and (storage.foldername(name))[1] = (select auth.uid())::text);
