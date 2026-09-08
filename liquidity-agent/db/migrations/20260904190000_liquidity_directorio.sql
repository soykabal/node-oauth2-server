-- Directorio de instituciones de liquidez: más tipos y columnas de origen
-- (aplicada en Supabase como liquidity_agent_directorio)
alter table public.liq_proveedores drop constraint if exists liq_proveedores_tipo_check;
alter table public.liq_proveedores add constraint liq_proveedores_tipo_check check (tipo in (
  'family_office','fondo','gestor_activos','hnwi','banco','banca_inversion','fintech_lender',
  'tesoreria_corporativa','dao_defi','market_maker','custodio','exchange','plataforma_tokenizacion',
  'infraestructura','aseguradora','soberano','multilateral','corporativo','otro'));
alter table public.liq_proveedores
  add column if not exists categoria    text,   -- categoría del directorio (Global & Regional Banks, DeFi…)
  add column if not exists tipo_detalle text,   -- tipo tal como lo describe la fuente
  add column if not exists region       text,   -- región / foco tal como lo describe la fuente
  add column if not exists tesis        text,   -- por qué es un fit (why it's a fit)
  add column if not exists origen_lista text;   -- documento de origen
create index if not exists liq_prov_categoria_idx on public.liq_proveedores(categoria);
create index if not exists liq_prov_tipo_idx on public.liq_proveedores(tipo);
