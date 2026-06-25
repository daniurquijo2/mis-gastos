-- ============================================================
--  Esquema de la app de Gastos para Supabase
--  Pega TODO esto en: Supabase -> SQL Editor -> New query -> Run
-- ============================================================

-- ---------- TABLAS ----------
create table if not exists folders (
  id         text primary key,
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name       text not null,
  color      text not null default '#4f8cff',
  created_at timestamptz not null default now()
);

create table if not exists tags (
  id         text primary key,
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name       text not null,
  color      text not null default '#3ecf8e',
  created_at timestamptz not null default now()
);

create table if not exists expenses (
  id         text primary key,
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name       text not null,
  price      numeric not null default 0,
  date       text,
  folder_id  text,
  tag_ids    text[] not null default '{}',
  necesidad  text not null default 'prescindible',
  photo_path text,
  photos     text[] not null default '{}',
  created_at bigint,
  deleted_at timestamptz
);

-- Si la tabla expenses ya existía (caso de Dani), añade las columnas nuevas:
alter table expenses add column if not exists necesidad text not null default 'prescindible';
alter table expenses add column if not exists deleted_at timestamptz;
alter table expenses add column if not exists photos text[] not null default '{}';

-- ---------- SEGURIDAD POR FILA (cada usuario solo ve lo suyo) ----------
alter table folders  enable row level security;
alter table tags     enable row level security;
alter table expenses enable row level security;

drop policy if exists "own folders"  on folders;
drop policy if exists "own tags"     on tags;
drop policy if exists "own expenses" on expenses;

create policy "own folders"  on folders  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own tags"     on tags     for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own expenses" on expenses for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------- ALMACEN DE FOTOS ----------
insert into storage.buckets (id, name, public)
values ('fotos','fotos', true)
on conflict (id) do nothing;

drop policy if exists "fotos insert" on storage.objects;
drop policy if exists "fotos update" on storage.objects;
drop policy if exists "fotos delete" on storage.objects;

create policy "fotos insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'fotos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "fotos update" on storage.objects
  for update to authenticated
  using (bucket_id = 'fotos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "fotos delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'fotos' and (storage.foldername(name))[1] = auth.uid()::text);
