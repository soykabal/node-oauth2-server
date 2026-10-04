-- =============================================================================
-- Kabal · Agente de Liquidez — correos automáticos al mover de etapa
-- =============================================================================
-- Al cambiar `liq_oportunidades.etapa`, un trigger genera el correo de esa etapa
-- (plantilla por etapa con placeholders) y lo deja en la cola `liq_correos`:
--   · estado 'pendiente'  → el proveedor tiene contacto_email: listo para Gmail.
--   · estado 'sin_correo' → falta la dirección; en cuanto se guarda
--     `liq_proveedores.contacto_email`, otro trigger lo pasa a 'pendiente'.
-- El tablero (o el CLI) toma el correo pendiente, lo abre en Gmail como borrador
-- o lo envía, y lo marca con `liq_correo_marcar(...)`, que además registra la
-- interacción en la bitácora. Nada se envía desde la base: la base prepara.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Configuración mínima (firma, cc por defecto)
-- -----------------------------------------------------------------------------
create table if not exists public.liq_correo_config (
  clave  text primary key,
  valor  text
);
comment on table public.liq_correo_config is 'Ajustes de los correos del Agente de Liquidez (firma, cc por defecto, remitente).';

insert into public.liq_correo_config (clave, valor) values
  ('firma',        E'Equipo Kabal\nKabal Bridge · PSAD-0056 · San Salvador'),
  ('cc_default',   null),
  ('idioma',       'es')
on conflict (clave) do nothing;

-- -----------------------------------------------------------------------------
-- 2. Plantillas por etapa
--    Placeholders: {{decisor}} {{proveedor}} {{oportunidad}} {{vehiculo}} {{monto}}
--                  {{proximo_paso}} {{fecha_proximo_paso}} {{firma}}
-- -----------------------------------------------------------------------------
create table if not exists public.liq_plantillas_correo (
  etapa       text primary key
              check (etapa in ('identificado','contactado','primera_reunion','segunda_reunion',
                               'due_diligence','compromiso_verbal','firmado','wired','nurture','perdido')),
  activa      boolean not null default true,
  asunto      text not null,
  cuerpo      text not null,
  updated_at  timestamptz not null default now()
);
comment on table public.liq_plantillas_correo is 'Correo que se prepara al entrar a cada etapa del funnel de liquidez. Editable por el equipo.';

insert into public.liq_plantillas_correo (etapa, asunto, cuerpo) values
('contactado',
 'Kabal · liquidez para {{vehiculo}} — {{proveedor}}',
 E'Estimado/a {{decisor}}:\n\nGracias por su tiempo. Le escribo de Kabal Bridge (PSAD-0056, El Salvador) por la oportunidad de participar como proveedor de liquidez en {{oportunidad}} ({{vehiculo}}), con un monto objetivo de {{monto}}.\n\nEn breve: financiamos comercio exterior y emisiones respaldadas por activos reales bajo el marco LEAD/CNAD, con rendimiento esperado de 12–18% APY (no garantizado), custodia regulada y KYC/AML completo antes de cualquier desembolso.\n\n¿Le parece si coordinamos una llamada de 30 minutos esta semana o la próxima? Le envío material de respaldo (one-pager y whitepaper) en cuanto me confirme.\n\nSaludos cordiales,\n{{firma}}'),
('primera_reunion',
 'Reunión Kabal × {{proveedor}} — agenda y material',
 E'Estimado/a {{decisor}}:\n\nConfirmo nuestra reunión sobre {{oportunidad}} ({{vehiculo}}). Agenda propuesta:\n\n1. Kabal en 5 minutos: tesis, licencia PSAD-0056 y marco LEAD/CNAD.\n2. La oportunidad: estructura, colateral, plazos y monto objetivo ({{monto}}).\n3. Riesgos, mitigantes y proceso de KYC/AML.\n4. Siguientes pasos y calendario.\n\nAdjunto one-pager y whitepaper. Cualquier pregunta previa, con gusto.\n\nSaludos cordiales,\n{{firma}}'),
