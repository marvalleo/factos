# FACTOS

Sistema de verificación de hechos sobre gasto público, votaciones y declaraciones
de autoridades, con evidencia documental archivada y trazable. **No se presenta
como "fuente de verdad"** — se presenta como sistema trazable y corregible, que
es lo que la arquitectura puede demostrar. Se construye en dos variantes desde
una sola fuente: un sitio editorial independiente y uno con la lectura del
partido (ver `docs/plan-maestro.md` §0/§4, contrato C6).

## Este repo lo trabajan dos agentes, en secuencia, nunca en paralelo

Codex también trabaja este repositorio, con entrada propia en `AGENTS.md`.
La coordinación es exclusivamente vía Git y `docs/ai/` — ninguno de los dos
agentes puede ver la sesión del otro. **Antes de leer el resto de este
archivo**, lee en este orden:

1. `docs/ai/PROTOCOL.md` — reglas compartidas con Codex, incluye el resumen
   de las reglas duras del proyecto.
2. `docs/ai/PROJECT_STATE.md` — estado actual (índice, no copia).
3. `docs/ai/HANDOFF.md` — qué dejó el agente anterior (puede haber sido Codex).
4. `docs/ai/TASKS.md` — tarea activa y responsable.
5. `git status` y los últimos commits.

## Antes de tocar nada (además de lo anterior)

1. Lee `docs/plan-maestro.md` completo. Es la biblia — gates, agentes,
   contratos, checklist de seguridad. Si algo en el código contradice ese
   documento, gana el documento.
2. Lee `docs/checkpoints.md`. Es la definición **formal** de cada checkpoint:
   entregables concretos, criterios de aceptación, pruebas obligatorias y qué
   queda explícitamente fuera. **Es este documento, no la prosa del plan
   maestro, el que decide si un CP está realmente cerrado.**
3. Lee `docs/contrato-editorial.md`. Escala de veredictos (6 niveles, sin
   excepciones) y criterio de qué se verifica (4 condiciones + reglas de
   simetría S1–S5). Ninguna ficha se redacta sin ceñirse a esto.
4. Revisa `schemas/ficha.schema.json` — contrato C5.
5. Revisa `migrations/001_esquema_base.sql` y luego, **obligatoriamente**,
   `migrations/002_gobernanza_evidencia.sql`. La 002 corrige gaps reales
   detectados en revisión externa (versionado explícito, aislamiento del rol
   `analista_partido`, auto-aprobación forzada, manifiesto de evidencia
   completo). Aplícalas en ese orden. Nunca trabajes sólo contra la 001.

## Reglas duras, no negociables

- **Ninguna verificación se publica sin al menos una evidencia archivada**
  (`sha256` + `http_headers` + `snapshot_url` o motivo documentado por su
  ausencia). Forzado por constraint en las migraciones y validado en el schema.
- **El rol `analista_partido` nunca tiene acceso de escritura a `verificacion`,
  `evidencia`, `afirmacion`, `captura` ni `fuente_cruda`.** Sólo puede escribir
  en `analisis_variante`, variante `partido`, sobre su propio `autor_id`. No
  agregar ese rol a ninguna política de las otras tablas, nunca.
- **`revisor_id` sólo puede fijarlo la propia persona autenticada como
  revisor** (trigger `fn_forzar_autoaprobacion`). Un `editor` no puede simular
  una segunda aprobación fijando ambos IDs.
- **El directorio de contenido generado para el sitio (`content/generado/`)
  nunca se edita a mano.** El único proceso autorizado a escribirlo es el job
  de exportación (`export-contenido.yml`, a crear en CP-3). Cualquier otro
  cambio ahí se rechaza en revisión. Ver `docs/checkpoints.md` §"Regla de
  ruta única de publicación".
- **Toda evidencia lleva `sha256` Y (`snapshot_url` O un motivo documentado
  de por qué no hay snapshot).** El hash prueba integridad, no procedencia ni
  momento de captura — eso lo da el snapshot de un tercero independiente.

## Estado actual

Ver el tablero de checkpoints en `docs/plan-maestro.md` §12 y el detalle de
CP-1 en `docs/checkpoints.md`. **CP-1 es la fase actual.** No adelantarse a
CP-2 (redacción de fichas) ni a fases posteriores salvo que el plan indique
explícitamente paralelismo.

## Piloto de CP-1/CP-2 (números concretos, no aspiracionales)

15–20 candidatas ingeridas de `opendata.camara.cl` (votaciones nominales,
legislatura en curso), 5–8 actores elegidos por el criterio de priorización
del contrato editorial — **no por afinidad política** —, 10 fichas
publicadas en CP-2. Detalle completo en `docs/checkpoints.md` §"Piloto".

## Agentes y límites (resumen — detalle en el plan)

- **Cosecha (harvesters):** determinista, sin LLM. Si un parser no puede leer
  un campo con certeza, debe fallar ruidosamente. Nunca inventa un valor.
- **Captura (Hermes / detección de afirmaciones):** produce candidatas
  (`estado: candidata`), nunca fichas publicadas ni veredictos. **Fuera de
  alcance hasta CP-5** — no empezar esto durante CP-1.
