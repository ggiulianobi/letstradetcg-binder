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

-- ======================================================
-- Adições — rodada de melhorias (classificação dinâmica por
-- foto + notificações de troca). Bloco idempotente, seguro pra
-- rodar de novo (não mexe nas tabelas já existentes).
-- ======================================================

-- 5) Linhas de classificação dentro de uma mesma foto (uma foto pode
-- conter várias cartas, cada uma com seu estado/preço/observação)
create table if not exists card_items (
  id uuid primary key default gen_random_uuid(),
  card_id uuid references cards(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  condition text,
  price text default '',
  for_trade boolean default false,
  for_sale boolean default false,
  note text default '',
  created_at timestamptz default now()
);

alter table card_items enable row level security;

create policy "Itens de carta são públicos para leitura"
  on card_items for select
  using (true);

create policy "Usuário só insere item próprio"
  on card_items for insert
  with check (auth.uid() = user_id);

create policy "Usuário só atualiza item próprio"
  on card_items for update
  using (auth.uid() = user_id);

create policy "Usuário só apaga item próprio"
  on card_items for delete
  using (auth.uid() = user_id);

-- 6) Pedidos de troca ("Let's Trade!")
create table if not exists trade_requests (
  id uuid primary key default gen_random_uuid(),
  from_user_id uuid references auth.users(id) on delete cascade not null,
  to_user_id uuid references auth.users(id) on delete cascade not null,
  from_binder_id uuid references binders(id) on delete set null,
  to_binder_id uuid references binders(id) on delete cascade not null,
  status text not null default 'pending',
  from_completed boolean default false,
  to_completed boolean default false,
  created_at timestamptz default now(),
  check (from_user_id <> to_user_id)
);

alter table trade_requests enable row level security;

create policy "Só as partes envolvidas veem o pedido de troca"
  on trade_requests for select
  using (auth.uid() = from_user_id or auth.uid() = to_user_id);

create policy "Usuário só cria pedido em nome próprio"
  on trade_requests for insert
  with check (auth.uid() = from_user_id);

-- Sem policy de update direto: a conclusão da troca passa pela função
-- abaixo (security definer), assim ninguém sobrescreve o lado do outro.
create or replace function complete_trade_request(request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  req trade_requests%rowtype;
begin
  select * into req from trade_requests where id = request_id;

  if req.id is null then
    raise exception 'Pedido de troca não encontrado';
  end if;

  if auth.uid() <> req.from_user_id and auth.uid() <> req.to_user_id then
    raise exception 'Você não faz parte desse pedido de troca';
  end if;

  if auth.uid() = req.from_user_id then
    update trade_requests set from_completed = true, status = 'completed' where id = request_id;
  else
    update trade_requests set to_completed = true, status = 'completed' where id = request_id;
  end if;
end;
$$;

grant execute on function complete_trade_request(uuid) to authenticated;

-- ======================================================
-- Adições — toggle de binder público/pesquisável.
-- Roda só uma vez (a segunda linha é uma migração pontual pros
-- binders que já existiam antes dessa coluna existir).
-- ======================================================

-- 7) Binder só aparece em carrossel/diretório/busca se is_public = true.
-- O link direto (binder.html?b=<id>) sempre funciona, público ou não —
-- isso não muda a policy de select, só o filtro usado nas listagens.
alter table binders add column if not exists is_public boolean not null default false;

-- Preserva a visibilidade dos binders criados antes dessa coluna existir
-- (senão eles somem da home/busca de uma hora pra outra).
update binders set is_public = true where is_public = false;
