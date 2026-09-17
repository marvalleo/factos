# FACTOS — Checkpoints: entregables, criterios, pruebas y exclusiones

> Responde a la Q1 de la revisión externa: `plan-maestro.md` describía las fases
> en prosa; esto formaliza cada checkpoint en un formato auditable. Es este
> documento, no la prosa del plan, el que se usa para decidir si un CP está
> realmente cerrado.
>
> **Versión:** 1.0

---

## CP-1 — Núcleo de datos y plataforma

### Entregables (artefactos concretos, verificables por inspección)

1. `migrations/001_esquema_base.sql` + `migrations/002_gobernanza_evidencia.sql` aplicadas sobre un proyecto Supabase Free real, sin errores.
2. Harvester Python funcional contra `opendata.camara.cl`, acotado al **piloto** definido en §Piloto más abajo — no contra todo el histórico.
3. Cada corrida del harvester deja: fila en `interno.corrida`, N filas en `interno.fuente_cruda` con manifiesto completo (archivo + `sha256` + `http_headers` + `obtenido_en` + `snapshot_url` o `snapshot_no_disponible_motivo`), N filas parseadas en tablas públicas con `localizador` exacto.
4. Job de GitHub Actions `keep-alive.yml`: ping trivial a Supabase, programado con frecuencia menor a 7 días.
5. Job de GitHub Actions `backup.yml`: `pg_dump` completo → Cloudflare R2, con log de éxito/fallo.
6. Job de GitHub Actions `alerta-uso.yml`: mide tamaño real de la base vía `pg_database_size` (SQL directo) y, opcionalmente, utilización de disco vía el endpoint documentado `GET /v1/projects/{ref}/config/disk/util`; abre issue al 80 % de cualquiera de las dos. **Egreso queda fuera** — no existe endpoint público estable para leerlo; depende del correo nativo de Supabase (ver corrección post-revisión externa en `CLAUDE.md`).
7. Suite de tests (pgTAP o equivalente) que cubre exactamente los casos de §Pruebas obligatorias.

### Criterios de aceptación (todos, no algunos)

- [ ] Al menos 15 votaciones nominales reales del piloto están en la base, cada una con su `fuente_cruda` archivada y verificable de forma independiente (alguien fuera del equipo puede tomar el `sha256` y confirmar contra el archivo).
- [ ] `keep-alive`, `backup` y `alerta-uso` corrieron **al menos dos veces cada uno** en fechas distintas, con evidencia en los logs de GitHub Actions (no basta con que el YAML exista sin haber corrido).
- [ ] La restauración del backup se ejecutó una vez de punta a punta contra un proyecto Supabase de prueba, y el tiempo que tomó quedó registrado.
- [ ] Cero secretos en el repo (verificado con `git log -p` sobre todo el historial, no sólo el HEAD).

### Pruebas obligatorias (automatizadas, no manuales)

| # | Prueba | Qué demuestra |
|---|---|---|
| T1 | Insertar `verificacion` con `estado='publicada'` y sin filas en `verificacion_evidencia` → debe fallar | La regla dura de publicación (Q del contrato original) |
| T2 | Insertar evidencia con `fuente_cruda` cuyo `storage_path` o `sha256` es null → la publicación que dependa de ella debe fallar | La evidencia debe estar realmente archivada, no sólo referenciada |
| T3 | Insertar `fuente_cruda` sin `snapshot_url` ni `snapshot_no_disponible_motivo` → debe fallar (constraint Q7) | El manifiesto de evidencia es obligatorio, no aspiracional |
| T4 | Como usuario con rol `anon`, intentar leer una `verificacion` en estado `borrador` → debe devolver cero filas | RLS funciona, no sólo existe |
| T5 | Como usuario con rol `analista_partido`, intentar `UPDATE` sobre `verificacion.resumen_hecho` → debe fallar por RLS | Aislamiento Q5: el partido no puede tocar Capa 1/2 |
| T6 | Como usuario `editor`, fijar `revisor_id` a un UUID que no es el propio `auth.uid()` → debe fallar por el trigger `fn_forzar_autoaprobacion` | Cierre del gap Q6 |
| T7 | Publicar una verificación, luego corregirla → debe existir una fila nueva en `verificacion_revision` con la versión anterior intacta, y la fila anterior de esa tabla no debe haber cambiado | Modelo de versionado Q3 |
| T8 | Correr el harvester dos veces sobre el mismo rango de fechas → la segunda corrida no debe duplicar `fuente_cruda` (dedupe por `sha256` o por URL+fecha) | Idempotencia — evita inflar el storage con archivos idénticos |

