# FACTOS — Plan maestro consolidado

> Documento rector único. Reemplaza y fusiona: `plan-maestro.md` v1.0, `fase-0.md` v1.0,
> `enmienda-costo-cero.md` v1.2 y `d1-d4-brief-legal.md` v1.0. Esos archivos quedan
> como historial en `docs/historial/`; **este es el que se revisa en cada gate.**
>
> Se revisa en cada checkpoint antes de avanzar. Ningún agente pasa de una fase sin
> que este documento esté actualizado y el gate aprobado.
>
> Complementa a `migrations/001_esquema_base.sql`, `migrations/002_gobernanza_evidencia.sql` (corrige gaps Q3/Q5/Q6/Q7 de la revisión externa), `schemas/ficha.schema.json` y `docs/checkpoints.md` (definición formal de entregables, criterios, pruebas y exclusiones — es ese documento, no la prosa de abajo, el que decide si un CP está cerrado). Cuando haya conflicto
> entre este plan y el código, **gana el plan**: el código se corrige, no el plan,
> salvo que se registre formalmente un cambio (§10).

**Versión:** 2.0 · **Estado global:** Fase 0 — decisiones estructurales cerradas, ADRs de detalle pendientes

---

## 0. Qué cambió respecto a la v1.0 (para quien venga del historial)

- **D1 resuelto:** doble salida desde una sola fuente — sitio independiente y sitio del partido, mismo hecho y evidencia, análisis (Capa 3) distinto. Nuevo contrato C6.
- **D4 resuelto:** Netlify con subdominio gratuito durante validación; dominio propio antes de lanzamiento público real.
- **D5 en gestión:** brief legal entregado, revisión de criterio (no ficha por ficha), gate duro antes de CP-3.
- **Costo:** Supabase **se mantiene** (Free, con spend cap y monitoreo activo), no se reemplaza por Git puro. El export a Git de fichas publicadas sigue existiendo, como capa adicional de integridad, no como reemplazo de la base.
- **RNF-11:** techo de costo USD 0/mes mientras el uso esté bajo el 80 % de cualquier cuota de Supabase.

## 0.1 · Revisión externa previa a CP-1 — correcciones aplicadas

Antes de iniciar CP-1, una revisión técnica externa detectó diez preguntas bloqueantes. Resueltas en `docs/checkpoints.md` y `migrations/002_gobernanza_evidencia.sql`:

- **Q1** (definición exacta de CP-1) → `docs/checkpoints.md`, entregables/criterios/pruebas/exclusiones explícitas.
- **Q2** (qué hacer ahora) → auditar y corregir antes de implementar. Esta sección es esa auditoría.
- **Q3** (modelo de correcciones) → tabla `verificacion_revision`, inmutable, append-only, poblada automáticamente al publicar (migración 002). Deja de depender implícitamente de la auditoría interna.
- **Q4** (ruta única de publicación) → job de exportación única fuente + gate de CI que compara byte a byte contra Supabase. Detalle en `docs/checkpoints.md` §"Regla de ruta única de publicación".
- **Q5** (poder del partido sobre Capa 1/2) → tabla `analisis_variante` separada, rol `analista_partido` sin acceso a `verificacion`/`evidencia`/`afirmacion`/`captura`/`fuente_cruda` (migración 002). Estructural, no convención de equipo.
- **Q6** (roles y auto-aprobación) → trigger `fn_forzar_autoaprobacion`: nadie puede fijar `revisor_id` salvo la propia persona autenticada como revisor (migración 002).
- **Q7** (manifiesto de evidencia) → campos `http_headers`, `metodo_captura`, `snapshot_no_disponible_motivo` agregados a `fuente_cruda`, con constraint que exige snapshot de tercero o motivo documentado (migración 002).
- **Q8** (piloto real) → números concretos en `docs/checkpoints.md` §"Piloto": 15–20 candidatas, 5–8 actores elegidos por criterio no por afinidad, sólo `opendata.camara.cl`, 10 fichas publicadas.
- **Q9** (capacidad del nivel gratuito con archivos) → estimación numérica en `docs/checkpoints.md`: ~2 GB a 500 fichas, ~20 GB a 5.000. Corrige ADR-05: evidencia va primero a R2, no a Supabase Storage.
- **Q10** (momento de la revisión legal) → se distingue revisión legal *preliminar* (modelo de datos, antes de cerrar CP-1) de revisión legal *completa* (antes de CP-3). Ver §5 más abajo.