('segunda_reunion',
 'Kabal × {{proveedor}} — segunda reunión / comité',
 E'Estimado/a {{decisor}}:\n\nGracias por la conversación. Para la segunda reunión con su comité/socios preparé:\n\n· Modelo financiero y sensibilidades de {{oportunidad}} ({{vehiculo}}, {{monto}}).\n· Estructura legal y documentación (LEAD/CNAD, contratos maestros).\n· Informe del certificador externo sobre el colateral.\n· Preguntas frecuentes de inversionistas institucionales.\n\nPróximo paso: {{proximo_paso}} ({{fecha_proximo_paso}}). Quedo atento a la fecha que mejor les acomode.\n\nSaludos cordiales,\n{{firma}}'),
('due_diligence',
 'Data room y checklist de due diligence — {{oportunidad}}',
 E'Estimado/a {{decisor}}:\n\nComo acordamos, abrimos el data room de {{oportunidad}} ({{vehiculo}}, monto objetivo {{monto}}). Incluye:\n\n· Documento de Información Relevante (DIR) y anexos.\n· Informe del certificador externo y valuación del colateral.\n· Estados financieros, contratos maestros y política de riesgos.\n· Expediente regulatorio (licencia PSAD-0056, reportes CNAD).\n\nEn paralelo, nuestro oficial de cumplimiento les enviará el checklist KYC/AML; completarlo es requisito antes de cualquier desembolso.\n\nPróximo paso: {{proximo_paso}} ({{fecha_proximo_paso}}).\n\nSaludos cordiales,\n{{firma}}'),
('compromiso_verbal',
 'Gracias por su compromiso — siguientes pasos {{oportunidad}}',
 E'Estimado/a {{decisor}}:\n\nMuchas gracias por confirmar su interés en participar con {{monto}} en {{oportunidad}} ({{vehiculo}}).\n\nPara formalizar:\n1. Les enviamos el contrato de suscripción y el formato de datos del suscriptor.\n2. Cierre de KYC/AML (si aún está pendiente).\n3. Firma y, con la firma, las instrucciones de fondeo por canal seguro.\n\nNuestra meta es cerrar la firma en los próximos 14 días. Próximo paso: {{proximo_paso}} ({{fecha_proximo_paso}}).\n\nSaludos cordiales,\n{{firma}}'),
('firmado',
 'Contrato firmado — instrucciones de fondeo {{oportunidad}}',
 E'Estimado/a {{decisor}}:\n\nConfirmamos la recepción del contrato firmado por {{monto}} en {{oportunidad}} ({{vehiculo}}). Bienvenidos.\n\nLas instrucciones de fondeo (cuenta destino, moneda y referencia) se las hace llegar nuestra tesorería por canal seguro; por favor confirmen siempre los datos por teléfono antes de transferir. Al recibir y verificar el desembolso les enviamos el acuse formal y el registro del suscriptor.\n\nSaludos cordiales,\n{{firma}}'),
('wired',
 'Acuse de recibo — fondos verificados {{oportunidad}}',
 E'Estimado/a {{decisor}}:\n\nConfirmamos la recepción y verificación de su desembolso por {{monto}} para {{oportunidad}} ({{vehiculo}}). Gracias por la confianza.\n\nA partir de ahora recibirán el reporte periódico de la emisión y el acceso al portal de inversionistas. Cualquier consulta, IR está a su disposición.\n\nSaludos cordiales,\n{{firma}}'),
('nurture',
 'Seguimos en contacto — Kabal × {{proveedor}}',
 E'Estimado/a {{decisor}}:\n\nEntendemos que {{oportunidad}} no es el momento adecuado. Nos gustaría mantenerlos al tanto de próximas emisiones ({{vehiculo}} y otros vehículos) y compartir el reporte trimestral de Kabal.\n\nSi en algún punto cambia el timing o el apetito, con gusto retomamos la conversación.\n\nSaludos cordiales,\n{{firma}}')
