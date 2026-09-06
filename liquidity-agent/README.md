# Kabal · Agente de Liquidez — CRM / Funnel

CRM y embudo de **proveedores de liquidez** (quién pone el capital) para el ecosistema Kabal:
suscriptores del KTFT, inversionistas de emisiones B2B de Kabal Bridge y fondeadores
(warehouse / líneas de crédito) de Kabal Lending. Es el espejo lado-demanda de `bridge_leads`
(quién trae el activo) y vive en el mismo proyecto Supabase.

```
liquidity-agent/
├── db/
│   ├── migrations/20260904120000_liquidity_crm.sql   esquema completo (tablas, triggers, vistas, RLS)
│   ├── migrations/20260904190000_liquidity_directorio.sql  tipos ampliados + columnas de origen del directorio
│   ├── migrations/20260904230000_liquidity_monto_potencial.sql  monto potencial por institución + vista liq_v_potencial_directorio
│   ├── migrations/20260905150000_liquidity_correos.sql   correos por etapa: plantillas, cola liq_correos, triggers y RPC para Gmail
│   ├── migrations/20260906010000_liquidity_correos_outreach.sql  lote diario de outreach: adjuntos, firma del CEO, deck por defecto, vista del día
│   ├── migrations/20260906120000_liquidity_correos_envio.sql  correo enviado ⇒ la ficha avanza sola; lote de 8/día
│   ├── migrations/20260906150000_liquidity_vehiculo_marketplace.sql  vehículo `marketplace`: liquidez para el Kabal Digital Marketplace, materiales en config
│   ├── directorio/                                   directorio maestro RWA (172 instituciones): .py, .json e insert idempotente
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
| `liq_oportunidades` | El funnel: proveedor × vehículo (`marketplace`, `ktft`, `emision_b2b`, `linea_credito`, `warehouse`, `deuda_privada`), monto objetivo / comprometido / firmado, etapa, probabilidad, próximo paso con fecha, motivo de pérdida. Enlace opcional a `bridge_emisiones`. |
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
| `liq_v_potencial_directorio` | Monto potencial del directorio por tipo de institución (estimación inicial por tipo × calificación en `monto_potencial_usd`, origen en `monto_potencial_origen`). |

RPC: `liq_mover_etapa(oportunidad_id, etapa, motivo, proximo_paso, fecha_proximo_paso, monto_comprometido_usd)`.

### Correos por etapa (Gmail)

Al cambiar `liq_oportunidades.etapa`, el trigger `liq_oport_correo_etapa` renderiza la plantilla de esa etapa
(`liq_plantillas_correo`, una fila por etapa, placeholders `{{decisor}} {{proveedor}} {{oportunidad}} {{vehiculo}}
{{monto}} {{proximo_paso}} {{fecha_proximo_paso}} {{firma}}`) y deja el correo en la cola `liq_correos`:

| Estado | Significado |
|---|---|
| `pendiente` | El proveedor tiene `contacto_email`: listo para abrir en Gmail. |
| `sin_correo` | Falta la dirección. En cuanto se guarda `liq_proveedores.contacto_email`, el trigger `liq_prov_correo_email` lo pasa a `pendiente`. |
| `borrador` / `enviado` | Ya está en Gmail (guarda `gmail_draft_id` / `gmail_message_id` / `gmail_thread_id`) y quedó registrado en `liq_interacciones` como `email`. |
| `omitido` | Se decidió no mandarlo. |

Etapas con plantilla: contactado, primera_reunion, segunda_reunion, due_diligence, compromiso_verbal, firmado, wired, nurture
(identificado y perdido no generan correo). Firma y CC por defecto en `liq_correo_config`.

**Posicionamiento: liquidez para el Kabal Digital Marketplace.** Desde el 6-sep-2026 el outreach no vende un token
específico sino el marketplace (Kabal Invest, operado por Kabal Bridge S.A. de C.V., PSAD-0056): un venue licenciado
por la CNAD donde se emiten y negocian activos reales tokenizados de Centroamérica y México (trade finance, cuentas por
cobrar, inmobiliario, energía renovable, commodities, crédito privado). El proveedor participa como ancla de emisiones
primarias, con una facilidad programática a los vehículos originadores, con una nota de colocación privada o dando
liquidez secundaria. Vehículo `marketplace` en `liq_oportunidades`. Materiales en marca (Nexa, teal/lime/navy, isologo
oficial): `Kabal_Digital_Marketplace_One_Pager_EN.pdf` (adjunto del primer contacto) y
`Kabal_Digital_Marketplace_Liquidity_Partners_EN.pdf` (deck, en la llamada o bajo NDA); el tablero los lleva embebidos
y los sube a Drive con **Correos → «Subir materiales a Drive»** (ids en `liq_correo_config`).

**Lote diario de 8 GO (outreach).** Cada mañana el agente elige los siguientes 8 proveedores GO sin oportunidad
(por `monto_potencial_usd`; `outreach_diario_go` en `liq_correo_config`), crea la oportunidad en `identificado`, deja
en `liq_correos` el primer correo en inglés (≤200 palabras, una línea personalizada por la tesis del proveedor, un solo
CTA de 20 minutos, sin promesas) con `adjuntos = [one-pager del marketplace, deck]`, crea el borrador en Gmail por API y
arma en Drive una carpeta por institución con los materiales. En el tablero, **Correos → «Crear borradores en Gmail con
one-pager»** crea los borradores con el PDF adjunto de un clic (el deck completo es opcional) y **«Reponer one-pager
oficial»** reemplaza el adjunto de los borradores que se crearon por API; en Gmail solo falta la dirección y enviar.

**Correo enviado ⇒ la ficha avanza sola.** El trigger `liq_correos_enviado_mueve` mueve la oportunidad a la etapa del
correo (hasta `compromiso_verbal`) con próximo paso de seguimiento (primer correo → follow-up D+4) en cuanto el correo
queda `enviado`, lo marque el tablero, el CLI o la reconciliación diaria. El tablero, al abrirse con el conector Gmail,
compara los borradores registrados con los que siguen en Gmail (`list_drafts`): el que ya no está y aparece en Enviados
(`search_threads`) se marca `enviado`. El trigger de etapa no regenera el correo de una etapa que ya tiene
borrador/enviado. Vista `liq_v_correos_del_dia`.

RPC: `liq_correo_marcar(id, estado, para, gmail_draft_id, gmail_message_id, gmail_thread_id, asunto, cuerpo, error)` y
`liq_correo_marcar_etapa(oportunidad_id, etapa, estado, …)`; vista `liq_v_correos_pendientes`. La base solo prepara:
el envío lo hace el tablero (conector Gmail del visitante) o una persona desde `cli.js correos`.

## Tablero visual

`dashboard/pipeline-liquidez.html` es el mismo tablero del Pipeline RWA, adaptado al funnel de liquidez:
KPIs (wired / firmado / comprometido / ponderado / alertas), embudo por etapa, tablero kanban con arrastrar y soltar,
tabla priorizada, vista de proveedores con KYC y el reporte «Lunes de liquidez». Está publicado como Artifact de
claude.ai; cuando el visor tiene el conector Supabase, lee y escribe las tablas `liq_*` en vivo mediante `execute_sql`.
Sin conector, funciona con el snapshot embebido y exporta los cambios como SQL para aplicarlos desde el chat.
Con el CRM vacío muestra datos de ejemplo marcados como tales.

**Correos al mover fichas.** Al arrastrar una ficha a una etapa con plantilla se abre el correo de esa etapa ya
rellenado; solo hay que confirmar la dirección (se guarda en el proveedor para la próxima vez). «Borrador en Gmail»
lo deja en Borradores y «Enviar ahora» lo manda, ambos con el conector Gmail del visitante (`create_draft` /
`send_message`); sin conector quedan «Abrir en mi correo» (mailto) y «Copiar». El botón **Correos** lista los
pendientes (incluidos los que la base generó desde el CLI) y al sincronizar se marcan en `liq_correos` y en la bitácora.

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
