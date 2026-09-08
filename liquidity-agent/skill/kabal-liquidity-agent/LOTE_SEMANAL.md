# Lote semanal de outreach — guion del lunes (automático)

Guion que ejecuta la rutina **«Lote semanal de liquidez — 8 GO cada lunes»** (cron `0 13 * * 1` UTC = 7:00 a.m. de El Salvador). Cada disparo abre una sesión nueva sin memoria: este archivo es la fuente de verdad.

**Regla que no se rompe:** el agente **nunca envía** un correo. Solo deja borradores en Gmail. El CEO (Guillermo Kattan, `gkattan@soykabal.com`) revisa y envía.

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
```

## 1. Reconciliar la semana anterior

Para cada fila de `liq_correos` con `estado='borrador'` y `gmail_draft_id` no nulo: si el borrador ya no está en Gmail y el mensaje aparece en Enviados, marcalo `enviado` con el RPC `liq_correo_marcar`. El trigger `liq_correos_enviado_mueve` mueve la oportunidad sola y deja el follow-up D+4.

Rebotes: buscá en Gmail `from:mailer-daemon OR subject:"Delivery Status Notification" newer_than:8d`. Si una dirección rebotó, poné ese contacto en `email_estado='rebotado'` en `liq_contactos`; si hay un contacto de prioridad 2 con email, dirigí el borrador a él y decilo en el reporte.

## 2. Elegir las 8 instituciones

```sql
select p.* from liq_proveedores p
where p.calificacion='GO'
  and not exists (select 1 from liq_oportunidades o where o.proveedor_id=p.id)
order by p.monto_potencial_usd desc nulls last
limit 8;
```

Si quedan menos de 8 GO sin oportunidad, completá con `calificacion='EXPLORE'` por el mismo criterio y decilo en el reporte.

Si una institución elegida no tiene filas en `liq_contactos`, investigá primero a su responsable de programa y a 3-5 contactos con WebSearch, cargalos con el mismo esquema que `liquidity-agent/db/contactos/` (rol, prioridad 1-5, `por_que`, `fuente`, `email_estado`) y recién ahí seguí.

## 3. Crear la oportunidad

Etapa `identificado`, vehículo `marketplace`. El trigger de etapa deja sola la fila en `liq_correos`.

## 4. Redactar el correo

Inglés, 200 palabras o menos: una sola línea personalizada con la tesis o el hito público del proveedor, un único CTA de 20 minutos, firma del CEO desde `liq_correo_config`.

Reglas de marca, sin excepción:

- Es liquidez para el **Kabal Digital Marketplace** (venue con licencia CNAD, Kabal Bridge S.A. de C.V., PSAD-0056), **no** para un token específico.
- Nada de KTFT en materiales de marketplace.
- Sin promesas de rendimiento: «target yields are indicative, not guaranteed».
- Sin «primero» ni «único».
- Precios y términos solo bajo NDA o en llamada.

## 5. Destinatario

Contacto de prioridad 1 de la vista `liq_v_contacto_principal`.

- Decisión del CEO del 2026-09-08: además de `publico` y `verificado`, **se aceptan** direcciones con `email_estado='patron_no_verificado'`. Un rebote se registra y el siguiente lote pasa al contacto de prioridad 2.
- **Nunca se inventa una dirección.** Si prioridad 1 no tiene email, probá prioridad 2; si ninguno tiene, dejá el borrador sin destinatario y listalo en el reporte.
- Copia y copia oculta: los valores de `outreach_cc_default` y `outreach_bcc_default` en `liq_correo_config`.
- Encabezado: «Dear Nombre Apellido,». Nunca Mr./Ms./Sr./Sra. — no se asume el trato de nadie.

## 6. Borradores en Gmail con el one-pager

El PDF oficial está embebido en `liquidity-agent/dashboard/pipeline-liquidez.html`:

```js
const ONEPAGER = {nombre:"Kabal_Digital_Marketplace_One_Pager_EN.pdf", mime:"application/pdf", bytes:195301, drive_id:"", b64:"<base64>"}
```

Extraé ese base64 con `python3`/`node`, guardalo en el scratchpad y pasalo en `attachments` de `create_draft`.

**Nunca adjuntes un archivo que no verificaste:** comprobá que empiece con `%PDF` y pese ~195 301 bytes. Si el adjunto falla, creá igual el borrador y marcá `adjuntos[].adjunto_en_gmail=false`; el tablero lo repone solo al abrirse.

> Ojo con `update_draft`: los adjuntos **no** se preservan. Si tocás un borrador ya creado, volvé a pasar el adjunto o marcá la bandera en `false`.

## 7. Guardar

En `liq_correos`: `para`, `cc`, `asunto`, `cuerpo`, `gmail_draft_id`, `gmail_message_id`, `gmail_thread_id`, `adjuntos`, estado `borrador`. En Drive, una carpeta por institución bajo `outreach_drive_root_id` con el one-pager y el deck.

## 8. Commit y push

A `claude/liquidity-agent-crm-database-rqflwx` (`git push -u origin claude/liquidity-agent-crm-database-rqflwx`). No abrir un PR nuevo: ya existe el #2.

## 9. Republicar el tablero

Copiá `liquidity-agent/dashboard/pipeline-liquidez.html` al scratchpad, actualizá el SNAPSHOT embebido (`/*__SNAPSHOT__*/{…}`) con los datos frescos y publicalo con la herramienta Artifact pasando `url: https://claude.ai/code/artifact/70ea4e0f-c5b0-4c71-95c8-e02e9d87149d`. Si el publish es rechazado por versión, leelo antes con `action:"read"`. Omití `favicon`.

## 10. Reportar

En español y breve: las 8 instituciones, a quién va cada correo y con qué estado de verificación de email, los rebotes de la semana, los borradores que quedaron sin destinatario y cualquier contacto que haya cambiado de puesto. Decí explícitamente que **nada fue enviado**.
