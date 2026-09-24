-- Separa el directorio por cobertura de contacto: a quién se le puede escribir hoy,
-- quién tiene contactos pero ninguna dirección usable, y quién no tiene contacto todavía.
create or replace view liq_v_cobertura_contacto as
select
  p.id            as proveedor_id,
  p.nombre        as proveedor,
  p.tipo,
  p.pais,
  p.calificacion,
  p.monto_potencial_usd,
  case
    when exists (select 1 from liq_contactos k where k.proveedor_id = p.id and k.activo
                   and k.email is not null and k.email_estado in ('publico','verificado'))
      then 'listo_verificado'
    when exists (select 1 from liq_contactos k where k.proveedor_id = p.id and k.activo
                   and k.email is not null and k.email_estado = 'patron_no_verificado')
      then 'listo_patron'
    when exists (select 1 from liq_contactos k where k.proveedor_id = p.id and k.activo)
      then 'sin_email'
    else 'sin_contacto'
  end as cobertura,
  (select count(*) from liq_contactos k
     where k.proveedor_id = p.id and k.activo) as contactos,
  (select count(*) from liq_contactos k
     where k.proveedor_id = p.id and k.activo and k.email is not null
       and k.email_estado in ('publico','verificado','patron_no_verificado')) as contactos_con_email,
  (select count(*) from liq_contactos k
     where k.proveedor_id = p.id and k.activo and k.email_estado = 'rebotado') as rebotados,
  cp.nombre       as contacto_1,
  cp.cargo        as contacto_1_cargo,
  cp.email        as contacto_1_email,
  cp.email_estado as contacto_1_email_estado,
  p.email_patron,
  p.canales_publicos,
  p.ruta_recomendada,
  exists (select 1 from liq_oportunidades o where o.proveedor_id = p.id) as tiene_oportunidad
from liq_proveedores p
left join liq_v_contacto_principal cp on cp.proveedor_id = p.id;

comment on view liq_v_cobertura_contacto is
  'Cobertura de contacto por institución. cobertura: listo_verificado (hay email publico/verificado), listo_patron (solo patron_no_verificado, aceptado por decisión del CEO 2026-09-08), sin_email (hay contactos pero ninguna dirección usable: ir por canales_publicos / ruta_recomendada), sin_contacto (falta investigar). El lote semanal solo puede dirigir correo a listo_*.';
