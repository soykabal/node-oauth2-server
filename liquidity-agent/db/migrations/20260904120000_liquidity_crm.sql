-- =============================================================================
-- Kabal · Agente de Liquidez — CRM / Funnel de proveedores de liquidez
-- Migración: 20260904120000_liquidity_crm
--
-- Lado DEMANDA del ecosistema: quién pone el capital (family offices, fondos,
-- HNWI, bancos, fintech lenders, tesorerías corporativas) para el KTFT, las
-- emisiones B2B de Kabal Bridge y las líneas de fondeo de Kabal Lending.
-- Es el espejo de bridge_leads (lado OFERTA: quién trae el activo).
--
-- Convenciones (mismas que bridge_*): nombres en español, estados como text +
-- CHECK, uuid pk, created_at/updated_at, RLS con política para authenticated.
-- Prefijo: liq_
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. PROVEEDORES DE LIQUIDEZ (la "cuenta" del CRM)
-- -----------------------------------------------------------------------------
create table if not exists public.liq_proveedores (
  id                  uuid primary key default gen_random_uuid(),
  nombre              text not null unique,
  tipo                text not null default 'family_office'
                      check (tipo in ('family_office','fondo','hnwi','banco','fintech_lender',
                                      'tesoreria_corporativa','dao_defi','multilateral','otro')),
  pais                text,
  ticket_min_usd      numeric check (ticket_min_usd is null or ticket_min_usd >= 0),
  ticket_max_usd      numeric check (ticket_max_usd is null or ticket_max_usd >= 0),
  vehiculos           text[] not null default '{}',   -- ktft | emision_b2b | linea_credito | warehouse | deuda_privada | equity_no (nunca mezclar con ronda)
  yield_objetivo_pct  numeric,
  horizonte_meses     integer check (horizonte_meses is null or horizonte_meses > 0),
  moneda_preferida    text not null default 'USD' check (moneda_preferida in ('USD','USDC','HNL')),
  decisor             text,
  contacto_email      text,
  telefono            text,
  kyc_estado          text not null default 'pendiente'
                      check (kyc_estado in ('pendiente','en_proceso','verde','rojo')),
  kyc_fecha           date,
  inversionista_calificado boolean not null default false,  -- umbral LEAD (USD 500K) cuando aplique
  calificacion        text not null default 'EXPLORE' check (calificacion in ('GO','EXPLORE','DROP')),
  fuente              text default 'referido',
  notas               text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  constraint liq_prov_ticket_rango check (ticket_min_usd is null or ticket_max_usd is null or ticket_min_usd <= ticket_max_usd)
);

comment on table public.liq_proveedores is 'Proveedores de liquidez (inversionistas/fondeadores) gestionados por el Agente de Liquidez.';

