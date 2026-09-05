# Pipeline RWA · Kabal Bridge — dashboard

Tablero de originación para administrar etapa, calificación y notas de los
contactos RWA de `public.bridge_leads` (Kabal Bridge, Centroamérica).

- **Artifact (URL fija):** https://claude.ai/code/artifact/e1343752-89b2-4207-8998-592b96c72ec4
- **Proyecto Supabase:** `hnkpjrmccsehmixcsdhr`
- **Tabla fuente:** `public.bridge_leads`

## Vistas

- **Tablero / Tabla** — pipeline activo: solo los prospectos **con contacto** (correo),
  gestionables por etapa (`nuevo → … → mandato`). El chip "Incluir Outbox en el tablero"
  los trae de vuelta si se necesita.
- **Outbox** — prospectos **sin contacto** (sin correo/decisor). Entraron por el scout pero
  aún no son contactables; el objetivo es conseguirles un contacto para activarlos. Al cargar
  el `contacto_email` en Supabase, el prospecto sale del Outbox y entra al tablero
  automáticamente (la vista se deriva de si el lead tiene correo, no de un estado en la base).

## Cómo se arma

`dashboard.html` = `template.html` con los datos de `bridge_leads` embebidos.
La plantilla trae el marcador `/*__LEADS__*/[]`; `build.py` lo reemplaza por
el array de contactos y escribe `dashboard.html`.

```
python3 build.py      # lee leads.json -> escribe dashboard.html
```

## Barrido diario (automático)

Rutina `Barrido diario · Valoración Pipeline RWA` (6:00 AM Honduras · `0 12 * * *` UTC).
Dispara **dentro de la sesión de Claude que la creó** (así hereda el acceso a Supabase,
Artifact y git; una sesión nueva no traía los conectores y por eso la rutina anterior
quedó desactivada). Cada mañana:

0. **Valora los leads nuevos** que el scout agregó y aún no tienen fila en
   `bridge_lead_valoraciones` (mismo método: estimación → escéptico → tier/fees
   canónicos) y los inserta.

Y luego hace el refresco del tablero:

1. Consulta Supabase (proyecto `hnkpjrmccsehmixcsdhr`) con el SELECT de abajo.
   Como el resultado (~430 filas en una sola celda `json_agg`) excede el límite
   de tokens, `execute_sql` guarda la salida en un archivo y devuelve su ruta.
2. `python3 parse_result.py <ruta-del-archivo>` → escribe `leads.json`.
3. `python3 build.py` → regenera `dashboard.html`.
4. Republica el artifact a la **misma URL** (primero lo lee con `action:read`,
   luego publica `dashboard.html` con `url=` esa URL) — así el enlace no cambia.
5. Commit de `leads.json` y `dashboard.html` del día en la branch
   `claude/supabase-table-query-o75meu`.

### SELECT de la actualización

```sql
select json_agg(l order by l.updated_at desc) from (
  select b.id, b.empresa, b.pais, b.sector, b.tipo_activo, b.monto_estimado_usd,
         b.senal, b.senal_url, b.senal_fecha, b.decisor, b.contacto_email, b.telefono,
         b.calificacion, b.etapa, b.angulo_entrada, b.fuente, b.notas,
         b.created_at, b.updated_at,
         v.valor_potencial_usd, v.tier as valor_tier, v.confianza as valor_confianza,
         v.clase as valor_clase, v.racional as valor_racional,
         v.fee_potencial_usd, v.fee_recurrente_anual_usd
  from bridge_leads b
  left join bridge_lead_valoraciones v on v.lead_id = b.id
) l;
```

El resultado (columna `json_agg`) es el contenido de `leads.json`.

## Valor potencial de emisión

Tabla lateral `public.bridge_lead_valoraciones` (aditiva; se une por `lead_id`, no
toca `bridge_leads`). Por prospecto guarda:

- `valor_potencial_usd` — tamaño plausible de la **primera emisión tokenizada** del
  activo (no el valor total del proyecto). Estimación IA por lotes, verificada por un
  agente escéptico y calibrada entre lotes para consistencia.
- `tier` — 0 sub-escala (< $1M) · 1 $1–5M · 2 $5–25M · 3 $25M+ (derivado del valor).
- `confianza` — alta (cifra explícita) · media (inferible de la señal) · baja (norma de sector).
- `clase`, `racional` — clase de activo y justificación corta.
- `fee_potencial_usd` — pricing canónico Kabal: **US$15,000 + 2 % del colocado**.
- `fee_recurrente_anual_usd` — administración post-emisión: **0.5 % anual** sobre AUM.

Los leads nuevos que entren por el scout aparecen **sin valorar** hasta que se corra
de nuevo la valoración (o se valoren a mano en la tabla).

## Nota sobre los cambios hechos en el tablero

El artifact publicado no escribe directo a Supabase (RLS activo, sin
credenciales). Los cambios de etapa/calificación/notas que se hacen en el
tablero se guardan en el navegador y se exportan como SQL desde el botón
**Sincronizar**. Ese SQL se aplica a `bridge_leads` para que la actualización
diaria los recoja de vuelta.