- **Frontend:** el sitio público es estático. Nunca consulta Supabase en
  runtime. Construye ambas variantes (independiente / partido) desde el
  export validado — nunca desde archivos editados a mano.

## Costo

Restricción activa: **USD 0/mes** mientras el uso esté bajo el 80 % de
cualquier cuota del plan Free de Supabase (500 MB base, 5 GB egreso/mes,
50k MAU). Estimación real de storage con archivos de evidencia en
`docs/checkpoints.md` §"Estimación de almacenamiento": ~2 GB a 500 fichas ya
supera la cuota de Supabase Storage — por eso la evidencia va **primero a
R2**, Supabase Storage sólo para archivos operativos livianos.

Jobs ya escritos en `.github/workflows/` (requieren configurar secrets antes
de que corran de verdad — ver cabecera de cada archivo):
- `keep-alive.yml` — evita pausa de Supabase a los 7 días de inactividad.
  Secrets: `SUPABASE_URL`, `SUPABASE_ANON_KEY`. Exige HTTP 200 exacto — no
  acepta 401/403/404/429 como éxito (corrección tras revisión externa: la
  primera versión sí los aceptaba, lo que podía dejar el job en verde con
  una credencial rota).
- `backup.yml` — `pg_dump` semanal → R2. Secrets: `SUPABASE_DB_URL`,
  `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_ENDPOINT`,
  `R2_BUCKET_BACKUPS`. La **restauración** no está automatizada a propósito
  — se prueba manualmente (comando al final del archivo), y es criterio de
  aceptación de CP-1 en `docs/checkpoints.md`.
- `alerta-uso.yml` — mide tamaño real de la base con una consulta SQL
  directa (`pg_database_size`, secret `SUPABASE_DB_URL`, el mismo que
  `backup.yml`) y, opcionalmente, utilización de disco físico vía el
  endpoint documentado `GET /v1/projects/{ref}/config/disk/util` (secrets
  `SUPABASE_ACCESS_TOKEN` + `SUPABASE_PROJECT_REF`, señal complementaria, no
  la misma métrica). **Egreso queda explícitamente fuera** — no existe un
  endpoint público estable para leerlo; depende sólo del correo nativo de
  Supabase. La primera versión de este archivo asumía un endpoint
  `/v1/projects/{ref}/usage` que no existe públicamente documentado en esa
  forma — corregido tras revisión externa, no es un supuesto vigente.

Ninguno de los tres ha corrido todavía en producción — están escritos,
validados sintácticamente (YAML + Bash + Python), pero no probados contra un
proyecto Supabase real. Correrlos al menos dos veces cada uno con secrets
reales es parte
de los criterios de aceptación de CP-1 (`docs/checkpoints.md`).

## Secretos

Nunca en el repo. GitHub Secrets para CI, variables de entorno del proveedor
para runtime. `service_role` de Supabase sólo en build y panel interno.

## Estructura del repo

```
AGENTS.md                       ← entrada para Codex (análogo a este archivo)
CLAUDE.md                       ← este archivo
docs/
  ai/
    PROTOCOL.md                 ← reglas compartidas con Codex. Léelo primero.
    PROJECT_STATE.md            ← índice de estado, no una copia del plan.
    HANDOFF.md                  ← entrega del último agente (puede ser Codex).
    TASKS.md                    ← tareas activas y responsables.
  decisions/
    README.md                  ← convención de ADRs nuevos (numeración 0001+,
                                   separada de la tabla histórica ADR-01..15).
  plan-maestro.md              ← la biblia. Empezar por acá.
  checkpoints.md               ← definición formal de CP-1..CP-8. Úsalo para
                                  saber si terminaste, no la prosa del plan.
  contrato-editorial.md        ← veredictos y criterio de selección
  arquitectura.md               ← seguridad, escalabilidad, descubribilidad
  historial/                    ← versiones anteriores, por trazabilidad
schemas/
  ficha.schema.json             ← contrato C5
migrations/
  001_esquema_base.sql          ← esquema original
  002_gobernanza_evidencia.sql  ← OBLIGATORIA. Corrige gaps de gobernanza.
.github/workflows/               ← keep-alive, backup, alerta-uso: escritos,
                                    validados sintácticamente; pendientes de
                                    pruebas reales en CP-1
```

## Al terminar cualquier tarea

Sigue el protocolo de cierre completo de `docs/ai/PROTOCOL.md` §5 —
pruebas ejecutadas, `TASKS.md` actualizado, `PROJECT_STATE.md` actualizado
sólo si cambió el estado global, `HANDOFF.md` reemplazado por completo (no
agregado), commit identificable, árbol limpio. Es lo que permite que Codex
retome el trabajo sin tener que adivinar qué quedó hecho.

Adicionalmente: actualiza la bitácora en `docs/plan-maestro.md` §12: qué
agente, qué fase, qué avanzó, qué quedó bloqueado. Si alguna prueba de
`docs/checkpoints.md` §"Pruebas obligatorias" todavía no pasa, el
checkpoint no se marca como cerrado, sin excepción.