on conflict (etapa) do nothing;

-- -----------------------------------------------------------------------------
-- 3. Cola de correos
-- -----------------------------------------------------------------------------
create table if not exists public.liq_correos (
  id                uuid primary key default gen_random_uuid(),
  oportunidad_id    uuid not null references public.liq_oportunidades(id) on delete cascade,
  proveedor_id      uuid not null references public.liq_proveedores(id) on delete cascade,
  etapa             text not null,
  para              text,
  cc                text,
  asunto            text not null,
  cuerpo            text not null,
  estado            text not null default 'pendiente'
                    check (estado in ('pendiente','sin_correo','borrador','enviado','omitido','error')),
  gmail_draft_id    text,
  gmail_message_id  text,
  gmail_thread_id   text,
  error             text,
  creado_en         timestamptz not null default now(),
  actualizado_en    timestamptz not null default now()
);
comment on table public.liq_correos is 'Correos preparados por etapa (los genera el trigger al mover la oportunidad). El tablero/CLI los abre en Gmail y los marca.';

create index if not exists liq_correos_estado_idx on public.liq_correos (estado, creado_en desc);
-- una sola fila pendiente por oportunidad × etapa (mover ida y vuelta no duplica)
create unique index if not exists liq_correos_pendiente_uq on public.liq_correos (oportunidad_id, etapa)
  where estado in ('pendiente','sin_correo');

create or replace function public.liq_correos_touch_fn()
returns trigger language plpgsql set search_path = public as $$
begin new.actualizado_en = now(); return new; end $$;
drop trigger if exists liq_correos_touch on public.liq_correos;
create trigger liq_correos_touch before update on public.liq_correos
  for each row execute function public.liq_correos_touch_fn();

-- -----------------------------------------------------------------------------
-- 4. Render de plantilla (placeholders) para una oportunidad
-- -----------------------------------------------------------------------------
create or replace function public.liq_render_correo(p_oportunidad_id uuid, p_etapa text)
returns table (para text, asunto text, cuerpo text)
language plpgsql stable set search_path = public as $$
declare
  o     public.liq_oportunidades;
  p     public.liq_proveedores;
  t     public.liq_plantillas_correo;
  v_firma text;
  v_veh text;
  v_monto text;
  v_fecha text;
  v_ctx text[][];
  a text; c text; i int;
begin
  select * into o from public.liq_oportunidades where id = p_oportunidad_id;
  if o.id is null then return; end if;
  select * into p from public.liq_proveedores where id = o.proveedor_id;
  select * into t from public.liq_plantillas_correo where etapa = p_etapa and activa;
  if t.etapa is null then return; end if;
  select valor into v_firma from public.liq_correo_config where clave = 'firma';
  v_veh := case o.vehiculo when 'ktft' then 'KTFT' when 'emision_b2b' then 'emisión B2B'
                           when 'linea_credito' then 'línea de crédito' when 'warehouse' then 'warehouse'
                           when 'deuda_privada' then 'deuda privada' else o.vehiculo end;
  v_monto := coalesce(o.moneda, 'USD') || ' ' ||
             to_char(coalesce(nullif(o.monto_firmado_usd, 0), nullif(o.monto_comprometido_usd, 0), o.monto_objetivo_usd), 'FM999,999,999,999');
  v_fecha := coalesce(to_char(o.fecha_proximo_paso, 'DD/MM/YYYY'), 'por definir');
  v_ctx := array[
    ['{{decisor}}',            coalesce(nullif(trim(p.decisor), ''), 'equipo de ' || p.nombre)],
    ['{{proveedor}}',          p.nombre],
    ['{{oportunidad}}',        o.nombre],
    ['{{vehiculo}}',           v_veh],
    ['{{monto}}',              v_monto],
    ['{{proximo_paso}}',       coalesce(nullif(trim(o.proximo_paso), ''), 'definir siguiente paso')],
    ['{{fecha_proximo_paso}}', v_fecha],
    ['{{firma}}',              coalesce(v_firma, 'Equipo Kabal')]
  ];
  a := t.asunto; c := t.cuerpo;
  for i in 1..array_length(v_ctx, 1) loop
    a := replace(a, v_ctx[i][1], v_ctx[i][2]);
    c := replace(c, v_ctx[i][1], v_ctx[i][2]);
  end loop;
  para := nullif(trim(p.contacto_email), '');
  asunto := a; cuerpo := c;
  return next;