**Reposicionamiento adoptado:** FACTOS no se presenta como "fuente de verdad" — promete infalibilidad y es indefendible ante el primer error real. Se presenta como **sistema de verificación trazable y corregible**: cada dato tiene origen verificable, cada corrección queda registrada, nada se publica sin evidencia archivada. Esto es lo que la arquitectura puede demostrar técnicamente, y es más defendible que lo que promete la formulación anterior.

---

## 1. Cómo se usa esta biblia

1. **Fuente única de verdad.** Si no está escrito aquí, no está decidido.
2. **Cada checkpoint es un gate**, con Definition of Done (§9). No se cruza a medias.
3. **Los contratos de interfaz (§4) están congelados.** Cambiar uno exige un cambio formal (§10) notificado a todos los agentes afectados.
4. **Seguridad es transversal**, no una fase (§8).
5. **Bitácora al día** (§12) al cierre de cada sesión de trabajo.
6. **Todo lo que se automatiza deja rastro**: corrida, hash, origen.

---

## 2. Modelo de agentes

| Agente | Dominio | Herramientas | Límite duro |
|---|---|---|---|
| **A1 · Plataforma** | Esquema Supabase, RLS, migraciones, Storage, Auth, export a Git, backup | SQL, Supabase CLI, Postgres, GitHub Actions | No decide criterios editoriales ni redacta fichas |
| **A2 · Cosecha** | Harvesters deterministas contra fuentes oficiales; archivado + hash | Python, APIs oficiales, `yt-dlp`, R2/Supabase Storage | **No usa LLM para extraer datos.** Nunca adivina un valor |
| **A3 · Captura (Hermes)** | Detección de afirmaciones verificables desde actas, audio y video | Hermes Agent, `faster-whisper`, `pyannote` | Sólo produce **candidatas**. No publica. No decide veredictos |
| **A4 · Frontend** | Sitio estático (Astro SSG), build en dos variantes (C6), SEO, búsqueda, OG images, JSON-LD | Astro, Netlify, Pagefind | No accede a la base en runtime público. Sólo consume build/JSON |
| **A5 · Seguridad** | Cloudflare/WAF, secretos, backups, auditoría, hardening, runbooks, monitoreo de uso Supabase | Cloudflare, GitHub Actions, Supabase dashboard | Puede **bloquear** un gate. Único con poder de veto técnico |
| **A6 · Editorial** | Escala de veredictos, criterio de selección, plantilla de ficha, análisis por variante, páginas de confianza | Documentación, revisión humana | No escribe código. Define el "qué", no el "cómo" |

**Veto:** A5 detiene cualquier gate con riesgo abierto de severidad alta. A6 detiene cualquier gate que comprometa credibilidad (publicar sin evidencia, título que tergiverse, análisis de partido filtrado a la variante independiente).

**Integrador humano** por encima de los seis: aprueba gates, resuelve conflictos, firma cambios formales (§10).

---

## 3. Roles de contenido — quién dice qué, quién trae el dato

- **Captura** (A3/Hermes): encuentra y fija la afirmación.
- **Evidencia** (A2 + harvesters): trae el dato oficial.
- **Veredicto** (humano, siempre): cruza ambas y decide.

Hermes detecta **afirmaciones verificables**, nunca "mentiras". El criterio de detección es neutro (cuantificable, sobre acto público, contrastable) — el veredicto lo decide la evidencia, no el filtro de búsqueda. Confundir esto reintroduce el sesgo de selección que el criterio D3 existe para prevenir.

---

## 4. Contratos de interfaz — lo que habilita el paralelismo

**C1 · Esquema de base de datos** (`esquema.sql`) — contrato entre A1, A2, A3. Tablas, tipos, constraints, la regla "no se publica sin evidencia".

