# FACTOS — Protocolo compartido (Codex + Claude Code)

Este archivo lo lee cualquier agente que trabaje en este repositorio, sin
excepción. Es el único punto donde las reglas duras del proyecto están
garantizadas de estar visibles para ambos, independientemente de qué archivo
de entrada usó cada uno (`AGENTS.md` o `CLAUDE.md`).

---

## 1. Reglas duras del proyecto — no negociables por ningún agente

Estas reglas están definidas con detalle en `docs/plan-maestro.md` y
`CLAUDE.md`. Se repiten aquí en forma resumida porque Codex no abre
`CLAUDE.md` por defecto, y esta es la garantía de que ambos agentes trabajan
con la misma base, no con memorias distintas de la misma regla.

- **Ninguna verificación se publica sin al menos una evidencia archivada**
  (`sha256` + `http_headers` + `snapshot_url` o un motivo documentado de por
  qué no hay snapshot). Forzado por constraint en las migraciones.
- **El rol `analista_partido` nunca escribe en `verificacion`, `evidencia`,
  `afirmacion`, `captura` ni `fuente_cruda`.** Sólo en `analisis_variante`,
  variante `partido`, sobre su propio `autor_id`. Ningún agente agrega ese
  rol a ninguna política de esas tablas, nunca, bajo ningún pretexto de
  conveniencia o de "simplificar el MVP".
- **`revisor_id` sólo puede fijarlo la propia persona autenticada como
  revisor** (trigger `fn_forzar_autoaprobacion`, migración 002).
- **El directorio de contenido generado para el sitio nunca se edita a
  mano.** Sólo el job de exportación (a crear en CP-3) escribe ahí.
- **Toda evidencia archivada lleva `sha256` Y (`snapshot_url` O un motivo
  documentado de su ausencia).** El hash prueba integridad, no procedencia
  ni momento de captura.
- **No modificar una migración ya aplicada. Crear una nueva, numerada
  secuencialmente**, con un comentario en el encabezado explicando qué
  corrige o agrega respecto a la anterior.
- **Egreso de Supabase no es verificable por API de forma confiable** — no
  simular ese dato ni inventar un endpoint. Ver comentarios en
  `.github/workflows/alerta-uso.yml` y `scripts/calcular_uso.py`.
- **Sin secretos en el repo, nunca.** GitHub Secrets para CI, variables de
  entorno del proveedor para runtime.

Si alguna tarea parece requerir romper una de estas reglas, **detenerse y
consultar a Marcelo**, no improvisar una excepción.

---

## 2. Reglas de trabajo compartido

1. Trabajar siempre desde la raíz del repositorio, nunca desde una copia
   parcial o una carpeta temporal fuera del árbol de Git.
2. Leer `docs/ai/PROJECT_STATE.md`, `docs/ai/HANDOFF.md` y `docs/ai/TASKS.md`
   **antes** de modificar cualquier archivo — no asumir que el estado es el
   que se recuerda de una sesión anterior.
3. No comenzar a modificar cambios ajenos sin revisar `git status` y el
   último `HANDOFF.md` primero. Si hay cambios sin commit de otra sesión,
   **no continuar automáticamente** — inspeccionar el diff y reportarlo
   antes de tocar nada.
4. No reescribir en silencio una decisión ya aprobada (un ADR cerrado, una
   sección del plan maestro marcada como resuelta, un checkpoint ya
   cerrado). Un cambio de eso es un cambio formal — ver `plan-maestro.md`
   §10 — y requiere que quede registrado, no una edición que borra el
   rastro de qué decía antes.
5. Ejecutar las validaciones y pruebas obligatorias que correspondan a la
   tarea (`docs/checkpoints.md` define las de cada checkpoint) **antes**
   de dar por cerrada una tarea o hacer el traspaso.
6. Toda decisión arquitectónica nueva y no trivial se documenta como ADR en
   `docs/decisions/` — ver §4 más abajo sobre numeración.
7. Una rama por tarea, nunca una rama compartida entre tareas distintas ni
   una rama "del agente". `main` permanece estable; sólo recibe merges de
   ramas que ya cumplieron sus criterios de aceptación.

---

## 3. Inicio de sesión (checklist obligatorio)

1. Leer el archivo de entrada propio (`AGENTS.md` o `CLAUDE.md`).
2. Leer este archivo completo.
3. Leer `docs/ai/PROJECT_STATE.md`.
4. Leer `docs/ai/HANDOFF.md`.
5. `git status` — confirmar árbol limpio o entender por qué no lo está.
6. Revisar los últimos 3-5 commits del repositorio.
7. Confirmar en `docs/ai/TASKS.md` cuál es la tarea activa asignada.
8. Sólo entonces, empezar a modificar archivos.

---

## 4. Decisiones arquitectónicas (ADR) — numeración

`docs/plan-maestro.md` §6 ya contiene una tabla de decisiones tecnológicas
cerradas antes de CP-1 (identificadas ahí como ADR-01 a ADR-15). **Esa tabla
está cerrada y no se extiende.** Las decisiones arquitectónicas nuevas, que
surjan durante el trabajo de Codex o Claude Code a partir de CP-1, se
documentan como archivos independientes en `docs/decisions/`, con su propia
numeración de cuatro dígitos empezando en `0001`:

```
docs/decisions/ADR-0001-<slug-descriptivo>.md
docs/decisions/ADR-0002-<slug-descriptivo>.md
```

Nunca reutilizar el formato `ADR-01` de dos dígitos para un archivo nuevo —
es deliberadamente distinto para que nadie confunda una decisión de la tabla
histórica con un archivo nuevo. Ver `docs/decisions/README.md` para la
plantilla.

---

## 5. Cierre de sesión (checklist obligatorio)

1. Ejecutar las pruebas correspondientes a la tarea. Registrar resultado
   real, no "debería pasar".
2. Actualizar `docs/ai/TASKS.md`: estado de la tarea, commit de cierre si
   corresponde.
3. Actualizar `docs/ai/PROJECT_STATE.md` **solamente si cambió el estado
   global** (un checkpoint se cerró, una decisión bloqueante se resolvió).
   No tocar este archivo por cambios menores — para eso está `TASKS.md`.
4. Reemplazar `docs/ai/HANDOFF.md` completo con la entrega actual — no
   agregar al final, no dejar entradas viejas mezcladas con la nueva.
5. Commit con mensaje identificable (qué se hizo, no "wip" o "avances").
6. `git status` limpio antes de terminar. Si algo queda a medio hacer,
   documentarlo en `HANDOFF.md` explícitamente — nunca dejarlo implícito
   en el diff sin comentar.

Si una sesión se interrumpe sin poder cerrar limpio, el siguiente agente en
retomar debe encontrar eso reflejado honestamente en `HANDOFF.md`, no
descubrirlo por sorpresa en el diff.
