# FACTOS — Registro de decisiones arquitectónicas (ADR)

## Por qué este directorio, y por qué no continúa la numeración anterior

`docs/plan-maestro.md` §6 tiene una tabla de 15 decisiones tecnológicas
(identificadas ahí como `ADR-01` a `ADR-15`) cerradas **antes** de que
existiera este flujo de coordinación entre Codex y Claude Code. Esa tabla
está cerrada y no se extiende con archivos nuevos.

Toda decisión arquitectónica que surja a partir de CP-1 en adelante —
elegida por Codex, por Claude Code, o discutida con Marcelo— se documenta
acá como un archivo independiente, con numeración de **cuatro dígitos**
para que nunca se confunda con la tabla histórica de dos dígitos:

```
docs/decisions/ADR-0001-<slug-descriptivo>.md
docs/decisions/ADR-0002-<slug-descriptivo>.md
```

## Cuándo escribir un ADR

Cuando la decisión:
- Es difícil o costosa de revertir.
- Afecta a ambos agentes (Codex y Claude Code deben conocerla igual).
- Cierra una alternativa que alguien podría razonablemente proponer de
  nuevo más adelante sin saber que ya se descartó, y por qué.

Ejemplos del tipo de decisión que corresponde documentar aquí (no
implica que estas específicas ya estén decididas — son ilustrativas):
por qué se implementa primero sobre PostgreSQL y no sobre una base
gráfica externa para el mapa de fuentes; por qué se separa el contenido
de candidatas del contenido publicado en tablas distintas en vez de un
único campo de estado; por qué un nuevo componente se agrega o se
descarta.

## Plantilla

```markdown
# ADR-0001 — <título corto>

**Estado:** propuesta | aceptada | rechazada | superada por ADR-00NN
**Fecha:** AAAA-MM-DD
**Decide:** Codex | Claude Code | Marcelo | conjunta

## Contexto

Qué problema o pregunta llevó a esta decisión.

## Decisión

Qué se decidió, en una o dos frases directas.

## Alternativas consideradas

Qué otras opciones se evaluaron y por qué se descartaron.

## Consecuencias

Qué se vuelve más fácil, qué se vuelve más difícil, qué queda cerrado.
```

Ningún agente cambia una decisión documentada aquí como "aceptada" sin
crear un ADR nuevo que la marque como "superada por" y explique por qué —
nunca editando el archivo original para que diga otra cosa.