**C2 · Formato de `fuente_cruda`** — contrato entre A2 y A6. Archivo original + `sha256` + URL + timestamp + `snapshot_url` + localizador.

**C3 · Cola de candidatas** — contrato entre A3 y el verificador humano. `texto_literal` + `actor_id` + `captura_id` + `ts_inicio/fin` + contexto ±60 s + fuente sugerida. Estado inicial siempre `candidata`.

**C4 · Endpoint JSON público** — contrato entre A1, A4 y el mundo externo. `/api/v1/fichas.json`, versionado, estable, expone ambas variantes o un flag `analisis_partido`.

**C5 · Plantilla de ficha** — contrato entre A6 y A4. Tres capas: hecho neutro (siempre, tabla `verificacion`) / evidencia (siempre, tabla `evidencia`) / análisis etiquetado (tabla separada `analisis_variante`, según variante — ver migración 002 y Q5 de la revisión externa en §0.1). Formalizada en `schemas/ficha.schema.json`.

**C6 · Variante de sitio** *(nuevo en v2.0)* — contrato entre A4 y A6. Cada verificación se construye en dos targets: `independiente` y `partido`. Capa 1 y 2 nunca se bifurcan; sólo Capa 3 y el `Organization` del JSON-LD cambian. Un solo contenido de origen, dos salidas de build.

---

## 5. Decisiones estructurales — estado

| # | Decisión | Estado | Resolución |
|---|---|---|---|
| D1 | Independiente vs. partido | ✅ Resuelto | Doble salida, C6. Ver §0 |
| D2 | Escala de veredictos | ✅ Ratificado | `contrato-editorial.md` — 6 niveles, con reglas generales y ejemplos |
| D3 | Criterio de selección | ✅ Ratificado | `contrato-editorial.md` — 4 condiciones + reglas de simetría S1–S5 |
| D4 | Dominio y WHOIS | ✅ Resuelto | Netlify `.netlify.app` en validación; dominio propio + WHOIS privado antes de lanzamiento público |
| D5 | Revisión legal | 🟡 En gestión — **dos pasadas, no una** | Preliminar sobre el modelo de datos (retención, corrección, citas, datos personales) antes de cerrar CP-1; completa (contenido publicado, términos de uso) antes de CP-3. Ver `docs/checkpoints.md` |
| D6 | Congelar contratos C1–C6 | ✅ Congelados | Este documento |
| ADRs 01–15 | Tecnología | ✅ Ratificados con la corrección de costo | Ver §6 |

### ✅ CHECKPOINT 0 — Gate de fundaciones: **CERRADO**
Único pendiente que no bloquea el trabajo técnico: D5 en curso, gate duro antes de CP-3. A partir de aquí, A1–A6 trabajan en paralelo.

---

## 6. ADRs — estado final

| ID | Decisión | Resolución final |
|---|---|---|
| ADR-01 ⚠️ | Generador del sitio | **Astro SSG** |
| ADR-02 | Hosting | **Netlify**, subdominio gratuito hasta validar; Cloudflare delante para WAF/DDoS. Confirmado por precedente propio (sitio regional del partido ya corre así, sin problemas) |
| ADR-03 ⚠️ | Base de datos y auth | **Supabase Free**, con spend cap y monitoreo de uso (§8) |
| ADR-04 ⚠️ | Panel interno | **App propia mínima sobre Supabase Auth** |
| ADR-05 | Almacenamiento de evidencia | **Supabase Storage + Cloudflare R2 free + snapshot en archive.org.** Object-lock diferido a cuando haya presupuesto |
| ADR-06 | Búsqueda | **Pagefind** hasta ~5.000 fichas → Meilisearch |
| ADR-07 | Lenguaje de harvesters | **Python** |
| ADR-08 | Orquestación | **GitHub Actions** — cosecha, backup, keep-alive |
| ADR-09 | Estructura de repos | Contenido exportado a Git (registro inmutable, commits firmados) + código en monorepo |
| ADR-10 | CI/CD | **GitHub Actions** + tests de RLS y constraints obligatorios |
| ADR-11 | Transcripción | **`faster-whisper` local** |
| ADR-12 | Modelos LLM por tarea | Opus 5 arquitectura, Sonnet 5 código, Haiku 4.5 clasificación masiva. Hermes con su modelo local |
| ADR-13 | Secretos | **GitHub Secrets + variables de entorno de Supabase/Cloudflare** |
| ADR-14 | Observabilidad | **UptimeRobot + alertas nativas de Supabase + alerta propia de uso semanal** |
| ADR-15 ⚠️ | Licencia | **CC BY** contenido · a definir licencia de código |

