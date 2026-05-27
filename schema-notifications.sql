-- ══════════════════════════════════════════════════════════
-- MUTUAL PAY OTC — Schema de Notificações
-- Cole no SQL Editor do Supabase e execute
-- ══════════════════════════════════════════════════════════

-- 1. Adicionar email ao profiles (para notificar parceiros)
alter table public.profiles add column if not exists email text;

-- 2. Atualizar trigger para capturar email no signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, name, company, whatsapp, role, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', new.email),
    coalesce(new.raw_user_meta_data->>'company', ''),
    coalesce(new.raw_user_meta_data->>'whatsapp', ''),
    coalesce(new.raw_user_meta_data->>'role', 'partner'),
    new.email
  )
  on conflict (id) do update set email = excluded.email;
  return new;
end;
$$;

-- 3. Atualizar email do trader existente (roda uma vez)
update public.profiles p
set email = u.email
from auth.users u
where p.id = u.id and p.email is null;

-- 4. Tabela de notificações
create table if not exists public.notifications (
  id            uuid default gen_random_uuid() primary key,
  operation_id  uuid references public.operations(id) on delete cascade,
  op_id         text,
  type          text not null,     -- status_change | missing_info | new_operation | client_response
  recipient     text not null,     -- partner | trader
  recipient_name     text,
  recipient_email    text,
  recipient_whatsapp text,
  subject       text,
  message       text,
  sent_whatsapp boolean default false,
  sent_email    boolean default false,
  created_at    timestamptz default now()
);

alter table public.notifications enable row level security;

-- Trader vê e gerencia todas as notificações
create policy "Trader acessa todas notificações"
  on public.notifications for all
  using (public.is_trader());

-- Parceiro lê notificações das suas próprias operações
create policy "Parceiro lê notificações das suas operações"
  on public.notifications for select
  using (
    operation_id in (
      select id from public.operations where partner_id = auth.uid()
    )
  );

-- Qualquer usuário autenticado pode inserir notificação
create policy "Usuário autenticado insere notificação"
  on public.notifications for insert
  with check (auth.uid() is not null);
