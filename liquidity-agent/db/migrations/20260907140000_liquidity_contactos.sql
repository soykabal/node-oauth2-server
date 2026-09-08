-- Contactos por institución: dueños de programa, decisores y puntos de entrada
-- (varios por proveedor). Fuente pública + estado del email (nunca inventado).
create table if not exists liq_contactos (
  id            uuid primary key default gen_random_uuid(),
  proveedor_id  uuid not null references liq_proveedores(id) on delete cascade,
  nombre        text not null,
  cargo         text,
  area          text,
  ubicacion     text,
  linkedin      text,
  email         text,
  email_estado  text not null default 'desconocido'
                check (email_estado in ('publico','patron_no_verificado','verificado','rebotado','desconocido')),
  rol           text not null default 'entrada'
                check (rol in ('dueno_programa','decisor','entrada','influencer','cobertura_latam','canal_generico')),
  prioridad     smallint not null default 3 check (prioridad between 1 and 5),
  por_que       text,
  fuente        text,
  notas         text,
  activo        boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index if not exists liq_contactos_prov_idx on liq_contactos(proveedor_id, prioridad);
create unique index if not exists liq_contactos_prov_nombre_uq on liq_contactos(proveedor_id, lower(nombre));

drop trigger if exists liq_contactos_touch on liq_contactos;
create trigger liq_contactos_touch before update on liq_contactos
  for each row execute function liq_touch_updated_at();

alter table liq_contactos enable row level security;
drop policy if exists liq_contactos_auth on liq_contactos;
create policy liq_contactos_auth on liq_contactos
  for all to authenticated using (true) with check (true);
drop policy if exists liq_contactos_service on liq_contactos;
create policy liq_contactos_service on liq_contactos
  for all to service_role using (true) with check (true);

-- Formato de email corporativo y canales públicos por proveedor
alter table liq_proveedores
  add column if not exists email_patron text,
  add column if not exists email_patron_fuente text,
  add column if not exists canales_publicos jsonb not null default '[]'::jsonb,
  add column if not exists ruta_recomendada text;

-- Contacto principal (prioridad 1) por proveedor
create or replace view liq_v_contacto_principal as
select distinct on (c.proveedor_id)
  c.proveedor_id, c.id as contacto_id, c.nombre, c.cargo, c.area, c.ubicacion,
  c.linkedin, c.email, c.email_estado, c.rol, c.prioridad, c.por_que, c.fuente
from liq_contactos c
where c.activo
order by c.proveedor_id, c.prioridad, c.created_at;

-- Vista completa para el dashboard
create or replace view liq_v_contactos as
select c.*, p.nombre as proveedor, p.tipo, p.pais, p.email_patron, p.ruta_recomendada
from liq_contactos c join liq_proveedores p on p.id = c.proveedor_id
where c.activo
order by p.nombre, c.prioridad, c.nombre;