### Explícitamente fuera de CP-1

- Redacción de fichas o publicación de ninguna verificación real (eso es CP-2).
- Panel de redacción con interfaz — CP-1 puede operarse con SQL directo o un script CLI mínimo. La UI es CP-2.
- Cosecha de DIPRES, Mercado Público o BCN — sólo `opendata.camara.cl` en CP-1.
- Cualquier trabajo de Hermes / detección de afirmaciones — eso es CP-5.
- Sitio público, build de Astro, dominio — eso es CP-3/CP-4.
- Video, audio, transcripción — CP-7.

### Bloqueo conocido, no bloqueante para CP-1 mismo

D5 (revisión legal completa) no bloquea CP-1. Sí bloquea CP-3. Pero según Q10 de la revisión, **una pasada legal preliminar sobre el modelo de datos** (qué se conserva, por cuánto tiempo, cómo se corrige, cómo se cita) debería ocurrir antes de cerrar CP-1, no antes de CP-3. Ver `docs/plan-maestro.md` sección de decisiones para el estado exacto de esto.

---

## CP-2 — Panel interno y primeras fichas (piloto real)

### Piloto — números concretos (responde a Q8)

- **Universo:** votaciones nominales de la Cámara de Diputados, período: legislatura en curso (últimos ~12 meses a la fecha de cosecha). Acotado y reciente para que los datos sean comparables entre sí.
- **Actores:** 5 a 8 diputados, elegidos por el criterio de priorización de `contrato-editorial.md` (impacto, alcance, verificabilidad) — **no por afinidad política.** Es la primera aplicación práctica de la regla de simetría S1/S2: si el primer lote ya está sesgado a un sector, el proyecto arranca contradiciendo su propio criterio.
- **Fuentes permitidas en este piloto:** únicamente `opendata.camara.cl`. Se excluye Mercado Público hasta tener el ticket, y DIPRES/BCN hasta CP-5 o cuando A6 lo requiera para un caso concreto.
- **Volumen:** 15–20 candidatas ingeridas en CP-1 → **10 fichas redactadas y publicadas** en CP-2, seleccionadas de ese pool según el criterio D3, no todas las candidatas se convierten en ficha.
- **Evidencias por ficha:** 1–2 en promedio (la mayoría se resuelve contra un solo registro de votación). El esquema soporta N; no diseñar el piloto asumiendo que siempre habrá una sola.

### Entregables

1. Panel mínimo (puede ser un formulario simple, no necesita ser elaborado) sobre Supabase Auth, con los tres roles operativos: `verificador`, `revisor`, `editor`.
2. 10 fichas en `estado='publicada'`, cada una con su fila correspondiente en `verificacion_revision` (versión 1).
3. Al menos una ficha con veredicto `exacto` y al menos una con `impreciso` o `falso` — el piloto no puede ser sólo negativo (ver `contrato-editorial.md`, "por qué importa publicar los exactos").
4. Distribución por actor documentada (regla S3 de transparencia trimestral, aplicada por primera vez a escala de piloto).

### Criterios de aceptación

- [ ] Las 10 fichas pasan validación contra `schemas/ficha.schema.json` sin errores.
- [ ] Ninguna fila de `verificacion` tiene `verificador_id = revisor_id`.
- [ ] MFA activo en las cuentas de quienes operan el panel (mínimo TOTP).
- [ ] La distribución por actor no está concentrada en un solo sector (regla S1/S2 aplicada, no sólo declarada).

### Explícitamente fuera de CP-2

- Sitio público — las fichas existen en la base, no en un sitio visible por terceros todavía.
- El análisis de Capa 3 (`analisis_variante`) puede quedar vacío en esta fase si no hay analista de partido asignado aún; no es bloqueante para publicar Capa 1/2.

---

## CP-3 — Sitio público estático y capa de red

*(resumen breve — detalle completo pendiente de la misma formalización si se solicita; se prioriza CP-1/CP-2 primero por ser lo inmediato)*

