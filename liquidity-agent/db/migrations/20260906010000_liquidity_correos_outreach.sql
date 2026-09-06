-- =============================================================================
-- Kabal · Agente de Liquidez — outreach diario a instituciones GO (7/día)
-- =============================================================================
-- · El trigger de correos por etapa no regenera el correo de una etapa que ya
--   tiene borrador/enviado (el primer correo se prepara ANTES de mover la ficha
--   a 'contactado'; al enviarse, la ficha pasa a 'contactado' sin duplicar).
-- · liq_correos.adjuntos: adjuntos esperados (el tablero los anexa al crear el
--   borrador en Gmail; hoy el deck institucional KTFT en inglés).
-- · Config: firma del CEO, deck por defecto y tamaño del lote diario.
-- · Vista liq_v_correos_del_dia: el lote preparado hoy.
-- =============================================================================

create or replace function public.liq_oport_correo_etapa()
returns trigger language plpgsql set search_path = public as $$
declare
  r record;
  v_cc text;
begin
  if tg_op = 'UPDATE' and new.etapa is not distinct from old.etapa then return new; end if;
  if exists (select 1 from public.liq_correos
              where oportunidad_id = new.id and etapa = new.etapa and estado in ('borrador','enviado')) then
    return new;
  end if;
  select * into r from public.liq_render_correo(new.id, new.etapa);
  if r.asunto is null then return new; end if;
  select valor into v_cc from public.liq_correo_config where clave = 'cc_default';
  insert into public.liq_correos (oportunidad_id, proveedor_id, etapa, para, cc, asunto, cuerpo, estado)
  values (new.id, new.proveedor_id, new.etapa, r.para, v_cc, r.asunto, r.cuerpo,
          case when r.para is null then 'sin_correo' else 'pendiente' end)
  on conflict do nothing;
  return new;
end $$;

alter table public.liq_correos add column if not exists adjuntos jsonb not null default '[]'::jsonb;
comment on column public.liq_correos.adjuntos is 'Adjuntos esperados: [{"nombre":"...","drive_id":"...","mime":"application/pdf"}]. El tablero los adjunta al crear el borrador.';

insert into public.liq_correo_config (clave, valor) values
  ('firma', E'Guillermo Kattan\nCEO · Kabal\nKabal Bridge S.A. de C.V. · PSAD-0056 · San Salvador'),
  ('deck_ktft_en_drive_id', '1Jo6rq8ukZxPWeP-umLyz1ptEVgFC_FxG'),
  ('deck_ktft_en_nombre', 'KTFT_Institutional_Presentation_CNAD_EN.pdf'),
  ('outreach_diario_go', '7')
on conflict (clave) do update set valor = excluded.valor;

-- La vista de pendientes expone los adjuntos esperados (columna nueva → recrear)
drop view if exists public.liq_v_correos_pendientes;
create view public.liq_v_correos_pendientes as
select c.id, c.oportunidad_id, c.proveedor_id, c.etapa, c.estado, c.para, c.cc, c.asunto, c.cuerpo, c.adjuntos,
       c.creado_en, o.nombre as oportunidad, o.vehiculo, o.monto_objetivo_usd,
       p.nombre as proveedor, p.decisor, p.contacto_email,
       round(extract(epoch from (now() - c.creado_en)) / 86400.0, 1) as dias_esperando
  from public.liq_correos c
  join public.liq_oportunidades o on o.id = c.oportunidad_id
  join public.liq_proveedores p on p.id = c.proveedor_id
 where c.estado in ('pendiente','sin_correo')
 order by c.creado_en desc;
alter view public.liq_v_correos_pendientes set (security_invoker = true);

create or replace view public.liq_v_correos_del_dia as
select c.*, o.nombre as oportunidad, o.etapa as etapa_oportunidad, p.nombre as proveedor, p.tipo, p.pais, p.decisor
  from public.liq_correos c
  join public.liq_oportunidades o on o.id = c.oportunidad_id
  join public.liq_proveedores p on p.id = c.proveedor_id
 where c.creado_en::date = current_date
 order by c.creado_en;
alter view public.liq_v_correos_del_dia set (security_invoker = true);

-- -----------------------------------------------------------------------------
-- Rutina diaria (la ejecuta el agente, no la base):
--   1. Reconciliar: correos en 'borrador' cuyo draft ya no existe en Gmail → 'enviado',
--      ficha a 'contactado', próximo paso "Follow-up día 4".
--   2. Elegir los siguientes N (outreach_diario_go) proveedores GO sin oportunidad,
--      por monto_potencial_usd desc (excluye plataformas/infraestructura sin capital).
--   3. Crear oportunidad en 'identificado' + fila en liq_correos (etapa 'contactado',
--      primer correo en inglés personalizado, adjuntos = deck) en estado 'sin_correo'.
--   4. El CEO abre el tablero → «Correos» → «Crear borradores en Gmail con deck»:
--      quedan en Borradores con el PDF; solo pone la dirección y envía.
-- -----------------------------------------------------------------------------
