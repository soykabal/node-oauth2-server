# Contactos por institución (investigación pública, 2026-09-07)

Un JSON por institución GO del directorio (`liq_proveedores.calificacion = 'GO'`), producido por búsqueda en
fuentes públicas (sitios corporativos, comunicados, perfiles públicos de LinkedIn, agendas de conferencias, prensa).
Cada archivo trae:

- `programa`: qué programa de activos digitales / tokenización tiene la institución y quién lo lleva.
- `formato_email`: patrón corporativo con fuente y confianza. **Ningún email nominal se inventa**: los que no se
  vieron literalmente en una página pública quedan como `patron_no_verificado` y hay que confirmarlos antes de enviar.
- `canales_publicos`: buzones y formularios oficiales (prensa, IR, partnerships), teléfonos, LinkedIn corporativo.
- `contactos`: dueño del programa, decisores, puntos de entrada, influencers y cobertura LatAm, con `prioridad`
  (1 = escribir primero), `por_que` y `fuente`.
- `ruta_recomendada`: a quién escribir primero, a quién copiar y el camino cálido (socio, evento, inversionista común).
- `notas`: limitaciones de la búsqueda y datos a verificar (títulos vigentes, salidas recientes, etc.).

`generar_sql.py` convierte los JSON en upserts para `liq_contactos` y en updates de `liq_proveedores`
(`email_patron`, `canales_publicos`, `ruta_recomendada`, `decisor`, `contacto_email` solo si es público):

```bash
python3 liquidity-agent/db/contactos/generar_sql.py            # genera sql/<institucion>.sql junto a los JSON
python3 liquidity-agent/db/contactos/generar_sql.py blackrock.json
```

Los SQL se aplican con el conector de Supabase (`execute_sql`) o `psql`. La migración que crea la tabla es
`db/migrations/20260907140000_liquidity_contactos.sql`. Al cargar una nueva tanda GO, agregar el JSON aquí y volver a generar.
