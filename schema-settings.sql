-- ══════════════════════════════════════════════════════════
-- MUTUAL PAY OTC — Configurações da mesa (conta de recebimento)
-- Cole no SQL Editor do Supabase e execute
-- ══════════════════════════════════════════════════════════

create table if not exists public.settings (
  key        text primary key,
  value      jsonb,
  updated_at timestamptz default now()
);

alter table public.settings enable row level security;

-- Qualquer usuário autenticado pode ler
create policy "Usuário autenticado lê configurações"
  on public.settings for select
  using (auth.uid() is not null);

-- Apenas trader pode escrever
create policy "Trader gerencia configurações"
  on public.settings for all
  using (public.is_trader());

-- Linha inicial (trader irá preencher pelo painel)
insert into public.settings (key, value) values
('conta_recebimento', '{
  "titular": "",
  "cnpj": "",
  "banco": "",
  "agencia": "",
  "conta": "",
  "tipo": "Conta Corrente",
  "pix": "",
  "obs": ""
}'::jsonb)
on conflict (key) do nothing;
