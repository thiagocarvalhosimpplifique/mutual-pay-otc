-- ══════════════════════════════════════════════════════════
-- MUTUAL PAY OTC — Destinatários de liquidação
-- Cole no SQL Editor do Supabase e execute
-- ══════════════════════════════════════════════════════════

create table if not exists public.destinatarios (
  id           uuid default gen_random_uuid() primary key,
  operation_id uuid references public.operations(id) on delete cascade,
  nome         text,
  documento    text,                       -- CPF, CNPJ, Tax ID do destinatário
  rede         text,                       -- Tron (TRC20), Ethereum (ERC20), PIX, SWIFT...
  carteira     text,                       -- endereço cripto ou chave PIX
  banco        text,
  swift_bic    text,
  iban_conta   text,
  agencia      text,
  moeda        text default 'USDT',
  valor        numeric,                    -- valor nessa moeda para este destinatário
  status       text default 'pendente',   -- pendente | confirmado | enviado | falhou
  tx_hash      text,                       -- hash da transação / comprovante
  notes        text,
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);

alter table public.destinatarios enable row level security;

-- Trader acessa tudo
create policy "Trader acessa todos os destinatários"
  on public.destinatarios for all
  using (public.is_trader());

-- Parceiro gerencia destinatários das suas próprias operações
create policy "Parceiro gerencia destinatários das suas operações"
  on public.destinatarios for all
  using (
    operation_id in (
      select id from public.operations where partner_id = auth.uid()
    )
  );
