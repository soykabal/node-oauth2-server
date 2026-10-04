-- Datos de DEMO para el CRM del Agente de Liquidez.
-- Solo para un entorno local o de prueba: NO correr en producción.
-- Nombres ficticios. Idempotente (borra y recrea lo que tenga el sufijo [DEMO]).

begin;

delete from public.liq_proveedores where nombre like '%[DEMO]';

insert into public.liq_proveedores (nombre, tipo, pais, ticket_min_usd, ticket_max_usd, vehiculos, yield_objetivo_pct, horizonte_meses, moneda_preferida, decisor, contacto_email, kyc_estado, inversionista_calificado, calificacion, fuente) values
  ('Family Office Delta [DEMO]',      'family_office',         'Panamá',      250000, 2000000, '{ktft,emision_b2b}',        14, 24, 'USD',  'Ana Delta',      'ana@delta.example',   'verde',     true,  'GO',      'referido'),
  ('Fondo Ceiba Credit [DEMO]',       'fondo',                 'México',      1000000, 10000000, '{warehouse,linea_credito}', 13, 36, 'USD',  'Luis Ceiba',     'luis@ceiba.example',  'en_proceso', true, 'GO',      'evento'),
  ('Inversionista Privado R. [DEMO]', 'hnwi',                  'Honduras',    50000,  500000,  '{ktft}',                    15, 12, 'USDC', 'R. Privado',     'rp@example.com',      'pendiente', false, 'EXPLORE', 'inbound'),
  ('Banco Istmo [DEMO]',              'banco',                 'El Salvador', 2000000, 15000000, '{linea_credito,warehouse}', 11, 48, 'USD',  'Comité Istmo',   'tesoreria@istmo.example', 'pendiente', true, 'EXPLORE', 'outbound'),
  ('Tesorería Corp. Andina [DEMO]',   'tesoreria_corporativa', 'Colombia',    500000, 3000000, '{ktft,deuda_privada}',      12, 18, 'USDC', 'CFO Andina',     'cfo@andina.example',  'rojo',      true,  'DROP',    'referido'),
  ('DAO Liquidez LatAm [DEMO]',       'dao_defi',              'Global',      100000, 1000000, '{ktft}',                    16, 6,  'USDC', 'Multisig',       'gov@dao.example',     'pendiente', false, 'EXPLORE', 'inbound');

-- Oportunidades en distintas etapas
insert into public.liq_oportunidades (proveedor_id, nombre, vehiculo, monto_objetivo_usd, proximo_paso, fecha_proximo_paso, fecha_cierre_esperada, owner)
select id, 'FO Delta · KTFT 1ª emisión [DEMO]', 'ktft', 1000000, 'Enviar subscription agreement', current_date + 2, current_date + 20, 'CEO' from public.liq_proveedores where nombre = 'Family Office Delta [DEMO]';
insert into public.liq_oportunidades (proveedor_id, nombre, vehiculo, monto_objetivo_usd, proximo_paso, fecha_proximo_paso, fecha_cierre_esperada)
select id, 'Ceiba · Warehouse Kabal Lending [DEMO]', 'warehouse', 5000000, 'Sesión de DD con riesgo', current_date - 3, current_date + 60 from public.liq_proveedores where nombre = 'Fondo Ceiba Credit [DEMO]';
insert into public.liq_oportunidades (proveedor_id, nombre, vehiculo, monto_objetivo_usd)
select id, 'R. Privado · KTFT [DEMO]', 'ktft', 150000 from public.liq_proveedores where nombre = 'Inversionista Privado R. [DEMO]';
insert into public.liq_oportunidades (proveedor_id, nombre, vehiculo, monto_objetivo_usd, proximo_paso, fecha_proximo_paso)
select id, 'Istmo · Línea de crédito revolvente [DEMO]', 'linea_credito', 3000000, 'Primera reunión con tesorería', current_date + 7 from public.liq_proveedores where nombre = 'Banco Istmo [DEMO]';
insert into public.liq_oportunidades (proveedor_id, nombre, vehiculo, monto_objetivo_usd)
select id, 'Andina · KTFT [DEMO]', 'ktft', 500000 from public.liq_proveedores where nombre = 'Tesorería Corp. Andina [DEMO]';
insert into public.liq_oportunidades (proveedor_id, nombre, vehiculo, monto_objetivo_usd, proximo_paso, fecha_proximo_paso)
select id, 'DAO LatAm · KTFT [DEMO]', 'ktft', 300000, 'Responder preguntas de gobernanza', current_date + 1 from public.liq_proveedores where nombre = 'DAO Liquidez LatAm [DEMO]';

