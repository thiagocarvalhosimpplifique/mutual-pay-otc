-- ══════════════════════════════════════════════════════════
-- MUTUAL PAY OTC — Clientes cadastrados pelo parceiro
-- Cole no SQL Editor do Supabase e execute
-- ══════════════════════════════════════════════════════════

-- 1. Tabela de clientes
create table if not exists public.clients (
  id           uuid default gen_random_uuid() primary key,
  partner_id   uuid references public.profiles(id) on delete cascade,
  tipo         text default 'remetente',  -- 'remetente' | 'beneficiario' | 'ambos'
  nome         text not null,
  pais         text,
  tipo_doc     text,
  num_doc      text,
  status_kyc   text,
  status_kyb   text,
  end_completo text,
  docs         text,
  ramo         text,
  website      text,
  doc_registro text,
  kyb_docs     text,
  banco        text,
  swift_bic    text,
  iban_conta   text,
  agencia      text,
  pix_chave    text,
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);

alter table public.clients enable row level security;

-- Parceiro gerencia seus próprios clientes
create policy "Parceiro gerencia seus clientes"
  on public.clients for all
  using (partner_id = auth.uid());

-- Trader vê todos os clientes (somente leitura)
create policy "Trader vê todos os clientes"
  on public.clients for select
  using (public.is_trader());

-- 2. Link das operações aos clientes cadastrados
alter table public.operations add column if not exists remetente_id   uuid references public.clients(id);
alter table public.operations add column if not exists beneficiario_id uuid references public.clients(id);
