-- Smoke test del esquema liq_* (correr contra un Postgres local vacío con el
-- stub de abajo, NUNCA contra producción). Falla con RAISE si algo se rompe.
begin;

-- Stubs mínimos del entorno Supabase
do $$ begin
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin;
  end if;
end $$;
create table if not exists public.bridge_emisiones (id uuid primary key default gen_random_uuid(), nombre text);

\i liquidity-agent/db/migrations/20260904120000_liquidity_crm.sql

-- ---------------------------------------------------------------------------
-- Escenario
-- ---------------------------------------------------------------------------
insert into public.liq_proveedores (nombre, tipo, pais, ticket_min_usd, ticket_max_usd, vehiculos, decisor, contacto_email)
values ('FO Prueba', 'family_office', 'Panamá', 250000, 2000000, '{ktft,emision_b2b}', 'Ana Decisora', 'ana@example.com');

insert into public.liq_oportunidades (proveedor_id, nombre, vehiculo, monto_objetivo_usd, proximo_paso, fecha_proximo_paso)
select id, 'FO Prueba · KTFT 1ª emisión', 'ktft', 500000, 'Enviar whitepaper', current_date + 2 from public.liq_proveedores where nombre = 'FO Prueba';

-- probabilidad default por etapa en INSERT
do $$ declare v int; begin
  select probabilidad_pct into v from public.liq_oportunidades where nombre like 'FO Prueba%';
  if v <> 5 then raise exception 'probabilidad default esperada 5, obtuve %', v; end if;
end $$;

-- historial registra el insert
do $$ declare n int; begin
  select count(*) into n from public.liq_etapa_historial;
  if n <> 1 then raise exception 'historial esperaba 1 fila, obtuve %', n; end if;
end $$;

-- mover por el funnel con la RPC
select public.liq_mover_etapa(id, 'contactado', null, 'Agendar 1ª reunión', current_date + 3) from public.liq_oportunidades;
select public.liq_mover_etapa(id, 'primera_reunion') from public.liq_oportunidades;
select public.liq_mover_etapa(id, 'due_diligence') from public.liq_oportunidades;
select public.liq_mover_etapa(id, 'compromiso_verbal', null, 'Enviar subscription agreement', current_date + 1, 400000) from public.liq_oportunidades;

do $$ declare r record; begin
  select * into r from public.liq_oportunidades limit 1;
  if r.fecha_compromiso_verbal <> current_date then raise exception 'fecha_compromiso_verbal no se fijó'; end if;
  if r.probabilidad_pct <> 70 then raise exception 'probabilidad esperada 70, obtuve %', r.probabilidad_pct; end if;
  if r.monto_comprometido_usd <> 400000 then raise exception 'monto_comprometido esperado 400000'; end if;
end $$;

-- alerta_kyc en la vista (proveedor aún pendiente)
do $$ declare b boolean; begin
  select alerta_kyc into b from public.liq_v_pipeline limit 1;
  if not b then raise exception 'alerta_kyc debía ser true'; end if;
end $$;

-- firmado fija fecha_firma y monto_firmado = comprometido
select public.liq_mover_etapa(id, 'firmado') from public.liq_oportunidades;
do $$ declare r record; begin
  select * into r from public.liq_oportunidades limit 1;
  if r.fecha_firma is null or r.monto_firmado_usd <> 400000 then raise exception 'firmado no fijó fecha/monto'; end if;
end $$;

-- KYC antes del wire: debe fallar
do $$ declare ok boolean := false; begin
  begin
    perform public.liq_mover_etapa(id, 'wired') from public.liq_oportunidades;
  exception when others then
    if sqlerrm like 'LIQ_KYC_REQUERIDO%' then ok := true; else raise; end if;
  end;
  if not ok then raise exception 'wired sin KYC verde debía fallar'; end if;
end $$;

-- KYC verde + wire verificado que cubre lo firmado ⇒ etapa wired automática
update public.liq_proveedores set kyc_estado = 'verde', kyc_fecha = current_date;
insert into public.liq_desembolsos (oportunidad_id, monto_usd, moneda, referencia, verificado)
select id, 400000, 'USDC', '0xabc', true from public.liq_oportunidades;

do $$ declare r record; begin
  select * into r from public.liq_v_pipeline limit 1;
  if r.etapa <> 'wired' then raise exception 'esperaba wired, obtuve %', r.etapa; end if;
  if r.monto_wired_usd <> 400000 then raise exception 'wired usd esperado 400000, obtuve %', r.monto_wired_usd; end if;
  if r.probabilidad_pct <> 100 then raise exception 'probabilidad esperada 100'; end if;
end $$;

-- perdido exige motivo
insert into public.liq_oportunidades (proveedor_id, nombre, vehiculo, monto_objetivo_usd)
select id, 'FO Prueba · Línea warehouse', 'warehouse', 1000000 from public.liq_proveedores;
do $$ declare ok boolean := false; begin
  begin
    update public.liq_oportunidades set etapa = 'perdido' where nombre like '%warehouse%';
  exception when others then
    if sqlerrm like 'LIQ_MOTIVO_REQUERIDO%' then ok := true; else raise; end if;
  end;
  if not ok then raise exception 'perdido sin motivo debía fallar'; end if;
end $$;
select public.liq_mover_etapa(id, 'perdido', 'Ticket mínimo fuera de rango') from public.liq_oportunidades where nombre like '%warehouse%';

-- vistas responden
select etapa, oportunidades, monto_objetivo_usd, monto_wired_usd from public.liq_v_funnel;
select vehiculo, activas, pipeline_usd, firmado_usd, wired_usd from public.liq_v_resumen_vehiculo;
select nombre, oportunidades, wired_usd from public.liq_v_proveedor_resumen;
select * from public.liq_v_motivos_perdida;
select etapa_anterior, etapa_nueva, motivo from public.liq_etapa_historial order by cambiado_en;

-- RLS activo en todas
do $$ declare n int; begin
  select count(*) into n from pg_tables where schemaname='public' and tablename like 'liq\_%' and rowsecurity;
  if n <> 5 then raise exception 'RLS esperado en 5 tablas, obtuve %', n; end if;
end $$;

select 'SMOKE OK' as resultado;
rollback;
