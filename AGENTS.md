# FACTOS — Entrada para Codex

Este repositorio es trabajado de forma **secuencial** por dos agentes distintos:
Codex (este archivo) y Claude Code (`CLAUDE.md`). Nunca en paralelo sobre el
mismo estado — la coordinación es exclusivamente vía Git y los archivos de
`docs/ai/`. Ninguno de los dos agentes puede ver la sesión del otro.

## Orden de lectura obligatorio, antes de tocar nada

1. `docs/ai/PROTOCOL.md` — reglas compartidas, incluye las reglas duras no
   negociables del proyecto. Es lo primero, siempre.
2. `docs/ai/PROJECT_STATE.md` — estado actual, es un índice, no una copia.
3. `docs/ai/HANDOFF.md` — qué dejó el agente anterior (puede haber sido
   Claude, no asumas que fue Codex).
4. `docs/ai/TASKS.md` — cuál es la tarea activa y quién es responsable.
5. `git status` y los últimos commits — para confirmar que lo escrito en
   `HANDOFF.md` coincide con lo que realmente hay en el árbol.

Sólo después de estos cinco pasos, modificar archivos.

## Documentos oficiales del proyecto (no duplicar su contenido aquí)

- `docs/plan-maestro.md` — la biblia. Arquitectura, agentes, contratos, gates.
- `docs/checkpoints.md` — entregables, criterios de aceptación y pruebas
  obligatorias por checkpoint. Es lo que decide si algo está "listo".
- `docs/contrato-editorial.md` — escala de veredictos y criterio de selección.
- `migrations/001_esquema_base.sql` y `migrations/002_gobernanza_evidencia.sql`
  — esquema Supabase. **Nunca editar una migración ya aplicada — crear una
  nueva, numerada.**
- `schemas/ficha.schema.json` — formato de una ficha de verificación.

Si algo en el código contradice `docs/plan-maestro.md`, gana el plan. Si
Codex necesita cambiarlo, eso es un cambio formal (§10 de `plan-maestro.md`),
no una edición silenciosa.

## Reglas específicas para Codex

- Codex normalmente no abre `CLAUDE.md`. Aun así, **`CLAUDE.md` y este
  archivo comparten exactamente las mismas reglas duras** — están repetidas
  en `docs/ai/PROTOCOL.md` para que ningún agente trabaje con información
  distinta. Si tienes dudas sobre una regla, `PROTOCOL.md` es la fuente,
  no la memoria de esta sesión.
- Codex puede leer `CLAUDE.md` de todos modos si quiere contexto adicional
  sobre cómo Claude Code entiende el proyecto — es información, no un
  archivo de configuración exclusivo de otro agente.

## Al terminar cualquier sesión

Seguir el protocolo de cierre completo en `docs/ai/PROTOCOL.md` §"Cierre de
sesión". No es opcional. El siguiente agente en trabajar —sea Codex otra vez
o Claude Code— depende de que `HANDOFF.md` sea preciso, no optimista.
