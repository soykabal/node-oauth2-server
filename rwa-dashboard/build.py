#!/usr/bin/env python3
"""Genera dashboard.html inyectando leads.json en template.html.

Uso:
    python3 build.py           # lee leads.json, escribe dashboard.html

leads.json debe ser un array JSON de contactos de public.bridge_leads
(ver el SELECT en README.md). Solo se conservan las columnas que usa el
tablero; el resto se ignora sin error.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
KEEP = [
    "id", "empresa", "pais", "sector", "tipo_activo", "monto_estimado_usd",
    "senal", "senal_url", "senal_fecha", "decisor", "contacto_email",
    "telefono", "calificacion", "etapa", "angulo_entrada", "fuente",
    "notas", "updated_at",
    # valoracion potencial (LEFT JOIN bridge_lead_valoraciones)
    "valor_potencial_usd", "valor_tier", "valor_confianza", "valor_clase",
    "valor_racional", "fee_potencial_usd", "fee_recurrente_anual_usd",
    "valor_canal",
]
MARKER = "/*__LEADS__*/[]"


def main():
    leads_path = os.path.join(HERE, "leads.json")
    tpl_path = os.path.join(HERE, "template.html")
    out_path = os.path.join(HERE, "dashboard.html")

    with open(leads_path, encoding="utf-8") as f:
        leads = json.load(f)
    if not isinstance(leads, list):
        sys.exit("leads.json debe ser un array JSON")

    clean = [{k: l.get(k) for k in KEEP} for l in leads]
    payload = json.dumps(clean, ensure_ascii=False, separators=(",", ":"))

    with open(tpl_path, encoding="utf-8") as f:
        tpl = f.read()
    if MARKER not in tpl:
        sys.exit("No se encontró el marcador de datos en template.html")

    html = tpl.replace(MARKER, "/*__LEADS__*/" + payload)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(html)

    print(f"OK · {len(clean)} contactos · {len(html):,} bytes -> dashboard.html")


if __name__ == "__main__":
    main()
