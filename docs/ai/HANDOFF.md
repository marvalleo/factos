# FACTOS — Handoff

> Este archivo se **reemplaza completo** en cada cierre de sesión, no se
> acumula. Si necesitas ver traspasos anteriores, están en el historial de
> Git de este mismo archivo (`git log -p docs/ai/HANDOFF.md`), no aquí.

```yaml
ultimo_agente: ninguno
estado: sin_iniciar
rama: main
ultimo_commit: (pendiente del primer commit real de trabajo)
tarea: Ninguna tarea de CP-1 iniciada todavía
fecha: 2026-09-17
```

## Trabajo realizado

Ninguno todavía. Esta es la entrega inicial de la capa de coordinación
(este archivo, `PROTOCOL.md`, `PROJECT_STATE.md`, `TASKS.md`,
`docs/decisions/`), preparada antes de que el repositorio exista en disco.

## Archivos modificados

- `AGENTS.md` (nuevo)
- `docs/ai/PROTOCOL.md` (nuevo)
- `docs/ai/PROJECT_STATE.md` (nuevo)
- `docs/ai/HANDOFF.md` (nuevo, este archivo)
- `docs/ai/TASKS.md` (nuevo)
- `docs/decisions/README.md` (nuevo)
- `CLAUDE.md` (actualizado — referencias a la capa de coordinación)

## Pruebas ejecutadas y resultados

No aplica — no hay código de aplicación tocado en esta entrega, sólo
documentación de coordinación.

## Decisiones tomadas

- Numeración de ADRs nuevos separada de la tabla histórica ADR-01..15 (ver
  `PROTOCOL.md` §4 y `docs/decisions/README.md`).
- `plan-maestro.md`, `checkpoints.md` y `contrato-editorial.md` permanecen
  en `docs/`, no se mueven a la raíz — evita reescribir referencias
  cruzadas ya existentes en el resto del repo sin necesidad real.

## Problemas encontrados

Ninguno.

## Cambios incompletos

Todo lo de CP-1 sigue pendiente (ver `docs/checkpoints.md`). Esta entrega
sólo prepara el terreno de coordinación entre Codex y Claude Code.

## Próximo paso exacto

El siguiente agente en trabajar (Codex o Claude Code, según decida
Marcelo) debe iniciar **T1 de CP-1**: aplicar `migrations/001_esquema_base.sql`
y `migrations/002_gobernanza_evidencia.sql` contra un proyecto Supabase Free
real, y confirmar mediante las pruebas T1–T4 de `docs/checkpoints.md` que las
constraints funcionan antes de avanzar a cualquier otra tarea.

## Archivos que no deben tocarse sin motivo explícito

- `migrations/001_esquema_base.sql` — ya aplicado conceptualmente, no editar,
  crear `003_...sql` si algo debe corregirse.
- `migrations/002_gobernanza_evidencia.sql` — mismo criterio.
- La tabla de ADR-01..15 dentro de `docs/plan-maestro.md` §6 — está cerrada.

## Preguntas para Marcelo

Ninguna en esta entrega inicial. Las preguntas prácticas sobre la ruta de
disco y qué agente corre dónde se resolvieron por fuera de este archivo,
directamente con Marcelo, antes de la primera tarea real.
