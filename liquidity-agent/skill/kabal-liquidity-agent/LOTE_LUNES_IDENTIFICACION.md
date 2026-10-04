# Lote semanal de identificación — guion del lunes (automático)

Guion que ejecuta la rutina **«Lote semanal de liquidez — identificación cada lunes»** (cron `0 13 * * 1` UTC = 7:00 a.m. de El Salvador). Cada disparo abre una sesión nueva sin memoria: este archivo es la fuente de verdad.

Este guion es el **paso 1 de 2** del ciclo semanal de outreach. Solo identifica y prepara — no redacta ni toca Gmail. El paso 2 (redactar, adjuntar, dejar los borradores) lo hace `LOTE_SEMANAL.md` el miércoles siguiente, usando lo que este guion dejó listo el lunes. Así las instituciones aparecen en el tablero como `identificado` dos días antes de que salga cualquier borrador de correo.

**Regla que no se rompe:** este guion **nunca** toca `liq_correos` ni Gmail. Solo crea oportunidades en `liq_oportunidades`.

## Contexto

| | |
|---|---|
| Repo | `soykabal/node-oauth2-server`, rama `claude/liquidity-agent-crm-database-rqflwx` (PR #2, sin mergear) |
| Base | Supabase `hnkpjrmccsehmixcsdhr`, tablas `liq_*`, vía MCP `execute_sql` (el HTTP directo a supabase.co está bloqueado por el proxy) |
| Reglas del agente | `liquidity-agent/skill/kabal-liquidity-agent/SKILL.md` — mandan sobre este archivo si hay conflicto |
| Tablero | https://claude.ai/code/artifact/70ea4e0f-c5b0-4c71-95c8-e02e9d87149d |

Antes de leer nada bajo `liquidity-agent/`:

```
git fetch origin claude/liquidity-agent-crm-database-rqflwx
git checkout claude/liquidity-agent-crm-database-rqflwx
git pull origin claude/liquidity-agent-crm-database-rqflwx
```

## 1. Elegir hasta 8 instituciones nuevas

Solo entran instituciones a las que se les puede escribir, o sea `cobertura` `listo_verificado` o `listo_patron` en la vista `liq_v_cobertura_contacto`, y que todavía no tengan oportunidad:

```sql
select * from liq_v_cobertura_contacto
where calificacion='GO'
  and cobertura in ('listo_verificado','listo_patron')
  and not tiene_oportunidad
order by monto_potencial_usd desc nulls last
limit 8;
```

Si salen menos de 8, completá **en este orden** y decilo en el reporte:

1. `cobertura='sin_email'` (hay contactos pero ninguna dirección usable): reintentá encontrar el correo del contacto de prioridad 1 con WebSearch. Si aparece, cargalo en `liq_contactos` y entra al lote. Si no, **no** la identifiques todavía: dejala para abordaje por `canales_publicos` / `ruta_recomendada` y listala aparte en el reporte.
2. `cobertura='sin_contacto'`: investigá al responsable de programa y a 3-5 contactos con WebSearch, cargalos con el mismo esquema que `liquidity-agent/db/contactos/` (rol, prioridad 1-5, `por_que`, `fuente`, `email_estado`) y recién ahí entra al lote.
3. Recién al final, `calificacion='EXPLORE'` por el mismo criterio.

Si una institución elegible no tiene `monto_potencial_usd` (y por lo tanto `liq_proveedores.monto_potencial_usd` es `null`), **no la identifiques todavía**: `liq_oportunidades.monto_objetivo_usd` es obligatorio y no se inventa un monto. Listala aparte en el reporte como pendiente de valoración.

Nunca identifiques una institución cuya `cobertura` sea `sin_email` o `sin_contacto` sin haber cargado antes un contacto con email usable: sin destinatario, el miércoles no tiene a quién dirigir el borrador.

## 2. Crear la oportunidad

Para cada institución elegida, insertar en `liq_oportunidades` (etapa por defecto `identificado`, no toques `liq_correos`):

```sql
insert into liq_oportunidades (proveedor_id, nombre, vehiculo, moneda, monto_objetivo_usd)
select p.id, p.nombre || ' · Marketplace Kabal', 'marketplace', 'USD', p.monto_potencial_usd
from liq_proveedores p
where p.id = '<proveedor_id>';
```

No hace falta ningún paso extra: no existe plantilla de correo para la etapa `identificado` en `liq_plantillas_correo`, así que el trigger `liq_oport_correo_etapa` no genera ninguna fila en `liq_correos` en este momento. El correo (etapa `contactado`) lo arma `LOTE_SEMANAL.md` el miércoles.

## 3. Republicar el tablero

Copiá `liquidity-agent/dashboard/pipeline-liquidez.html` al scratchpad, actualizá el SNAPSHOT embebido (`/*__SNAPSHOT__*/{…}`) con los datos frescos y publicalo con la herramienta Artifact pasando `url: https://claude.ai/code/artifact/70ea4e0f-c5b0-4c71-95c8-e02e9d87149d`. Si el publish es rechazado por versión, leelo antes con `action:"read"`. Omití `favicon`. Si no se identificó ninguna institución nueva, podés omitir este paso.

## 4. Commit y push

Si tocaste `liquidity-agent/dashboard/pipeline-liquidez.html` u otro archivo del repo (por ejemplo `liquidity-agent/db/contactos/` al cargar contactos nuevos de la investigación de fallback), hacé commit y `git push -u origin claude/liquidity-agent-crm-database-rqflwx`. No abrir un PR nuevo: ya existe el #2. Si no hubo cambios de archivos (solo filas nuevas en Supabase), no hace falta commit.

## 5. Reportar

En español y breve: las instituciones identificadas hoy (nombre, monto objetivo, cobertura), las que quedaron fuera por falta de valoración o de contacto usable, y si el fondo de instituciones GO con cobertura lista se está agotando (menos de 8 disponibles sin necesidad de investigación de fallback). Decí explícitamente que **no se tocó ningún correo**: el miércoles siguiente `LOTE_SEMANAL.md` redacta y deja los borradores para lo que quedó `identificado` acá.
