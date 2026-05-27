-- ══════════════════════════════════════════════════════════
-- MUTUAL PAY OTC — Schema Supabase
-- Cole todo este conteúdo no SQL Editor do Supabase e execute
-- ══════════════════════════════════════════════════════════

-- 1. Tabela de perfis (estende auth.users)
create table public.profiles (
  id        uuid references auth.users on delete cascade primary key,
  role      text not null default 'partner',  -- 'trader' ou 'partner'
  name      text,
  company   text,
  whatsapp  text,
  created_at timestamptz default now()
);

-- 2. Tabela de operações
create table public.operations (
  id         uuid default gen_random_uuid() primary key,
  op_id      text unique not null,
  partner_id uuid references public.profiles(id) on delete cascade,
  status     text not null default 'Demanda recebida',

  -- dados da operação (intake)
  tipo          text,
  moeda_origem  text,
  valor         numeric,
  moeda_destino text,
  pais_destino  text,
  sla_desejado  text,
  proposito     text,
  invoice       text,

  -- remetente
  remetente     text,
  pais_remetente text,
  tipo_doc      text,
  num_doc       text,
  status_kyc    text,
  end_remetente text,
  docs_remetente text,

  -- beneficiário
  beneficiario     text,
  ramo             text,
  website          text,
  doc_registro     text,
  status_kyb       text,
  end_beneficiario text,
  kyb_docs         text,

  -- cotação do trader
  taxa_base          numeric,
  valor_destino_base numeric,
  tarifas_base       text,
  sla                text,
  validade           timestamptz,
  obs_trader         text,

  -- cotação final (parceiro aplica fee)
  spread              numeric,
  taxa_final          numeric,
  valor_destino_final numeric,
  tarifas_final       text,
  obs_cliente         text,

  -- resposta do cliente
  cliente_aceite    boolean,
  cliente_aceite_at timestamptz,

  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 3. Row Level Security
alter table public.profiles  enable row level security;
alter table public.operations enable row level security;

-- 4. Função: usuário é trader?
create or replace function public.is_trader()
returns boolean language sql security definer as $$
  select exists(
    select 1 from public.profiles
    where id = auth.uid() and role = 'trader'
  );
$$;

-- 5. Políticas de acesso — profiles
create policy "Usuário vê próprio perfil"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Usuário atualiza próprio perfil"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Trader vê todos os perfis"
  on public.profiles for select
  using (public.is_trader());

-- 6. Políticas de acesso — operations
create policy "Trader acessa todas operações"
  on public.operations for all
  using (public.is_trader());

create policy "Parceiro vê próprias operações"
  on public.operations for select
  using (partner_id = auth.uid());

create policy "Parceiro cria operação"
  on public.operations for insert
  with check (partner_id = auth.uid());

create policy "Parceiro atualiza própria operação"
  on public.operations for update
  using (partner_id = auth.uid());

-- 7. Trigger: cria perfil automaticamente ao registrar usuário
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, name, company, whatsapp, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', new.email),
    coalesce(new.raw_user_meta_data->>'company', ''),
    coalesce(new.raw_user_meta_data->>'whatsapp', ''),
    coalesce(new.raw_user_meta_data->>'role', 'partner')
  );
  return new;
end;
$$;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
