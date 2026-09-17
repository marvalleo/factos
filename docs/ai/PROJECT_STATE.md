# FACTOS — Estado del proyecto (índice)

> Este archivo es un **índice**, no una copia. Si algo aquí contradice
> `docs/plan-maestro.md`, gana `plan-maestro.md` y este archivo está
> desactualizado — corregirlo, no seguirlo. La tabla de checkpoints
> canónica vive en `plan-maestro.md` §12, no aquí.
>
> Actualizar este archivo sólo cuando cambia el **estado global**: se cierra
> un checkpoint, se resuelve una decisión bloqueante, cambia el checkpoint
> activo. No actualizar por avances parciales de una tarea — eso va en
> `docs/ai/TASKS.md`.

**Última actualización:** 2026-09-17 · **Actualizado por:** Claude (sesión de coordinación inicial)

---

## Qué es FACTOS, en una línea

Sistema de verificación de hechos sobre autoridades y políticos chilenos,
trazable y corregible (no se presenta como "fuente de verdad" — ver
`plan-maestro.md` §0.1). Doble salida desde una sola fuente: sitio editorial
independiente y sitio con la lectura del partido (contrato C6).

## Documentos oficiales (leer ahí, no aquí)

| Documento | Contenido |
|---|---|
| `docs/plan-maestro.md` | Arquitectura, agentes, contratos C1–C6, ADRs, riesgos, bitácora §12 |
| `docs/checkpoints.md` | Entregables, criterios de aceptación y pruebas obligatorias por CP |
| `docs/contrato-editorial.md` | Escala de veredictos (D2), criterio de selección (D3) |
| `migrations/001_esquema_base.sql` | Esquema base Supabase/Postgres |
| `migrations/002_gobernanza_evidencia.sql` | Correcciones de gobernanza — **obligatoria**, aplicar después de 001 |
| `schemas/ficha.schema.json` | Formato de intercambio de una ficha de verificación |

## Decisiones no negociables (resumen — detalle en `PROTOCOL.md` §1)

- Nada se publica sin evidencia archivada.
- `analista_partido` nunca toca Capa 1/2, sólo `analisis_variante`.
- `revisor_id` sólo lo fija la propia persona autenticada como revisor.
- Costo de infraestructura: USD 0/mes mientras el uso esté bajo el 80% de
  cualquier cuota del plan Free de Supabase (ver `plan-maestro.md` §8/§11).

## Checkpoint activo

**CP-1 — Núcleo de datos y plataforma. Abierto, no cerrado.**

Ver `docs/checkpoints.md` §CP-1 para entregables y pruebas T1–T8 exactas.
Ver `docs/plan-maestro.md` §12 para el tablero completo de los 8 checkpoints.

## Componentes existentes al momento de esta entrega

- Esquema y migraciones (001 + 002) — escritos, **no aplicados todavía
  contra un proyecto Supabase real**.
- `schemas/ficha.schema.json` — completo, validado sintácticamente.
- `.github/workflows/keep-alive.yml`, `backup.yml`, `alerta-uso.yml` —
  escritos, validados sintácticamente (YAML + Bash + Python), **ninguno ha
  corrido todavía contra infraestructura real**.
- `docs/` completo: plan maestro, checkpoints, contrato editorial.
- Capa de coordinación Codex/Claude Code (`AGENTS.md`, `CLAUDE.md`,
  `docs/ai/`, `docs/decisions/`) — recién creada, sin uso real todavía.

## Pendiente, en orden

1. Aplicar migraciones 001 y 002 contra un proyecto Supabase Free real.
2. Configurar secrets de GitHub y correr los tres workflows al menos dos
   veces cada uno con infraestructura real.
3. Harvester contra `opendata.camara.cl` (piloto: 15–20 candidatas).
4. Cerrar las pruebas T1–T8 de `docs/checkpoints.md`.

## Bloqueos conocidos

- D5 (revisión legal) — preliminar sobre el modelo de datos, pendiente
  antes de cerrar CP-1. Ver `plan-maestro.md` tabla de decisiones §5.
- Ninguno de los tres workflows tiene secrets configurados aún.
