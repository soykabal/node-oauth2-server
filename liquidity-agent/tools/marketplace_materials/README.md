# Materiales del Kabal Digital Marketplace (proveedores de liquidez)

Fuentes HTML del one-pager y del deck en inglés, en manual de marca (Nexa, teal #075259 / lime #6FD904 / navy #141E26,
isologo oficial en negativo). Se renderizan a PDF con Chromium (Playwright):

```bash
# 1. colocar las fuentes y el logo (no se versionan: son activos privados de marca)
#    fonts/Nexa-Regular.otf  fonts/Nexa-Bold.otf   (Drive: Kabal Manual de Marca)
#    assets/logo-dark.png                          (isologo negativo: blanco + triángulos lima)
# 2. renderizar
node render_pdf.js
# → Kabal_Digital_Marketplace_One_Pager_EN.pdf (Letter) y Kabal_Digital_Marketplace_Liquidity_Partners_EN.pdf (16:9)
```

El one-pager es el adjunto del primer contacto; el deck va en la llamada o bajo NDA. Contenido canónico: Operator
Document Scope del marketplace (Listing/Trading Rules, DIR, AML/KYC, conflictos, fee schedule), sin referencias a un
token específico, yields "objetivo, no garantizado", sin "first/only", pricing solo bajo NDA.

## Versión ligera para adjuntar por API (`onepager_lean.py`)

El PDF renderizado con Chromium embebe Nexa como fuente Type3 (≈190 KB) y no puede adjuntarse por API desde el chat.
`onepager_lean.py` genera el mismo one-pager en ≈20 KB: texto en Helvetica (WinAnsi), logo oficial como JPEG con el
fondo de marca horneado (`logo_dark_on_navy.jpg` 360 px, `logo_light_on_grey.jpg` 200 px) y la paleta oficial.
Es el adjunto que el agente pone en los borradores del lote diario; la versión con Nexa queda embebida en el tablero
(«Reponer one-pager oficial») y en Drive.
