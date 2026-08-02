-- ======================================================
-- LetsTradeTCG Binder — schema V2
-- Rode este script UMA VEZ no Supabase: seu projeto →
-- SQL Editor → New query → cole tudo → Run
-- ======================================================

-- 1) Perfil do usuário (dados do cadastro)
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  nickname text unique not null,
  birthdate date,
  state text,               -- sigla do estado, ex: SP, RJ
  whatsapp text default '',
  created_at timestamptz default now()
);

alter table profiles enable row level security;

create policy "Perfis são públicos para leitura"
  on profiles for select
  using (true);

create policy "Usuário só cria o próprio perfil"
  on profiles for insert
  with check (auth.uid() = id);

create policy "Usuário só atualiza o próprio perfil"
  on profiles for update
  using (auth.uid() = id);

-- 2) Binders (pastas) — cada usuário pode ter várias
create table if not exists binders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  views int default 0,
  created_at timestamptz default now()
);

alter table binders enable row level security;

create policy "Binders são públicos para leitura"
  on binders for select
  using (true);

create policy "Usuário só cria binder próprio"
  on binders for insert
  with check (auth.uid() = user_id);

create policy "Usuário só atualiza binder próprio"
  on binders for update
  using (auth.uid() = user_id);

create policy "Usuário só apaga binder próprio"
  on binders for delete
  using (auth.uid() = user_id);

-- Função seguindo security definer pra incrementar visitas sem
-- precisar dar permissão de UPDATE geral na tabela pra qualquer um
create or replace function increment_binder_views(binder_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update binders set views = views + 1 where id = binder_id;
end;
$$;

grant execute on function increment_binder_views(uuid) to anon, authenticated;

-- 3) Cartas ("folhas") dentro de cada binder
create table if not exists cards (
  id uuid primary key default gen_random_uuid(),
  binder_id uuid references binders(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  image_path text not null,
  condition text,            -- M, NM, SP, MP, HP, DM
  price text default '',
  for_trade boolean default false,
  for_sale boolean default false,
  created_at timestamptz default now()
);

alter table cards enable row level security;

create policy "Cartas são públicas para leitura"
  on cards for select
  using (true);

create policy "Usuário só insere carta própria"
  on cards for insert
  with check (auth.uid() = user_id);

create policy "Usuário só atualiza carta própria"
  on cards for update
  using (auth.uid() = user_id);

create policy "Usuário só apaga carta própria"
  on cards for delete
  using (auth.uid() = user_id);

-- 4) Bucket de imagens (público pra leitura, protegido pra escrita)
insert into storage.buckets (id, name, public)
values ('cards', 'cards', true)
on conflict (id) do nothing;

create policy "Imagens do bucket cards são públicas"
  on storage.objects for select
  using (bucket_id = 'cards');

create policy "Usuário só sobe na própria pasta"
  on storage.objects for insert
  with check (
    bucket_id = 'cards'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Usuário só apaga da própria pasta"
  on storage.objects for delete
  using (
    bucket_id = 'cards'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