end $$;

-- -----------------------------------------------------------------------------
-- 5. Trigger: al cambiar de etapa se encola el correo de esa etapa
-- -----------------------------------------------------------------------------
create or replace function public.liq_oport_correo_etapa()
returns trigger language plpgsql set search_path = public as $$
declare
  r record;
  v_cc text;
begin
  if tg_op = 'UPDATE' and new.etapa is not distinct from old.etapa then return new; end if;
  select * into r from public.liq_render_correo(new.id, new.etapa);
  if r.asunto is null then return new; end if;   -- etapa sin plantilla (identificado, perdido…)
  select valor into v_cc from public.liq_correo_config where clave = 'cc_default';
  insert into public.liq_correos (oportunidad_id, proveedor_id, etapa, para, cc, asunto, cuerpo, estado)
  values (new.id, new.proveedor_id, new.etapa, r.para, v_cc, r.asunto, r.cuerpo,
          case when r.para is null then 'sin_correo' else 'pendiente' end)
  on conflict do nothing;
  return new;
end $$;

drop trigger if exists liq_oport_correo_etapa on public.liq_oportunidades;
create trigger liq_oport_correo_etapa after insert or update of etapa on public.liq_oportunidades
  for each row execute function public.liq_oport_correo_etapa();

-- Cuando se guarda la dirección del proveedor, los correos que esperaban pasan a 'pendiente'.
create or replace function public.liq_prov_correo_email()
returns trigger language plpgsql set search_path = public as $$
begin
  if nullif(trim(new.contacto_email), '') is not null
     and new.contacto_email is distinct from old.contacto_email then
    update public.liq_correos
       set para = new.contacto_email, estado = 'pendiente'
     where proveedor_id = new.id and estado = 'sin_correo';
  end if;
  return new;
end $$;

drop trigger if exists liq_prov_correo_email on public.liq_proveedores;
create trigger liq_prov_correo_email after update of contacto_email on public.liq_proveedores
  for each row execute function public.liq_prov_correo_email();

-- -----------------------------------------------------------------------------
-- 6. RPC: marcar el correo (borrador creado / enviado / omitido / error)
--    Si viene p_para y el proveedor no tenía email, lo guarda (solo hay que poner la dirección).
--    Registra la interacción en la bitácora cuando se creó borrador o se envió.
-- -----------------------------------------------------------------------------
create or replace function public.liq_correo_marcar(
  p_id uuid,
  p_estado text,
  p_para text default null,
  p_gmail_draft_id text default null,
  p_gmail_message_id text default null,
  p_gmail_thread_id text default null,
  p_asunto text default null,
  p_cuerpo text default null,
  p_error text default null
) returns public.liq_correos
language plpgsql security invoker set search_path = public as $$
declare
  v public.liq_correos;