**Gate de entrada, no de salida:** D5 (revisión legal completa) debe estar cerrada **antes** de que el build sea accesible por cualquier persona fuera del equipo, incluso en subdominio de prueba. Éste es el punto exacto donde Q10 exige más precisión que la que tenía el plan v2.0: la revisión legal preliminar (modelo de datos) ocurre antes de CP-1; la revisión legal completa (contenido publicado, términos de uso) ocurre antes de CP-3.

**Entregables mínimos:** build de Astro en dos variantes (C6), consumiendo exclusivamente el export validado (ver regla de ruta única de publicación más abajo), Cloudflare delante, prueba de carga documentada.

---

## Regla de ruta única de publicación (responde a Q4)

**El problema exacto que señala la revisión:** una constraint en Supabase impide que se inserte una fila inválida en la base. No impide que alguien edite a mano un archivo JSON en el repo y que Astro lo publique igual, sin pasar por Supabase ni por sus constraints.

**La solución, en tres partes:**

1. **El directorio de contenido generado nunca se edita a mano.** Se declara explícitamente en `CLAUDE.md` y se refuerza con `CODEOWNERS`: cualquier PR que modifique `content/generado/**` sin que el commit provenga del job de exportación automática se rechaza en revisión.
2. **Job de exportación única fuente:** un GitHub Action (`export-contenido.yml`) es el **único** proceso autorizado a escribir en `content/generado/`. Lee de Supabase (sólo `estado='publicada'`), valida cada ficha contra `schemas/ficha.schema.json`, y confirma que el `hash_contenido` de cada ficha coincide con el que Supabase calculó al publicar — si no coincide, el job falla en vez de escribir un archivo corrupto.
3. **Gate de CI en cada PR:** `verificar-contenido.yml` re-ejecuta la exportación contra el estado actual de Supabase y compara byte a byte con lo committeado. Si difieren, la build falla. Esto hace mecánicamente imposible que el sitio público muestre algo que Supabase no respalda — no depende de que nadie recuerde la regla.

Este mecanismo es el que responde a la pregunta de fondo: **Astro nunca es la fuente de verdad de ningún dato; siempre es un espejo verificado de Supabase.**

---

## Estimación de almacenamigo — responde a Q9

Cálculo explícito, no una regla vaga de "cuando se acerque el límite":

| Escala | Archivos de evidencia estimados | Tamaño promedio por archivo | Total estimado |
|---|---|---|---|
| Piloto (CP-1/CP-2): 15–20 fichas | ~30–40 (mezcla de XML de votación, livianos) | ~0,2–1 MB | **< 40 MB** — muy por debajo de cualquier cuota gratuita |
| 500 fichas (primer disparador) | ~1.000 (mezcla XML + algunos PDF de DIPRES) | ~2 MB | **~2 GB** |
| 5.000 fichas | ~10.000 | ~2 MB | **~20 GB** |

**Consecuencia concreta:** a 500 fichas, 2 GB ya supera el ~1 GB de Supabase Storage Free. Por eso `interno.fuente_cruda.storage_path` debe apuntar preferentemente a **R2** (mayor cuota gratuita), reservando Supabase Storage para archivos operativos pequeños del panel. Esto corrige ADR-05: no es "Supabase Storage + R2" como opciones equivalentes, es **R2 primero para evidencia, Supabase Storage sólo para lo liviano.**

A 5.000 fichas, 20 GB probablemente ya exige revisar el plan gratuito de R2 vigente en ese momento — el disparador correspondiente en `plan-maestro.md` §11 ("Storage de evidencia cerca del límite combinado") debe leerse con este número real, no como una alarma abstracta.

**Backup de los archivos, no sólo de la base:** el `pg_dump` cubre metadatos y texto. Los archivos de evidencia en R2 no tienen versionado gratuito garantizado. La mitigación real es que **el snapshot de archive.org cumple doble función**: prueba de procedencia/momento (Q7) y copia de respaldo fuera de nuestra infraestructura. Es la razón por la que la constraint `fuente_cruda_snapshot_o_motivo` (migración 002) es dura y no opcional.

---

## Nota de posicionamiento (adoptada)

Se corrige la formulación del objetivo en toda la documentación: FACTOS no se presenta como "fuente de verdad", que promete infalibilidad y es indefendible ante el primer error. Se presenta como **sistema de verificación trazable y corregible** — que es exactamente lo que la arquitectura puede demostrar técnicamente: cada dato tiene origen verificable, cada corrección queda registrada, nada se publica sin evidencia archivada. Ver actualización en `docs/plan-maestro.md`.