-- -----------------------------------------------------------------------------
-- 2. OPORTUNIDADES (el funnel: un proveedor × un vehículo/emisión)
-- -----------------------------------------------------------------------------
create table if not exists public.liq_oportunidades (
  id                      uuid primary key default gen_random_uuid(),
  proveedor_id            uuid not null references public.liq_proveedores(id) on delete cascade,
  emision_id              uuid references public.bridge_emisiones(id) on delete set null,
  nombre                  text not null,
  vehiculo                text not null default 'ktft'
                          check (vehiculo in ('ktft','emision_b2b','linea_credito','warehouse','deuda_privada')),
  moneda                  text not null default 'USD' check (moneda in ('USD','USDC','HNL')),
  monto_objetivo_usd      numeric not null check (monto_objetivo_usd > 0),
  monto_comprometido_usd  numeric not null default 0 check (monto_comprometido_usd >= 0),
  monto_firmado_usd       numeric not null default 0 check (monto_firmado_usd >= 0),
  etapa                   text not null default 'identificado'
                          check (etapa in ('identificado','contactado','primera_reunion','segunda_reunion',
                                           'due_diligence','compromiso_verbal','firmado','wired',
                                           'perdido','nurture')),
  etapa_desde             timestamptz not null default now(),
  probabilidad_pct        integer not null default 10 check (probabilidad_pct between 0 and 100),
  owner                   text default 'CEO',
  proximo_paso            text,
  fecha_proximo_paso      date,
  fecha_compromiso_verbal date,
  fecha_firma             date,
  fecha_cierre_esperada   date,
  motivo_perdida          text,
  notas                   text,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

create index if not exists liq_oport_proveedor_idx on public.liq_oportunidades(proveedor_id);
create index if not exists liq_oport_etapa_idx     on public.liq_oportunidades(etapa);
create index if not exists liq_oport_emision_idx   on public.liq_oportunidades(emision_id);

comment on table public.liq_oportunidades is 'Funnel del Agente de Liquidez: IDENTIFICADO → CONTACTADO → 1ª REUNIÓN → 2ª/SOCIOS → DD → COMPROMISO VERBAL → FIRMADO → WIRED.';

-- -----------------------------------------------------------------------------
-- 3. INTERACCIONES (bitácora de contacto)
-- -----------------------------------------------------------------------------
create table if not exists public.liq_interacciones (
  id              uuid primary key default gen_random_uuid(),
  proveedor_id    uuid not null references public.liq_proveedores(id) on delete cascade,
  oportunidad_id  uuid references public.liq_oportunidades(id) on delete set null,
  tipo            text not null default 'email'
                  check (tipo in ('email','llamada','reunion','whatsapp','evento','documento','nota')),
  fecha           timestamptz not null default now(),
  resumen         text,
  resultado       text,
  siguiente_accion text,
  creado_por      text,
  created_at      timestamptz not null default now()
);

create index if not exists liq_inter_proveedor_idx on public.liq_interacciones(proveedor_id, fecha desc);
create index if not exists liq_inter_oport_idx     on public.liq_interacciones(oportunidad_id, fecha desc);

-- -----------------------------------------------------------------------------
-- 4. DESEMBOLSOS / WIRES (capital efectivamente recibido)
-- -----------------------------------------------------------------------------
create table if not exists public.liq_desembolsos (
  id              uuid primary key default gen_random_uuid(),
  oportunidad_id  uuid not null references public.liq_oportunidades(id) on delete cascade,
  fecha           date not null default current_date,
  monto_usd       numeric not null check (monto_usd > 0),
  moneda          text not null default 'USD' check (moneda in ('USD','USDC','HNL')),
  referencia      text,          -- swift ref / tx hash
  cuenta_destino  text,          -- entidad receptora (Kabal Bridge SV, KTF PA, etc.)
  verificado      boolean not null default false,
  notas           text,
  created_at      timestamptz not null default now()
);

create index if not exists liq_desemb_oport_idx on public.liq_desembolsos(oportunidad_id);

-- -----------------------------------------------------------------------------
-- 5. HISTORIAL DE ETAPAS (auditoría del funnel, lo llena un trigger)
-- -----------------------------------------------------------------------------
create table if not exists public.liq_etapa_historial (
  id              uuid primary key default gen_random_uuid(),
  oportunidad_id  uuid not null references public.liq_oportunidades(id) on delete cascade,
  etapa_anterior  text,
  etapa_nueva     text not null,
  dias_en_anterior numeric,
  motivo          text,
  cambiado_en     timestamptz not null default now()
);

create index if not exists liq_hist_oport_idx on public.liq_etapa_historial(oportunidad_id, cambiado_en desc);

-- -----------------------------------------------------------------------------
-- 6. FUNCIONES Y TRIGGERS
-- -----------------------------------------------------------------------------
create or replace function public.liq_touch_updated_at()
returns trigger language plpgsql set search_path = public as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists liq_prov_touch on public.liq_proveedores;
create trigger liq_prov_touch before update on public.liq_proveedores
  for each row execute function public.liq_touch_updated_at();

drop trigger if exists liq_oport_touch on public.liq_oportunidades;
create trigger liq_oport_touch before update on public.liq_oportunidades
  for each row execute function public.liq_touch_updated_at();

-- Probabilidad por defecto según etapa (se puede sobreescribir a mano)
create or replace function public.liq_probabilidad_default(p_etapa text)
returns integer language sql immutable set search_path = public as $$
  select case p_etapa
    when 'identificado'      then 5
    when 'contactado'        then 10
    when 'primera_reunion'   then 20
    when 'segunda_reunion'   then 35
    when 'due_diligence'     then 50
    when 'compromiso_verbal' then 70
    when 'firmado'           then 90
    when 'wired'             then 100
    when 'nurture'           then 5
    else 0 end;
$$;

-- Guardas de negocio al cambiar de etapa:
--  * KYC antes del wire: nadie llega a 'wired' sin kyc_estado = 'verde' (regla dura).
--  * Al entrar a compromiso_verbal se fija la fecha (para la regla de degradación >14 días).
--  * Al entrar a firmado se fija fecha_firma y monto_firmado >= comprometido si venía en 0.
--  * Se registra el historial y se reinicia etapa_desde.
create or replace function public.liq_oport_before_change()
returns trigger language plpgsql set search_path = public as $$
declare
  v_kyc text;
begin
  if tg_op = 'INSERT' then
    if new.probabilidad_pct = 10 then
      new.probabilidad_pct := public.liq_probabilidad_default(new.etapa);
    end if;
    return new;
  end if;

  if new.etapa is distinct from old.etapa then
    if new.etapa = 'wired' then
      select kyc_estado into v_kyc from public.liq_proveedores where id = new.proveedor_id;
      if v_kyc is distinct from 'verde' then
        raise exception 'LIQ_KYC_REQUERIDO: el proveedor % no tiene KYC en verde (estado: %). Ningún cierre avanza a wired sin KYC.', new.proveedor_id, v_kyc;
      end if;
    end if;

    if new.etapa = 'compromiso_verbal' and new.fecha_compromiso_verbal is null then
      new.fecha_compromiso_verbal := current_date;
    end if;
    if new.etapa = 'firmado' then
      if new.fecha_firma is null then new.fecha_firma := current_date; end if;
      if new.monto_firmado_usd = 0 then new.monto_firmado_usd := coalesce(nullif(new.monto_comprometido_usd,0), new.monto_objetivo_usd); end if;
    end if;
    if new.etapa = 'perdido' and new.motivo_perdida is null then
      raise exception 'LIQ_MOTIVO_REQUERIDO: registrá motivo_perdida (es el checklist de la Serie A).';
    end if;

    -- si nadie tocó la probabilidad, adoptar la de la etapa nueva
    if new.probabilidad_pct = old.probabilidad_pct then
      new.probabilidad_pct := public.liq_probabilidad_default(new.etapa);
    end if;
    new.etapa_desde := now();
  end if;
  return new;
end $$;

drop trigger if exists liq_oport_before_change on public.liq_oportunidades;
create trigger liq_oport_before_change before insert or update on public.liq_oportunidades
  for each row execute function public.liq_oport_before_change();

create or replace function public.liq_oport_log_etapa()
returns trigger language plpgsql set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    insert into public.liq_etapa_historial(oportunidad_id, etapa_anterior, etapa_nueva)
    values (new.id, null, new.etapa);
  elsif new.etapa is distinct from old.etapa then
    insert into public.liq_etapa_historial(oportunidad_id, etapa_anterior, etapa_nueva, dias_en_anterior, motivo)
    values (new.id, old.etapa, new.etapa,
            round(extract(epoch from (now() - old.etapa_desde)) / 86400.0, 1),
            case when new.etapa = 'perdido' then new.motivo_perdida else null end);
  end if;
  return new;
end $$;

drop trigger if exists liq_oport_log_etapa on public.liq_oportunidades;
create trigger liq_oport_log_etapa after insert or update on public.liq_oportunidades
  for each row execute function public.liq_oport_log_etapa();

-- Un wire verificado que cubre lo firmado mueve la oportunidad a 'wired' automáticamente.
create or replace function public.liq_desembolso_after_insert()
returns trigger language plpgsql set search_path = public as $$
declare
  v_total numeric;
  v_firmado numeric;
  v_etapa text;
begin
  select coalesce(sum(monto_usd),0) into v_total
    from public.liq_desembolsos where oportunidad_id = new.oportunidad_id and verificado;
  select monto_firmado_usd, etapa into v_firmado, v_etapa
    from public.liq_oportunidades where id = new.oportunidad_id;
  if new.verificado and v_firmado > 0 and v_total >= v_firmado and v_etapa <> 'wired' then
    update public.liq_oportunidades set etapa = 'wired' where id = new.oportunidad_id;
  end if;
  return new;
end $$;

drop trigger if exists liq_desembolso_after_insert on public.liq_desembolsos;
create trigger liq_desembolso_after_insert after insert or update on public.liq_desembolsos
  for each row execute function public.liq_desembolso_after_insert();

-- -----------------------------------------------------------------------------
-- 7. VISTAS DEL FUNNEL
-- -----------------------------------------------------------------------------

-- Pipeline activo con días en etapa, wired real y banderas SLA.
create or replace view public.liq_v_pipeline as
select
  o.id,
  o.nombre,
  p.nombre                                   as proveedor,
  p.tipo                                     as tipo_proveedor,
  p.pais,
  p.kyc_estado,
  o.vehiculo,
  o.etapa,
  o.probabilidad_pct,
  o.monto_objetivo_usd,
  o.monto_comprometido_usd,
  o.monto_firmado_usd,
  coalesce(d.wired_usd, 0)                   as monto_wired_usd,
  round(o.monto_objetivo_usd * o.probabilidad_pct / 100.0, 2) as monto_ponderado_usd,
  o.owner,
  o.proximo_paso,
  o.fecha_proximo_paso,
  o.fecha_compromiso_verbal,
  o.fecha_cierre_esperada,
  o.etapa_desde,
  round(extract(epoch from (now() - o.etapa_desde)) / 86400.0, 1) as dias_en_etapa,
  i.ultima_interaccion,
  round(extract(epoch from (now() - coalesce(i.ultima_interaccion, o.created_at))) / 86400.0, 1) as dias_sin_contacto,
  -- Regla: todo nombre vivo tiene próximo paso con fecha, o no existe.
  (o.proximo_paso is null or o.fecha_proximo_paso is null)                as alerta_sin_proximo_paso,
  (o.fecha_proximo_paso is not null and o.fecha_proximo_paso < current_date) as alerta_paso_vencido,
  -- Regla H: compromiso verbal > 14 días sin firma ⇒ proponer degradar.
  (o.etapa = 'compromiso_verbal' and o.fecha_compromiso_verbal is not null
     and current_date - o.fecha_compromiso_verbal > 14)                    as alerta_degradar,
  -- KYC antes del wire: firmado sin KYC verde es bloqueo inminente.
  (o.etapa in ('due_diligence','compromiso_verbal','firmado') and p.kyc_estado <> 'verde') as alerta_kyc,
  o.created_at,
  o.updated_at
from public.liq_oportunidades o
join public.liq_proveedores p on p.id = o.proveedor_id
left join lateral (
  select sum(monto_usd) as wired_usd from public.liq_desembolsos x
  where x.oportunidad_id = o.id and x.verificado
) d on true
left join lateral (
  select max(fecha) as ultima_interaccion from public.liq_interacciones y
  where y.oportunidad_id = o.id or (y.oportunidad_id is null and y.proveedor_id = o.proveedor_id)
) i on true
where o.etapa not in ('perdido');

-- Funnel: conteo y $ por etapa (ordenado por el orden natural del embudo).
create or replace view public.liq_v_funnel as
with etapas as (
  select * from (values
    ('identificado',1),('contactado',2),('primera_reunion',3),('segunda_reunion',4),
    ('due_diligence',5),('compromiso_verbal',6),('firmado',7),('wired',8),('nurture',9),('perdido',10)
  ) as e(etapa, orden)
)
select
  e.orden,
  e.etapa,
  count(o.id)                                            as oportunidades,
  coalesce(sum(o.monto_objetivo_usd),0)                  as monto_objetivo_usd,
  coalesce(sum(o.monto_comprometido_usd),0)              as monto_comprometido_usd,
  coalesce(sum(o.monto_firmado_usd),0)                   as monto_firmado_usd,
  coalesce(sum(d.wired_usd),0)                           as monto_wired_usd,
  coalesce(sum(o.monto_objetivo_usd * o.probabilidad_pct / 100.0),0) as monto_ponderado_usd
from etapas e
left join public.liq_oportunidades o on o.etapa = e.etapa
left join lateral (
  select sum(monto_usd) as wired_usd from public.liq_desembolsos x
  where x.oportunidad_id = o.id and x.verificado
) d on true
group by e.orden, e.etapa
order by e.orden;

-- Resumen por vehículo: comprometido vs firmado vs wired (el "lunes de liquidez").
create or replace view public.liq_v_resumen_vehiculo as
select
  o.vehiculo,
  count(*) filter (where o.etapa not in ('perdido','nurture'))          as activas,
  coalesce(sum(o.monto_objetivo_usd) filter (where o.etapa not in ('perdido','nurture')),0) as pipeline_usd,
  coalesce(sum(o.monto_objetivo_usd * o.probabilidad_pct / 100.0)
           filter (where o.etapa not in ('perdido','nurture','wired')),0) as ponderado_usd,
  coalesce(sum(o.monto_comprometido_usd) filter (where o.etapa in ('compromiso_verbal','firmado','wired')),0) as comprometido_usd,
  coalesce(sum(o.monto_firmado_usd)      filter (where o.etapa in ('firmado','wired')),0) as firmado_usd,
  coalesce(sum(d.wired_usd),0)                                            as wired_usd
from public.liq_oportunidades o
left join lateral (
  select sum(monto_usd) as wired_usd from public.liq_desembolsos x
  where x.oportunidad_id = o.id and x.verificado
) d on true
group by o.vehiculo
order by pipeline_usd desc;

-- Resumen por proveedor (cuenta 360).
create or replace view public.liq_v_proveedor_resumen as
select
  p.id,
  p.nombre,
  p.tipo,
  p.pais,
  p.kyc_estado,
  p.calificacion,
  p.vehiculos,
  count(o.id)                                                       as oportunidades,
  count(o.id) filter (where o.etapa not in ('perdido','nurture','wired')) as activas,
  coalesce(sum(o.monto_objetivo_usd) filter (where o.etapa not in ('perdido','nurture')),0) as pipeline_usd,
  coalesce(sum(o.monto_firmado_usd) filter (where o.etapa in ('firmado','wired')),0) as firmado_usd,
  coalesce(sum(d.wired_usd),0)                                      as wired_usd,
  max(i.fecha)                                                      as ultima_interaccion,
  p.updated_at
from public.liq_proveedores p
left join public.liq_oportunidades o on o.proveedor_id = p.id
left join lateral (
  select sum(monto_usd) as wired_usd from public.liq_desembolsos x
  where x.oportunidad_id = o.id and x.verificado
) d on true
left join public.liq_interacciones i on i.proveedor_id = p.id
group by p.id;

-- Motivos de pérdida (checklist para la siguiente ronda).
create or replace view public.liq_v_motivos_perdida as
select
  coalesce(nullif(trim(o.motivo_perdida),''),'(sin motivo)') as motivo,
  count(*)                                                    as casos,
  coalesce(sum(o.monto_objetivo_usd),0)                       as monto_usd
from public.liq_oportunidades o
where o.etapa = 'perdido'
group by 1
order by casos desc, monto_usd desc;

-- -----------------------------------------------------------------------------
-- 8. RPC: mover de etapa con motivo (una sola llamada desde el agente)
-- -----------------------------------------------------------------------------
create or replace function public.liq_mover_etapa(
  p_oportunidad_id uuid,
  p_etapa text,
  p_motivo text default null,
  p_proximo_paso text default null,
  p_fecha_proximo_paso date default null,
  p_monto_comprometido_usd numeric default null
) returns public.liq_oportunidades
language plpgsql security invoker set search_path = public as $$
declare
  v_row public.liq_oportunidades;
begin
  update public.liq_oportunidades
     set etapa = p_etapa,
         motivo_perdida = case when p_etapa = 'perdido' then coalesce(p_motivo, motivo_perdida) else motivo_perdida end,
         proximo_paso = coalesce(p_proximo_paso, proximo_paso),
         fecha_proximo_paso = coalesce(p_fecha_proximo_paso, fecha_proximo_paso),
         monto_comprometido_usd = coalesce(p_monto_comprometido_usd, monto_comprometido_usd)
   where id = p_oportunidad_id
   returning * into v_row;
  if v_row.id is null then
    raise exception 'LIQ_NO_ENCONTRADA: oportunidad % no existe', p_oportunidad_id;
  end if;
  if p_motivo is not null and p_etapa <> 'perdido' then
    update public.liq_etapa_historial set motivo = p_motivo
     where id = (select id from public.liq_etapa_historial
                  where oportunidad_id = p_oportunidad_id order by cambiado_en desc limit 1);
  end if;
  return v_row;
end $$;

-- -----------------------------------------------------------------------------
-- 9. RLS (misma política que bridge_*: equipo autenticado)
-- -----------------------------------------------------------------------------
alter table public.liq_proveedores     enable row level security;
alter table public.liq_oportunidades   enable row level security;
alter table public.liq_interacciones   enable row level security;
alter table public.liq_desembolsos     enable row level security;
alter table public.liq_etapa_historial enable row level security;

drop policy if exists liq_prov_auth   on public.liq_proveedores;
drop policy if exists liq_oport_auth  on public.liq_oportunidades;
drop policy if exists liq_inter_auth  on public.liq_interacciones;
drop policy if exists liq_desemb_auth on public.liq_desembolsos;
drop policy if exists liq_hist_auth   on public.liq_etapa_historial;

create policy liq_prov_auth   on public.liq_proveedores     for all to authenticated using (true) with check (true);
create policy liq_oport_auth  on public.liq_oportunidades   for all to authenticated using (true) with check (true);
create policy liq_inter_auth  on public.liq_interacciones   for all to authenticated using (true) with check (true);
create policy liq_desemb_auth on public.liq_desembolsos     for all to authenticated using (true) with check (true);
create policy liq_hist_auth   on public.liq_etapa_historial for all to authenticated using (true) with check (true);

-- Las vistas corren con los permisos del que consulta (respetan RLS).
alter view public.liq_v_pipeline          set (security_invoker = true);
alter view public.liq_v_funnel            set (security_invoker = true);
alter view public.liq_v_resumen_vehiculo  set (security_invoker = true);
alter view public.liq_v_proveedor_resumen set (security_invoker = true);
alter view public.liq_v_motivos_perdida   set (security_invoker = true);