---

## 7. Fases y checkpoints

No estrictamente secuenciales tras CP-0. "Paralelo con" indica qué corre a la vez.

### FASE 1 — Núcleo de datos y plataforma
**Agentes:** A1 (líder), A2, A5 · **Paralelo con:** Fase 4 (A4 maqueta contra fixtures)

- **A1:** aplicar `esquema.sql` en Supabase Free; migraciones versionadas; RLS probada (anon no ve nada fuera de lo publicado); Storage con buckets `capturas`/`fuentes` privados.
- **A2:** harvester determinista contra `opendata.camara.cl` (votaciones + asistencia). XML → hash → `fuente_cruda` → tablas con localizador. Reintentos y checkpoints resumibles.
- **A5:** secretos en GitHub Secrets; job de keep-alive (evita pausa a los 7 días); job de backup `pg_dump` → R2; job de alerta de uso al 80 % de cuota (§8).

**Aceptación:** una votación real entra con `fuente_cruda` archivada y hash verificable; test automatizado confirma que publicar sin evidencia falla; keep-alive y backup probados al menos una vez.

#### ✅ CHECKPOINT 1 — Gate de datos

---

### FASE 2 — Panel interno y primeras fichas
**Agentes:** A1 (líder), A6, A5 · **Paralelo con:** Fase 4

- **A1:** panel sobre Supabase Auth. Flujo candidata → en_revisión → publicada, verificador ≠ revisor forzado por constraint.
- **A6:** 10 fichas reales sobre votaciones o presupuesto, aplicando plantilla C5 y criterio D3. Redactadas en ambas variantes (C6) donde corresponda.
- **A5:** MFA obligatorio (WebAuthn editor/admin, TOTP resto); panel en subdominio separado o allowlist.

**Aceptación:** 10 fichas publicadas, cada una con ≥1 evidencia y doble revisión; ninguna cuenta sin MFA.

#### ✅ CHECKPOINT 2 — Gate editorial + acceso

---

### FASE 3 — Sitio público estático y capa de red
**Agentes:** A4 (líder), A5, A1 · **Gate duro: D5 (revisión legal) debe estar cerrado antes de que este sitio sea visible por terceros.**

- **A4:** build estático en dos variantes (C6). Webhook Supabase → build Netlify incremental.
- **A5:** Cloudflare delante (WAF, rate limiting en aportes/login, origen oculto); HSTS + CSP estricta; runbook de modo bajo ataque.
- **A1:** export a Git de fichas publicadas, commits firmados, hash público por ficha.

**Aceptación:** ambas variantes sirven las 10 fichas desde CDN; visita anónima no genera consulta SQL (verificado en logs); prueba de carga sin degradar ni tocar la base; CSP sin errores críticos en escáner externo; **D5 cerrado**.

#### ✅ CHECKPOINT 3 — Gate de producción pública (primer estado mostrable)

---

### FASE 4 — Descubribilidad
**Agentes:** A4 (líder), A6 · **Paralelo con:** Fases 1–3

- **A4:** URLs estables (nunca cambian; 301 si hay que hacerlo). `NewsArticle`+`Organization`+`Person`+`ClaimReview` en JSON-LD, distinto `Organization` por variante. Sitemap, `robots.txt`, OG image por ficha, feed RSS, JSON público (C4), Pagefind, kit de vocería.
- **A6:** títulos en lenguaje hablado. Páginas de metodología, correcciones, financiamiento, equipo — enlazadas desde el home de cada variante.

