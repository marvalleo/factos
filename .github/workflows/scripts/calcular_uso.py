"""
Calcula porcentaje de uso contra las cuotas del plan Free de Supabase y
escribe el resultado como GitHub Actions outputs.

Corrección (revisión externa, sept. 2026): la versión anterior asumía un
endpoint GET /v1/projects/{ref}/usage con campos db_size_bytes/egress_bytes.
Ese endpoint no existe públicamente documentado en esa forma. Fuentes reales
usadas ahora:

  - Tamaño de base de datos: SELECT pg_database_size(current_database())
    ejecutado directamente contra Postgres (mismo DATABASE_URL que backup.yml).
    Esto es un proxy razonable de la cuota de "500 MB database size" que
    Supabase factura, no una lectura idéntica al medidor interno de billing
    — puede haber un margen pequeño de diferencia. Ver:
    https://supabase.com/docs/guides/platform/database-size
  - Utilización de disco físico (señal complementaria, no la misma métrica):
    GET /v1/projects/{ref}/config/disk/util — endpoint real y documentado.
    https://supabase.com/docs/reference/api/v1-get-disk-utilization

  - Egreso (bandwidth): NO existe un endpoint público estable para leerlo en
    tiempo real. Se deja fuera de este script a propósito. La única alerta
    automática de egreso es el correo nativo de Supabase al superar cuota
    (capa 1 de la estrategia de monitoreo — ver docs/plan-maestro.md §8).
    No simular este dato con un número inventado.

Uso: python3 calcular_uso.py --db-bytes <bytes> [--disk-used-bytes <bytes>
                                --disk-size-bytes <bytes>] "$GITHUB_OUTPUT"
"""
import argparse
import sys

LIMITE_DB_MB = 500
UMBRAL_PORCENTAJE = 80


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--db-bytes", type=int, required=True,
                         help="Resultado de pg_database_size(), en bytes.")
    parser.add_argument("--disk-used-bytes", type=int, default=None,
                         help="fs_used_bytes del endpoint de disk util (opcional).")
    parser.add_argument("--disk-size-bytes", type=int, default=None,
                         help="fs_size_bytes del endpoint de disk util (opcional).")
    parser.add_argument("github_output", help="Ruta del archivo $GITHUB_OUTPUT.")
    args = parser.parse_args()

    db_mb = args.db_bytes / (1024 * 1024)
    pct_db = round(db_mb / LIMITE_DB_MB * 100, 1)

    disk_disponible = args.disk_used_bytes is not None and args.disk_size_bytes is not None
    pct_disk = None
    if disk_disponible:
        pct_disk = round(args.disk_used_bytes / args.disk_size_bytes * 100, 1)

    supera_umbral = pct_db >= UMBRAL_PORCENTAJE
    if disk_disponible and pct_disk >= UMBRAL_PORCENTAJE:
        supera_umbral = True

    with open(args.github_output, "a") as f:
        f.write(f"db_mb={db_mb:.2f}\n")
        f.write(f"pct_db={pct_db}\n")
        f.write(f"disk_disponible={'true' if disk_disponible else 'false'}\n")
        if disk_disponible:
            f.write(f"pct_disk={pct_disk}\n")
        f.write(f"supera_umbral={'true' if supera_umbral else 'false'}\n")

    resumen = f"DB: {db_mb:.1f} MB de {LIMITE_DB_MB} MB ({pct_db}%)"
    if disk_disponible:
        resumen += f" | Disco: {pct_disk}%"
    else:
        resumen += " | Disco: no consultado (secrets de Management API no configurados)"
    resumen += " | Egreso: no verificable por API — depende de la alerta nativa de Supabase por correo."
    print(resumen)


if __name__ == "__main__":
    main()