-- Avanzar el funnel
select public.liq_mover_etapa(id, 'contactado')        from public.liq_oportunidades where nombre like 'FO Delta%[DEMO]';
select public.liq_mover_etapa(id, 'primera_reunion')   from public.liq_oportunidades where nombre like 'FO Delta%[DEMO]';
select public.liq_mover_etapa(id, 'due_diligence')     from public.liq_oportunidades where nombre like 'FO Delta%[DEMO]';
select public.liq_mover_etapa(id, 'compromiso_verbal', null, null, null, 800000) from public.liq_oportunidades where nombre like 'FO Delta%[DEMO]';
-- compromiso verbal viejo ⇒ dispara alerta_degradar
update public.liq_oportunidades set fecha_compromiso_verbal = current_date - 20 where nombre like 'FO Delta%[DEMO]';

select public.liq_mover_etapa(id, 'contactado')        from public.liq_oportunidades where nombre like 'Ceiba%[DEMO]';
select public.liq_mover_etapa(id, 'primera_reunion')   from public.liq_oportunidades where nombre like 'Ceiba%[DEMO]';
select public.liq_mover_etapa(id, 'segunda_reunion')   from public.liq_oportunidades where nombre like 'Ceiba%[DEMO]';
select public.liq_mover_etapa(id, 'due_diligence')     from public.liq_oportunidades where nombre like 'Ceiba%[DEMO]';

select public.liq_mover_etapa(id, 'contactado')        from public.liq_oportunidades where nombre like 'R. Privado%[DEMO]';
select public.liq_mover_etapa(id, 'nurture', 'Ticket por debajo del mínimo hasta la 2ª emisión') from public.liq_oportunidades where nombre like 'R. Privado%[DEMO]';

select public.liq_mover_etapa(id, 'contactado')        from public.liq_oportunidades where nombre like 'Istmo%[DEMO]';

select public.liq_mover_etapa(id, 'perdido', 'KYC en rojo: fuente de fondos no verificable') from public.liq_oportunidades where nombre like 'Andina%[DEMO]';

-- Un cierre completo: firmado + wire verificado ⇒ wired automático
insert into public.liq_oportunidades (proveedor_id, nombre, vehiculo, monto_objetivo_usd, proximo_paso, fecha_proximo_paso)
select id, 'FO Delta · Emisión B2B Torre Norte [DEMO]', 'emision_b2b', 400000, 'Confirmar recepción y emitir tokens', current_date from public.liq_proveedores where nombre = 'Family Office Delta [DEMO]';
select public.liq_mover_etapa(id, 'contactado')        from public.liq_oportunidades where nombre like 'FO Delta · Emisión%[DEMO]';
select public.liq_mover_etapa(id, 'due_diligence')     from public.liq_oportunidades where nombre like 'FO Delta · Emisión%[DEMO]';
select public.liq_mover_etapa(id, 'compromiso_verbal', null, null, null, 400000) from public.liq_oportunidades where nombre like 'FO Delta · Emisión%[DEMO]';
select public.liq_mover_etapa(id, 'firmado')           from public.liq_oportunidades where nombre like 'FO Delta · Emisión%[DEMO]';
insert into public.liq_desembolsos (oportunidad_id, monto_usd, moneda, referencia, cuenta_destino, verificado)
select id, 400000, 'USDC', '0xdemo…', 'Kabal Bridge S.A. de C.V.', true from public.liq_oportunidades where nombre like 'FO Delta · Emisión%[DEMO]';

-- Interacciones
insert into public.liq_interacciones (proveedor_id, oportunidad_id, tipo, fecha, resumen, resultado, siguiente_accion, creado_por)
select p.id, o.id, 'reunion', now() - interval '2 days', 'Revisión del whitepaper y waterfall', 'Interés confirmado, piden SA', 'Enviar subscription agreement', 'agente-liquidez'
from public.liq_proveedores p join public.liq_oportunidades o on o.proveedor_id = p.id where o.nombre like 'FO Delta · KTFT%[DEMO]';
insert into public.liq_interacciones (proveedor_id, oportunidad_id, tipo, fecha, resumen, resultado, creado_por)
select p.id, o.id, 'email', now() - interval '12 days', 'Enviado data room de cartera', 'Sin respuesta', 'agente-liquidez'
from public.liq_proveedores p join public.liq_oportunidades o on o.proveedor_id = p.id where o.nombre like 'Ceiba%[DEMO]';

commit;

select etapa, oportunidades, monto_objetivo_usd, monto_ponderado_usd, monto_wired_usd from public.liq_v_funnel;