**Aceptación:** buscar la afirmación en lenguaje natural encuentra la ficha; Core Web Vitals en verde; las cuatro páginas de confianza existen en ambas variantes.

#### ✅ CHECKPOINT 4 — Gate de descubribilidad

---

### FASE 5 — Captura automatizada (Hermes sobre actas)
**Agentes:** A3 (líder), A2, A6

- **A2:** harvester del Diario de Sesiones (texto verbatim oficial).
- **A3:** skill `detectar_afirmacion` — marca cifra/comparación/atribución/hecho pasado; descarta opinión/promesa/valoración. Salida = candidatas (C3).
- **A6:** ajusta criterio de detección, revisa falsos positivos.

**Aceptación:** Hermes entrega candidatas bien formadas, nunca publicadas directamente; tasa de falsos positivos bajo umbral aceptable para A6.

#### ✅ CHECKPOINT 5 — Gate de captura asistida

---

### FASE 6 — Buzón de aportes
**Agentes:** A1, A4, A5

- Formulario → tabla `aporte` en Supabase. Hash con sal de IP, nunca en claro.
- Turnstile + rate limiting + moderación previa antes de entrar a la cola de captura.

#### ✅ CHECKPOINT 6 — Gate de aportes

---

### FASE 7 — Audio, video, transcripción y diarización
**Agentes:** A2, A3, A6 · La más costosa y frágil; al final a propósito.

- **A2:** `yt-dlp` + archivado + hash + snapshot; **siempre** ±60 s de contexto.
- **A3:** `faster-whisper` large-v3 + diccionario propio (nombres, ministerios, UF, UTM); diarización con `pyannote` + huellas de voz de actores seguidos.
- **A6:** revisa atribución de hablante antes de aprobar.

**Aceptación:** afirmación de video atribuida al hablante correcto, con timestamp, contexto y archivo verificable; ninguna ficha de video se publica sin verificación humana de la atribución.

#### ✅ CHECKPOINT 7 — Gate de audiovisual

---

### FASE 8 — Escalamiento (por disparador, no por calendario)
Ver §11. Meilisearch, perfil por político, espejo jurisdiccional, Supabase Pro, revisión trimestral de accesos.

#### ✅ CHECKPOINT 8 — Gate de madurez

---

## 8. Seguridad y costo — checklist transversal (todos los gates)

- [ ] Ningún secreto en el repo. `service_role` sólo en build/panel.
- [ ] RLS probada: `anon` no accede a nada fuera de lo publicado.
- [ ] Inmutabilidad activa sobre `captura` y `fuente_cruda`.
- [ ] Auditoría append-only, sin `DELETE` ni para la app.
- [ ] **Uso de Supabase bajo 80 % de cuota** (500 MB base, 5 GB egreso, 50k MAU). Alerta nativa de Supabase activa para las tres (confirmar en el dashboard, especialmente para egreso). Job propio semanal cubre **sólo** tamaño de base (SQL directo) y, si hay secrets de Management API, disco físico — **no cubre egreso**, eso depende exclusivamente de la alerta nativa por correo.
- [ ] **Backup `pg_dump` → R2 probado este trimestre** (Free no incluye backup gestionado).
- [ ] **Keep-alive activo** (evita pausa a los 7 días de inactividad).
- [ ] MFA en todas las cuentas internas. Cero cuentas compartidas.
- [ ] IP de origen no expuesta. Cloudflare delante.
- [ ] CSP estricta + HSTS. Sin XSS explotable.
- [ ] Dependabot verde.
- [ ] Contenido publicado versionado en Git con hash público.
- [ ] Ningún gasto recurrente activado sin disparador de §11 cruzado y registrado.

**Modelo de amenazas priorizado:** 1) manipulación de contenido, 2) toma de cuentas, 3) pérdida del archivo de evidencia, 4) seguridad de colaboradores, 5) presión legal, 6) DDoS.

---

## 9. Definition of Done — uniforme

1. Cumple el criterio de aceptación de su fase.
2. Test automatizado donde aplique.
3. Pasa la checklist de §8 en lo que corresponda.
4. Dejó rastro: corrida / hash / origen registrados.
5. Documentada aquí o en el repo.
6. Marcada en la bitácora (§12) por el Integrador.

