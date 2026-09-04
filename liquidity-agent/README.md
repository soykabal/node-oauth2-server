# Kabal · Agente de Liquidez — CRM / Funnel

CRM y embudo de **proveedores de liquidez** (quién pone el capital) para el ecosistema Kabal:
suscriptores del KTFT, inversionistas de emisiones B2B de Kabal Bridge y fondeadores
(warehouse / líneas de crédito) de Kabal Lending. Es el espejo lado-demanda de `bridge_leads`
(quién trae el activo) y vive en el mismo proyecto Supabase.

```
liquidity-agent/
├── db/
│   ├── migrations/20260904120000_liquidity_crm.sql   esquema completo (tablas, triggers, vistas, RLS)
│   └── seed_demo.sql                                 datos ficticios para probar en local
├── src/
│   ├── crm.js        cliente PostgREST sin dependencias + lógica de priorización/resumen
│   └── cli.js        línea de comandos del agente
├── dashboard/pipeline-liquidez.html                  tablero visual (Artifact): funnel, tablero kanban, tabla, proveedores, lunes
├── skill/kabal-liquidity-agent/SKILL.md              definición del agente (reglas, flujos, formato)
└── test/
    ├── crm_test.js   unit tests (mocha)
    └── db_smoke.sql  prueba de extremo a extremo del esquema en Postgres local
```

## Modelo de datos

| Tabla | Qué es |
|---|---|
| `liq_proveedores` | La cuenta: tipo (family office, fondo, HNWI, banco, fintech lender, tesorería, DAO…), país, rango de ticket, vehículos de interés, yield objetivo, decisor, **estado KYC**, calificación GO/EXPLORE/DROP. |
| `liq_oportunidades` | El funnel: proveedor × vehículo (`ktft`, `emision_b2b`, `linea_credito`, `warehouse`, `deuda_privada`), monto objetivo / comprometido / firmado, etapa, probabilidad, próximo paso con fecha, motivo de pérdida. Enlace opcional a `bridge_emisiones`. |
| `liq_interacciones` | Bitácora: email, llamada, reunión, WhatsApp, evento, documento, nota. |
| `liq_desembolsos` | Wires recibidos (USD / USDC / HNL), referencia, cuenta destino, verificado. |
| `liq_etapa_historial` | Auditoría automática de cada cambio de etapa con días en la etapa anterior. |

Etapas: `identificado → contactado → primera_reunion → segunda_reunion → due_diligence → compromiso_verbal → firmado → wired`, más `nurture` y `perdido`.

### Reglas que la base hace cumplir

- **KYC antes del wire**: no se puede pasar a `wired` si el proveedor no tiene `kyc_estado = 'verde'`.
- **Perdido exige motivo**.
- Al entrar a `compromiso_verbal` se fija la fecha (para la regla de degradación a los 14 días); al entrar a `firmado` se fijan fecha y monto firmado.
- Un desembolso **verificado** que cubre el monto firmado mueve la oportunidad a `wired` automáticamente.
- La probabilidad se ajusta a la etapa salvo que se sobreescriba a mano.
- RLS activo en todas las tablas con la misma política que `bridge_*` (rol `authenticated`); las vistas corren como `security_invoker`.

### Vistas

| Vista | Uso |
|---|---|
| `liq_v_pipeline` | Oportunidades vivas con días en etapa, días sin contacto, wired real, monto ponderado y banderas SLA (`alerta_sin_proximo_paso`, `alerta_paso_vencido`, `alerta_degradar`, `alerta_kyc`). |
| `liq_v_funnel` | Conteo y $ por etapa en orden de embudo. |
| `liq_v_resumen_vehiculo` | Pipeline / ponderado / comprometido / firmado / wired por vehículo. |
| `liq_v_proveedor_resumen` | Cuenta 360 por proveedor. |
| `liq_v_motivos_perdida` | Motivos de pérdida agregados. |

RPC: `liq_mover_etapa(oportunidad_id, etapa, motivo, proximo_paso, fecha_proximo_paso, monto_comprometido_usd)`.

## Tablero visual

`dashboard/pipeline-liquidez.html` es el mismo tablero del Pipeline RWA, adaptado al funnel de liquidez:
KPIs (wired / firmado / comprometido / ponderado / alertas), embudo por etapa, tablero kanban con arrastrar y soltar,
tabla priorizada, vista de proveedores con KYC y el reporte «Lunes de liquidez». Está publicado como Artifact de
claude.ai; cuando el visor tiene el conector Supabase, lee y escribe las tablas `liq_*` en vivo mediante `execute_sql`.
Sin conector, funciona con el snapshot embebido y exporta los cambios como SQL para aplicarlos desde el chat.
Con el CRM vacío muestra datos de ejemplo marcados como tales.

## Uso

```bash
export SUPABASE_URL=https://<ref>.supabase.co
export SUPABASE_KEY=<service_role o JWT de usuario autenticado>

node liquidity-agent/src/cli.js help
node liquidity-agent/src/cli.js lunes --meta 5000000        # resumen ejecutivo + top 3 + alertas
node liquidity-agent/src/cli.js funnel --meta 5000000
node liquidity-agent/src/cli.js pipeline                    # priorizado por urgencia × valor × cierre
node liquidity-agent/src/cli.js proveedores
node liquidity-agent/src/cli.js proveedor:crear --nombre "Fondo X" --tipo fondo --pais México --vehiculos ktft,warehouse
node liquidity-agent/src/cli.js oportunidad:crear --proveedor <uuid> --nombre "Fondo X · KTFT E1" --monto 1000000 --paso "Enviar whitepaper" --fecha 2026-09-10
node liquidity-agent/src/cli.js mover --id <uuid> --etapa compromiso_verbal --monto 800000
node liquidity-agent/src/cli.js interaccion --proveedor <uuid> --tipo reunion --resumen "..." --siguiente "..."
node liquidity-agent/src/cli.js wire --oportunidad <uuid> --monto 800000 --moneda USDC --ref 0x... --verificado
node liquidity-agent/src/cli.js perdidas
```

Desde código:

```js
const { crearCliente, priorizar, resumenFunnel } = require('./liquidity-agent/src/crm');
const crm = crearCliente();                       // lee SUPABASE_URL / SUPABASE_KEY
const lunes = await crm.lunesDeLiquidez(5000000); // { resumen, por_vehiculo, top3, alertas, funnel }
```

## Pruebas

```bash
npm install
npm run test-liquidity                                     # unit tests (sin base de datos)

# Esquema de extremo a extremo en un Postgres local (con rol `authenticated` y stub de bridge_emisiones):
psql -d <db> -v ON_ERROR_STOP=1 -f liquidity-agent/test/db_smoke.sql
psql -d <db> -f liquidity-agent/db/migrations/20260904120000_liquidity_crm.sql -f liquidity-agent/db/seed_demo.sql
```

## Despliegue

La migración ya está aplicada en el proyecto Supabase de Kabal (`liquidity_agent_crm` y
`liquidity_agent_crm_search_path`). Para otro entorno, aplicar el archivo de `db/migrations/`
con `supabase db push` o el MCP `apply_migration`. Es aditiva: no toca tablas existentes.
