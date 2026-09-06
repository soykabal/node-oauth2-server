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