---

## 10. Proceso de cambio

1. Quien propone abre entrada en §12: qué cambia, por qué, qué contratos o gates afecta.
2. Si toca un contrato congelado (§4), se notifica a todos los agentes afectados.
3. El Integrador aprueba o rechaza. Si aprueba, sube versión y fecha.
4. Nunca se edita el pasado en silencio — los cambios se registran, igual que las correcciones de las fichas.

---

## 11. Riesgos vivos y disparadores de escalamiento

### Riesgos

| Riesgo | Prob. | Impacto | Mitigación | Dueño |
|---|---|---|---|---|
| Sesgo de selección mata la credibilidad | Alta | Crítico | Reglas S1–S5 de `contrato-editorial.md`; verificar también al propio sector | A6 |
| Hermes publica un dato errado | Media | Crítico | Sólo candidatas (C3); verificación humana obligatoria | A3 |
| Acusación de falsificación | Media | Crítico | Inmutabilidad + Git + hash público + historial de correcciones + contexto ±60 s | A5/A6 |
| "Independencia" de presentación se confunde con independencia real ante IFCN | Media | Alto | No prometer elegibilidad formal hasta que la gobernanza sea real (§0, D1) | A6 |
| Supabase pausa el proyecto por inactividad | Baja | Medio | Keep-alive automático (§8) | A5 |
| Uso se acerca a cuota gratuita sin darse cuenta | Media | Medio | Alerta nativa + job propio al 80 % | A5 |
| Fuente oficial cambia estructura y rompe el parser | Alta | Medio | Parser falla ruidosamente; Hermes detecta el cambio y avisa | A2/A3 |
| Doxxing de colaboradores | Media | Alto | Seudónimos por defecto; firma institucional; mínima PII | A5/A6 |
| Bloqueo de IP por un servicio del Estado | Baja | Alto | User-Agent real, robots.txt, delays, caché; nada de bypass anti-bot | A2 |

### Disparadores de escalamiento (numéricos, no por antojo)

| Disparador | Qué se activa | Costo aproximado |
|---|---|---|
| Base de datos sobre 400 MB (80 % de 500) | Migrar a Supabase Pro | ~USD 25/mes |
| Egreso sobre 4 GB/mes (80 % de 5) | Revisar qué toca la base directamente, o subir a Pro | ~USD 25/mes o $0 si es un bug de arquitectura |
| Más de 5.000 fichas | Meilisearch en VPS | ~USD 5–10/mes |
| Storage de evidencia cerca del límite combinado | R2 pago | ~USD 0,015/GB/mes |
| Necesidad real de archivar video propio | Almacenamiento en frío | Variable |
| Aparece mecenas o financiamiento | Espejo jurisdiccional, auditoría externa, abogado permanente, backups gestionados | — |
| Se busca elegibilidad IFCN real para el sitio independiente | Separación de gobernanza formal | — |

**Regla de gasto:** ningún costo recurrente se activa sin disparador cruzado y registrado en bitácora.

---

## 12. Bitácora y estado

| Fecha | Agente | Fase / CP | Avance | Bloqueo | Decisión registrada |
|---|---|---|---|---|---|
| — | Integrador | CP-0 | D1–D6 y ADRs cerrados; D5 en gestión externa | Ninguno técnico | v2.0 consolida v1.0 + Fase 0 + enmienda costo cero + D1/D4/D5 |

### Tablero de checkpoints

| CP | Nombre | Estado |
|---|---|---|
| 0 | Fundaciones | ✅ Cerrado |
| 1 | Datos | ⬜ |
| 2 | Editorial + acceso | ⬜ |
| 3 | Producción pública | ⬜ *(gate: D5 cerrado)* |
| 4 | Descubribilidad | ⬜ |
| 5 | Captura asistida | ⬜ |
| 6 | Aportes | ⬜ |
| 7 | Audiovisual | ⬜ |
| 8 | Madurez | ⬜ |

---

*Fin del plan maestro consolidado v2.0. Próxima revisión obligatoria: al cierre de CP-1.*
