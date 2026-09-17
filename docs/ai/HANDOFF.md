# FACTOS — Handoff

> Este archivo se **reemplaza completo** en cada cierre de sesión, no se
> acumula. Si necesitas ver traspasos anteriores, están en el historial de
> Git de este mismo archivo (`git log -p docs/ai/HANDOFF.md`), no aquí.

```yaml
ultimo_agente: Claude
estado: coordinacion_confirmada_cp1_sin_iniciar
rama: main
ultimo_commit: a618ec7 docs(handoff): record Codex bootstrap
tarea: Segunda mitad de la prueba de coordinación Codex -> Claude — lectura de main y explicación de estado
fecha: 2026-09-17
```

## Trabajo realizado

- Leí `docs/ai/PROTOCOL.md`, `docs/ai/PROJECT_STATE.md`, `docs/ai/HANDOFF.md`
  (versión de Codex), `docs/ai/TASKS.md`, `docs/checkpoints.md` (sección
  CP-1 y "Piloto") y `docs/plan-maestro.md` §12.
- Verifiqué `git log` y `git status`: HEAD en `a618ec7`, árbol de trabajo
  limpio, `main` sincronizado con `origin/main`.
- Confirmé que la entrega de Codex fue sólo bootstrap del repositorio
  (verificación SHA-256, `git init`, push inicial) — ninguna tarea técnica
  de CP-1 fue tocada.

## Estado del proyecto (resumen para quien continúe)

- **Checkpoint activo: CP-1 — Núcleo de datos y plataforma. Abierto, no
  cerrado.** Nada de CP-1 se ha empezado todavía; sólo existe el andamiaje
  (migraciones 001+002 escritas pero no aplicadas, `ficha.schema.json`
  completo, los tres workflows de GitHub Actions escritos y validados
  sintácticamente pero **ninguno corrió contra infraestructura real**).
- `docs/ai/TASKS.md` lista las 6 tareas de CP-1 (T-CP1-01..06), todas
  `sin_asignar`, sin dueño. **T-CP1-01 (aplicar migraciones 001+002 contra
  un proyecto Supabase real) es el punto de partida obligatorio** — las
  demás dependen de ella.
- Ninguno de los checkboxes de "pruebas obligatorias" de CP-1 en
  `docs/checkpoints.md` está marcado: ni las 15+ votaciones piloto con
  `fuente_cruda` archivada, ni las dos corridas reales de cada workflow
  (`keep-alive.yml`, `backup.yml`, `alerta-uso.yml`), ni la restauración de
  backup probada, ni la verificación de cero secretos en el historial
  completo.
- `docs/plan-maestro.md` §12 (bitácora) sólo tiene la fila de CP-0 cerrado.
  No hay fila para el trabajo de bootstrap de Codex ni para esta sesión —
  lo dejo señalado abajo porque, según el protocolo de cierre, corresponde
  agregarla cuando cambie el estado global real (no en esta sesión, porque
  el estado global de CP-1 sigue sin cambios).

## Archivos modificados

- `docs/ai/HANDOFF.md` (reemplazado completo para este cierre).

## Pruebas ejecutadas y resultados

- No aplica trabajo de código en esta sesión: fue una sesión de lectura y
  coordinación, sin cambios a migraciones, schemas ni workflows.

## Decisiones tomadas

- No inicié ninguna tarea de CP-1 (ni T-CP1-01) en esta sesión: el pedido
  explícito era leer `main`, explicar el estado y dejar el handoff — no
  avanzar CP-1. Empezar una tarea sin asignación clara habría violado la
  regla de "un agente a la vez, coordinado vía Git" si Codex ya estuviera
  trabajando en paralelo sin que yo lo supiera.

## Problemas encontrados

- Inconsistencia menor detectada (no corregida, sólo documentada): el
  HANDOFF.md que dejó Codex describía el estado como si `a618ec7` todavía
  no existiera, pero ese commit ya era HEAD al momento de leerlo — es
  decir, el handoff de Codex no reflejaba su propio commit. Ya no aplica
  tras este reemplazo.

## Cambios incompletos

- Todo CP-1 sigue pendiente desde cero. Nada de las 6 tareas de
  `docs/ai/TASKS.md` fue iniciado.

## Próximo paso exacto

Asignar y ejecutar **T-CP1-01** (aplicar `migrations/001_esquema_base.sql`
y `migrations/002_gobernanza_evidencia.sql` contra un proyecto Supabase
real, en ese orden) en la rama `feat/aplicar-migraciones`. Es la tarea sin
dependencias que desbloquea a las otras cinco. Quien la tome debe releer
`docs/checkpoints.md` §"Pruebas obligatorias" antes de marcarla como
cerrada.

## Archivos que no deben tocarse sin motivo explícito

- `migrations/001_esquema_base.sql` y `migrations/002_gobernanza_evidencia.sql`
  (sólo se tocan para aplicarlas o corregir un gap real, nunca por estilo).
- La tabla de ADR-01..15 dentro de `docs/plan-maestro.md` §6.

## Preguntas para Marcelo

Ninguna. El estado es claro y el siguiente paso técnico (T-CP1-01) no
requiere una decisión de producto, sólo ejecución.
