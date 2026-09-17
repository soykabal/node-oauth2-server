#!/usr/bin/env python3
"""Convierte el resultado del SELECT de Supabase en leads.json.

El SELECT devuelve una sola fila/columna (json_agg) con ~430 contactos, asi que
execute_sql suele exceder el limite de tokens y guarda la salida en un archivo.
Este script recibe ESE archivo (o cualquier texto que contenga el arreglo JSON)
y escribe rwa-dashboard/leads.json.

Uso:
    python3 parse_result.py <ruta-del-archivo-de-resultado>
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def main():
    if len(sys.argv) < 2:
        sys.exit("Uso: python3 parse_result.py <archivo-de-resultado>")
    raw = open(sys.argv[1], encoding="utf-8").read()

    # El archivo puede ser el tool-result completo {"result": "...<json>..."}
    s = raw
    try:
        outer = json.loads(raw)
        if isinstance(outer, dict) and "result" in outer:
            s = outer["result"]
    except json.JSONDecodeError:
        pass

    i, j = s.find("["), s.rfind("]")
    if i == -1 or j == -1:
        sys.exit("No se encontro un arreglo JSON en el resultado")
    arr = json.loads(s[i:j + 1])

    # json_agg viene como [{"json_agg": [ ...contactos... ]}]
    if arr and isinstance(arr[0], dict) and "json_agg" in arr[0]:
        data = arr[0]["json_agg"]
    else:
        data = arr
    if not isinstance(data, list):
        sys.exit("El contenido no es un arreglo de contactos")

    out = os.path.join(HERE, "leads.json")
    json.dump(data, open(out, "w", encoding="utf-8"), ensure_ascii=False)
    print(f"{len(data)} contactos -> leads.json")


if __name__ == "__main__":
    main()
