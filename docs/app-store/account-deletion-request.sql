-- Account deletion requests from Atfood (Apple guideline 5.1.1(v): deletion must be started inside the app).
-- An owner cannot be removed at once: the restaurant (and its Stripe subscription) goes with the account.
-- The app records a request here; the Attabl team closes the restaurant and deletes the account within 30 days.
-- Additive only: one new table, one new function. Nothing existing is changed.
-- Each new request also raises a notification for the platform operators in the web dashboard.

create table if not exists public.account_deletion_requests (
  user_id      uuid primary key references auth.users(id) on delete cascade,
  email        text not null,
  restaurants  text not null default '',
  requested_at timestamptz not null default now(),
  processed_at timestamptz
);

-- No policy on purpose: only the function below (security definer) and the service role can read or write.
alter table public.account_deletion_requests enable row level security;
revoke all on public.account_deletion_requests from anon, authenticated;

create or replace function public.request_account_deletion()
returns text
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    return 'not_authenticated';
  end if;
  insert into account_deletion_requests (user_id, email, restaurants)
  select v_uid,
         (select email from auth.users where id = v_uid),
         coalesce((select string_agg(t.name, ', ' order by t.name)
                   from admin_users au join tenants t on t.id = au.tenant_id
                   where au.user_id = v_uid), '')
  on conflict (user_id) do nothing;   -- asking twice keeps the first request and its date

  -- New request only: alert the platform operators in the web dashboard bell (their eyes only).
  if found then
    insert into notifications (tenant_id, user_id, type, title, body, read)
    select op.tenant_id, op.user_id, 'info', 'Demande de suppression de compte',
           r.email || case when r.restaurants <> '' then ' (' || r.restaurants || ')' else '' end
             || '. A traiter sous 30 jours : table account_deletion_requests.',
           false
    from admin_users op, account_deletion_requests r
    where r.user_id = v_uid
      and (op.is_super_admin is true or op.role = 'super_admin')
      and op.is_active is true and op.tenant_id is not null;
  end if;
  return 'requested';
end;
$$;

revoke all on function public.request_account_deletion() from public, anon;
grant execute on function public.request_account_deletion() to authenticated;

-- To process: select * from account_deletion_requests where processed_at is null order by requested_at;
-- Undo: drop function public.request_account_deletion(); drop table public.account_deletion_requests;
