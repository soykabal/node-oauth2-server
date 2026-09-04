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

## Actualización diaria (automática)

Una rutina programada corre cada mañana y hace:

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
  select id, empresa, pais, sector, tipo_activo, monto_estimado_usd,
         senal, senal_url, senal_fecha, decisor, contacto_email, telefono,
         calificacion, etapa, angulo_entrada, fuente, notas,
         created_at, updated_at
  from bridge_leads
) l;
```

El resultado (columna `json_agg`) es el contenido de `leads.json`.

## Nota sobre los cambios hechos en el tablero

El artifact publicado no escribe directo a Supabase (RLS activo, sin
credenciales). Los cambios de etapa/calificación/notas que se hacen en el
tablero se guardan en el navegador y se exportan como SQL desde el botón
**Sincronizar**. Ese SQL se aplica a `bridge_leads` para que la actualización
diaria los recoja de vuelta.