begin
  if p_id is null then return null; end if;
  if p_estado not in ('pendiente','sin_correo','borrador','enviado','omitido','error') then
    raise exception 'LIQ_CORREO_ESTADO: estado % no válido', p_estado;
  end if;
  update public.liq_correos
     set estado = p_estado,
         para = coalesce(nullif(trim(p_para), ''), para),
         asunto = coalesce(p_asunto, asunto),
         cuerpo = coalesce(p_cuerpo, cuerpo),
         gmail_draft_id = coalesce(p_gmail_draft_id, gmail_draft_id),
         gmail_message_id = coalesce(p_gmail_message_id, gmail_message_id),
         gmail_thread_id = coalesce(p_gmail_thread_id, gmail_thread_id),
         error = case when p_estado = 'error' then coalesce(p_error, error) else null end
   where id = p_id
   returning * into v;
  if v.id is null then
    raise exception 'LIQ_CORREO_NO_ENCONTRADO: correo % no existe', p_id;
  end if;
  if nullif(trim(p_para), '') is not null then
    update public.liq_proveedores set contacto_email = p_para
     where id = v.proveedor_id and nullif(trim(contacto_email), '') is null;
  end if;
  if p_estado in ('borrador','enviado') then
    insert into public.liq_interacciones (proveedor_id, oportunidad_id, tipo, resumen, resultado, creado_por)
    values (v.proveedor_id, v.oportunidad_id, 'email',
            case when p_estado = 'enviado' then 'Enviado: ' else 'Borrador en Gmail: ' end || v.asunto,
            'etapa ' || v.etapa || case when v.para is not null then ' · ' || v.para else '' end,
            'gmail');
  end if;
  return v;
end $$;

-- Atajo: marcar por oportunidad × etapa (lo que usa el tablero al sincronizar).
create or replace function public.liq_correo_marcar_etapa(
  p_oportunidad_id uuid,
  p_etapa text,
  p_estado text,
  p_para text default null,
  p_gmail_draft_id text default null,
  p_gmail_message_id text default null,
  p_gmail_thread_id text default null,
  p_asunto text default null,
  p_cuerpo text default null
) returns public.liq_correos
language plpgsql security invoker set search_path = public as $$
declare
  v_id uuid;
begin
  select id into v_id from public.liq_correos
   where oportunidad_id = p_oportunidad_id and etapa = p_etapa and estado in ('pendiente','sin_correo')
   order by creado_en desc limit 1;
  if v_id is null then return null; end if;
  return public.liq_correo_marcar(v_id, p_estado, p_para, p_gmail_draft_id, p_gmail_message_id, p_gmail_thread_id, p_asunto, p_cuerpo, null);
end $$;

-- -----------------------------------------------------------------------------
-- 7. Vista de pendientes (lo que el tablero y el CLI muestran)
-- -----------------------------------------------------------------------------
create or replace view public.liq_v_correos_pendientes as
select c.id, c.oportunidad_id, c.proveedor_id, c.etapa, c.estado, c.para, c.cc, c.asunto, c.cuerpo,
       c.creado_en, o.nombre as oportunidad, o.vehiculo, o.monto_objetivo_usd,
       p.nombre as proveedor, p.decisor, p.contacto_email,
       round(extract(epoch from (now() - c.creado_en)) / 86400.0, 1) as dias_esperando
  from public.liq_correos c
  join public.liq_oportunidades o on o.id = c.oportunidad_id
  join public.liq_proveedores p on p.id = c.proveedor_id
 where c.estado in ('pendiente','sin_correo')
 order by c.creado_en desc;

alter view public.liq_v_correos_pendientes set (security_invoker = true);

-- -----------------------------------------------------------------------------
-- 8. RLS (misma política que el resto de liq_*)
-- -----------------------------------------------------------------------------
alter table public.liq_correos           enable row level security;
alter table public.liq_plantillas_correo enable row level security;
alter table public.liq_correo_config     enable row level security;

drop policy if exists liq_correos_auth   on public.liq_correos;
drop policy if exists liq_plantillas_auth on public.liq_plantillas_correo;
drop policy if exists liq_correo_cfg_auth on public.liq_correo_config;

create policy liq_correos_auth    on public.liq_correos           for all to authenticated using (true) with check (true);
create policy liq_plantillas_auth on public.liq_plantillas_correo for all to authenticated using (true) with check (true);
create policy liq_correo_cfg_auth on public.liq_correo_config     for all to authenticated using (true) with check (true);
