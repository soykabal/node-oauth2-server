-- =============================================================================
-- Kabal · Agente de Liquidez — vehículo 'marketplace'
-- =============================================================================
-- El outreach a proveedores de liquidez se hace para el Kabal Digital
-- Marketplace (Kabal Invest, operado por Kabal Bridge S.A. de C.V., PSAD-0056),
-- no para un token específico: ancla de emisiones primarias, facilidad
-- programática a los vehículos originadores, nota de colocación privada o
-- liquidez secundaria en el venue. Materiales (one-pager + deck del marketplace,
-- manual de marca) en liq_correo_config; el tablero los sube a Drive.
-- =============================================================================
alter table public.liq_oportunidades drop constraint if exists liq_oportunidades_vehiculo_check;
alter table public.liq_oportunidades add constraint liq_oportunidades_vehiculo_check
  check (vehiculo in ('ktft','emision_b2b','linea_credito','warehouse','deuda_privada','marketplace'));
comment on column public.liq_oportunidades.vehiculo is 'ktft | emision_b2b | linea_credito | warehouse | deuda_privada | marketplace (liquidez para el Kabal Digital Marketplace: ancla de emisiones primarias, facilidad programática o liquidez secundaria, sin atarse a un token específico)';

insert into public.liq_correo_config (clave, valor) values
  ('outreach_posicionamiento', 'marketplace'),
  ('outreach_posicionamiento_nota', 'Desde 2026-09-06 el outreach a proveedores de liquidez se hace para el Kabal Digital Marketplace (Kabal Invest, operado por Kabal Bridge S.A. de C.V., PSAD-0056), no para un token específico.'),
  ('onepager_marketplace_nombre', 'Kabal_Digital_Marketplace_One_Pager_EN.pdf'),
  ('deck_marketplace_nombre', 'Kabal_Digital_Marketplace_Liquidity_Partners_EN.pdf'),
  ('materiales_nota', 'One-pager y deck del Kabal Digital Marketplace (EN, manual de marca). Los ids de Drive (onepager_marketplace_drive_id / deck_marketplace_drive_id) los escribe el tablero al subirlos con «Subir materiales a Drive».')
on conflict (clave) do update set valor = excluded.valor;
delete from public.liq_correo_config where clave in ('onepager_ktft_en_drive_id','onepager_ktft_en_nombre','onepager_ktft_en_origen','deck_ktft_en_drive_id','deck_ktft_en_nombre');
