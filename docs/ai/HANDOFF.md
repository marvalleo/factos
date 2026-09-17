# FACTOS — Handoff

> Este archivo se **reemplaza completo** en cada cierre de sesión, no se
> acumula. Si necesitas ver traspasos anteriores, están en el historial de
> Git de este mismo archivo (`git log -p docs/ai/HANDOFF.md`), no aquí.

```yaml
ultimo_agente: Codex
estado: listo_para_coordinacion_con_claude
rama: main
ultimo_commit: 37a9484 chore(init): import FACTOS baseline
tarea: Prueba de coordinación Codex → Claude — entrega de bootstrap
fecha: 2026-09-17
```

## Trabajo realizado

- Verifiqué el paquete oficial `factos-repo.tar.gz` contra el SHA-256
  `1cc418d2f7c52eb91e5c664e7343e7fcf961d00e6e19d3c2da6ee97d185d5341`.
- Extraje el árbol fuente, inicialicé Git en `main` y publiqué el commit
  inicial en `origin/main` (`https://github.com/marvalleo/factos.git`).
- Confirmé que los 22 archivos versionados están normalizados a LF mediante
  `.gitattributes`; no hay archivos `.ps1` actuales.

## Archivos modificados

- `docs/ai/HANDOFF.md` (reemplazado para esta entrega de Codex).

## Pruebas ejecutadas y resultados

- SHA-256 del paquete: coincide exactamente con el valor oficial.
- Integridad del tar: correcta (`tar -tzf`).
- Normalización de finales de línea: correcta (`git ls-files --eol`, índice y
  worktree en LF).
- Índice inicial: correcto (`git diff --cached --check`, sin errores).
- Publicación: `main` sigue a `origin/main` y ambos apuntan a `37a9484`
  antes de este handoff.

## Decisiones tomadas

- El tar de importación no se versionó: fue validado, extraído y retirado para
  evitar duplicar el árbol fuente dentro del repositorio.
- Se preservó el `.gitattributes` provisto por el paquete: LF global y CRLF
  exclusivamente para futuros archivos `.ps1`.

## Problemas encontrados

- Ninguno en el repositorio. Hubo una falla transitoria del sandbox local de
  Codex antes de esta entrega; el acceso al workspace ya está operativo.

## Cambios incompletos

- Ninguna tarea de CP-1 fue iniciada ni modificada.
- La segunda mitad de la prueba de coordinación está pendiente: Claude debe
  leer el repositorio, explicar el estado, reemplazar este handoff y hacer su
  propio commit.

## Próximo paso exacto

Claude debe clonar o actualizar `main`, leer `AGENTS.md`/`CLAUDE.md` y los
documentos de `docs/ai/`, verificar el estado de Git y realizar su commit de
handoff. Después, Codex debe leer ese commit y confirmar que entiende la
entrega de Claude antes de documentar el módulo de preguntas y el grafo de
fuentes.

## Archivos que no deben tocarse sin motivo explícito

- `migrations/001_esquema_base.sql` y `migrations/002_gobernanza_evidencia.sql`.
- La tabla de ADR-01..15 dentro de `docs/plan-maestro.md` §6.

## Preguntas para Marcelo

Ninguna. La prueba puede continuar con Claude usando el remoto publicado.
