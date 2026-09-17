# FACTOS — Tareas

> Cada tarea nueva se agrega con un ID secuencial `T-CP1-NN` (o `T-CP2-NN`,
> etc., según el checkpoint al que pertenece). Los IDs `T1`–`T8` mencionados
> en `docs/checkpoints.md` para las pruebas obligatorias de CP-1 se
> referencian tal cual, no se renombran aquí, para que ambos documentos
> hablen del mismo identificador.

## CP-1 — Núcleo de datos y plataforma

### T-CP1-01 · Aplicar migraciones contra Supabase real
- **Descripción:** crear proyecto Supabase Free, aplicar `001` y luego `002`
  en orden, confirmar sin errores.
- **Estado:** sin_asignar
- **Responsable:** sin asignar
- **Rama:** `feat/aplicar-migraciones`
- **Dependencias:** ninguna — es la tarea de arranque.
- **Criterios de aceptación:** ver `docs/checkpoints.md` §CP-1, entregable 1.
- **Commit de cierre:** —

### T-CP1-02 · Harvester `opendata.camara.cl` (piloto)
- **Descripción:** harvester Python determinista, acotado al piloto (15–20
  candidatas, votaciones nominales, legislatura en curso, 5–8 actores
  elegidos por criterio de priorización — no por afinidad política).
- **Estado:** sin_asignar
- **Responsable:** sin asignar
- **Rama:** `feat/harvester-camara-piloto`
- **Dependencias:** T-CP1-01 (necesita el esquema aplicado para escribir
  en `interno.fuente_cruda`).
- **Criterios de aceptación:** ver `docs/checkpoints.md` §CP-1, entregables
  2–3, y pruebas T1–T3, T8.
- **Commit de cierre:** —

### T-CP1-03 · Configurar y probar `keep-alive.yml`
- **Descripción:** configurar secrets `SUPABASE_URL`, `SUPABASE_ANON_KEY`;
  correr el workflow al menos dos veces en fechas distintas.
- **Estado:** sin_asignar
- **Responsable:** sin asignar
- **Rama:** `chore/secrets-keep-alive`
- **Dependencias:** T-CP1-01 (la tabla `tema` debe existir para HTTP 200 real).
- **Criterios de aceptación:** ver `docs/checkpoints.md` §CP-1, criterio de
  aceptación "keep-alive corrió al menos dos veces".
- **Commit de cierre:** —

### T-CP1-04 · Configurar y probar `backup.yml` + restauración real
- **Descripción:** configurar secrets de R2 y `SUPABASE_DB_URL`; correr el
  backup al menos dos veces; ejecutar **una restauración completa** contra
  un proyecto Supabase de prueba y documentar el tiempo que tomó.
- **Estado:** sin_asignar
- **Responsable:** sin asignar
- **Rama:** `chore/secrets-backup`
- **Dependencias:** T-CP1-01.
- **Criterios de aceptación:** ver `docs/checkpoints.md` §CP-1 — la prueba
  de restauración es explícitamente un criterio de cierre de CP-1, no opcional.
- **Commit de cierre:** —

### T-CP1-05 · Configurar y probar `alerta-uso.yml`
- **Descripción:** configurar `SUPABASE_DB_URL` (obligatorio) y, si se
  quiere la señal de disco, `SUPABASE_ACCESS_TOKEN` + `SUPABASE_PROJECT_REF`
  (opcional). Confirmar que abre issue correctamente en un caso simulado
  sobre el 80%.
- **Estado:** sin_asignar
- **Responsable:** sin asignar
- **Rama:** `chore/secrets-alerta-uso`
- **Dependencias:** T-CP1-01.
- **Criterios de aceptación:** el job corre sin error; si se fuerza un caso
  sobre 80%, se abre el issue con el contenido esperado. Recordar: egreso
  no está cubierto por este job — no es un criterio de esta tarea.
- **Commit de cierre:** —

### T-CP1-06 · Pruebas T1–T8 de `docs/checkpoints.md`
- **Descripción:** escribir y correr la suite de pruebas (pgTAP o
  equivalente) que cubre exactamente los ocho casos listados en
  `docs/checkpoints.md` §CP-1 "Pruebas obligatorias".
- **Estado:** sin_asignar
- **Responsable:** sin asignar
- **Rama:** `test/cp1-suite`
- **Dependencias:** T-CP1-01, T-CP1-02 (T8 depende del harvester).
- **Criterios de aceptación:** las ocho pruebas pasan. Ninguna se marca
  como "pasada" sin haber corrido realmente.
- **Commit de cierre:** —

---

## Sin checkpoint asignado todavía

*(vacío — agregar aquí cualquier tarea que surja y no encaje limpiamente en
un CP existente, hasta decidir dónde va)*
