-- Monto potencial por institución (ticket plausible para los vehículos de Kabal).
-- Estimación inicial por tipo × calificación; se ajusta a mano tras el primer contacto.
-- (aplicada en Supabase como liquidity_agent_monto_potencial)
alter table public.liq_proveedores
  add column if not exists monto_potencial_usd numeric check (monto_potencial_usd is null or monto_potencial_usd >= 0),
  add column if not exists monto_potencial_origen text default 'estimado_por_tipo';  -- estimado_por_tipo | confirmado | manual

create or replace function public.liq_monto_potencial_default(p_tipo text, p_calificacion text)
returns numeric language sql immutable set search_path = public as $$
  select case p_tipo
    when 'banco'                 then case when p_calificacion='GO' then 5000000 else 3000000 end
    when 'multilateral'          then case when p_calificacion='GO' then 5000000 else 3000000 end
    when 'soberano'              then case when p_calificacion='GO' then 5000000 else 2500000 end
    when 'gestor_activos'        then case when p_calificacion='GO' then 3000000 else 1500000 end
    when 'fondo'                 then case when p_calificacion='GO' then 2000000 else 1000000 end
    when 'banca_inversion'       then case when p_calificacion='GO' then 2000000 else 1000000 end
    when 'dao_defi'              then case when p_calificacion='GO' then 1500000 else  500000 end
    when 'aseguradora'           then case when p_calificacion='GO' then 1000000 else  500000 end
    when 'corporativo'           then case when p_calificacion='GO' then 1000000 else  500000 end
    when 'family_office'         then case when p_calificacion='GO' then 1000000 else  500000 end
    when 'fintech_lender'        then case when p_calificacion='GO' then 1000000 else  500000 end
    when 'tesoreria_corporativa' then case when p_calificacion='GO' then 1000000 else  500000 end
    when 'market_maker'          then case when p_calificacion='GO' then  500000 else  250000 end
    when 'exchange'              then case when p_calificacion='GO' then  500000 else  250000 end
    when 'hnwi'                  then case when p_calificacion='GO' then  250000 else  100000 end
    else null  -- plataforma_tokenizacion, custodio, infraestructura, otro: no aportan capital
  end;
$$;

update public.liq_proveedores
   set monto_potencial_usd = public.liq_monto_potencial_default(tipo, calificacion),
       monto_potencial_origen = 'estimado_por_tipo'
 where monto_potencial_usd is null;

-- Vista: potencial del directorio por tipo
create or replace view public.liq_v_potencial_directorio as
select tipo,
       count(*)                                                    as instituciones,
       count(*) filter (where calificacion='GO')                   as go,
       count(*) filter (where monto_potencial_usd > 0)             as con_capital,
       coalesce(sum(monto_potencial_usd),0)                        as potencial_usd,
       coalesce(sum(monto_potencial_usd) filter (where calificacion='GO'),0) as potencial_go_usd
  from public.liq_proveedores
 group by tipo
 order by potencial_usd desc;
alter view public.liq_v_potencial_directorio set (security_invoker = true);
