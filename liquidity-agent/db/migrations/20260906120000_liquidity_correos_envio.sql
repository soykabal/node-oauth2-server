-- =============================================================================
-- Kabal · Agente de Liquidez — envío = avance automático de la ficha; lote de 8
-- =============================================================================
-- · Al marcar un correo como 'enviado' (tablero, CLI o reconciliación diaria),
--   la ficha avanza sola a la etapa de ese correo si está más adelante que la
--   etapa actual, con próximo paso de seguimiento (primer correo → follow-up D+4).
--   Solo avanza hasta compromiso_verbal: firmado/wired siguen exigiendo la
--   acción humana (y la regla KYC) porque esos correos confirman, no abren.
-- · Lote diario de outreach: 8 instituciones GO por día.
-- · One-pager oficial (Drive, con logos, manual de marca) como adjunto del
--   primer contacto; el deck completo va en la llamada o bajo NDA.
-- =============================================================================

create or replace function public.liq_etapa_orden(p_etapa text)
returns int language sql immutable as $$
  select case p_etapa
    when 'identificado' then 1 when 'contactado' then 2 when 'primera_reunion' then 3
    when 'segunda_reunion' then 4 when 'due_diligence' then 5 when 'compromiso_verbal' then 6
    when 'firmado' then 7 when 'wired' then 8 else 0 end
$$;

create or replace function public.liq_correo_enviado_mueve()
returns trigger language plpgsql set search_path = public as $$
declare
  v_etapa_actual text;
  v_paso text;
  v_fecha date;
begin
  if new.estado <> 'enviado' or old.estado is not distinct from 'enviado' then return new; end if;
  if new.etapa not in ('contactado','primera_reunion','segunda_reunion','due_diligence','compromiso_verbal') then return new; end if;
  select etapa into v_etapa_actual from public.liq_oportunidades where id = new.oportunidad_id;
  if v_etapa_actual is null or v_etapa_actual in ('perdido','nurture') then return new; end if;
  if public.liq_etapa_orden(new.etapa) <= public.liq_etapa_orden(v_etapa_actual) then return new; end if;
  if new.etapa = 'contactado' then
    v_paso := 'Follow-up D+4 (bump corto) · D+10 aporte de valor · D+18 breakup';
    v_fecha := current_date + 4;
  else
    v_paso := 'Seguimiento del correo de ' || replace(new.etapa, '_', ' ');
    v_fecha := current_date + 3;
  end if;
  perform public.liq_mover_etapa(new.oportunidad_id, new.etapa, null, v_paso, v_fecha, null);
  return new;
end $$;

drop trigger if exists liq_correos_enviado_mueve on public.liq_correos;
create trigger liq_correos_enviado_mueve
  after update of estado on public.liq_correos
  for each row execute function public.liq_correo_enviado_mueve();

comment on function public.liq_correo_enviado_mueve() is
  'Correo enviado ⇒ la ficha avanza sola a la etapa del correo (hasta compromiso_verbal) con próximo paso de seguimiento.';

insert into public.liq_correo_config (clave, valor) values
  ('outreach_diario_go', '8'),
  ('onepager_ktft_en_drive_id', '1PrtDd71poYPuEFX82aZ1Mz9ls9MB5yvr'),
  ('onepager_ktft_en_nombre', 'Kabal_KTFT_Investor_OnePager_v4.pdf'),
  ('onepager_ktft_en_origen', 'Drive: 03_KTFT_Investor_OnePager_v4.pdf (one-pager oficial con logos, manual de marca)')
on conflict (clave) do update set valor = excluded.valor;
