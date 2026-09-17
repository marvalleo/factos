# FACTOS — Fase 0: casos de uso, requisitos y decisiones de tecnología

> Insumo obligatorio del `plan-maestro.md`. Cierra el vacío detectado: la Fase 0
> original saltaba directo a congelar contratos sin haber definido qué se enchufa
> en ellos.
>
> **Orden secuencial de Fase 0:**
> `0.1 Casos de uso → 0.2 Requisitos no funcionales → 0.3 ADRs de tecnología → 0.4 Congelar contratos (D6)`
>
> **Versión:** 1.0 · **Estado:** borrador para ratificar

---

## 0.1 — Casos de uso

### Actores

| Actor | Tipo | Notas |
|---|---|---|
| Ciudadano anónimo | Externo | Nunca autenticado. Nunca toca la base |
| Representante / vocero | Externo | Usa fichas en vivo. Necesita velocidad y cita lista |
| Medio / desarrollador tercero | Externo | Consume JSON/RSS. No debe depender de nosotros |
| Actor verificado | Externo | El político sujeto de una ficha. Ejerce réplica |
| Aportante | Externo | Sube material. Puede ser anónimo |
| Verificador | Interno | Redacta fichas contra evidencia |
| Revisor | Interno | Segundo par de ojos. Nunca el mismo que verificó |
| Editor | Interno | Publica, corrige, retira |
| Admin | Interno | Accesos, claves, auditoría |
| A2 Cosecha | Automático | Determinista, sin LLM |
| A3 Captura (Hermes) | Automático | Sólo produce candidatas |

### Casos de uso

**Públicos (definen el frontend y el rendimiento)**

| ID | Caso | Actor | Criterio de aceptación |
|---|---|---|---|
| CU-01 | Busca una afirmación que acaba de escuchar, en lenguaje hablado | Ciudadano | Encuentra la ficha en ≤3 interacciones y ≤30 s totales |
| CU-02 | Consulta el perfil de un político con todas sus verificaciones | Ciudadano | Contador por veredicto visible; orden cronológico y por veredicto |
| CU-03 | Comparte una ficha en WhatsApp | Ciudadano | OG image muestra afirmación + veredicto sin abrir el link |
| CU-04 | Cita el hecho y la fuente en vivo, en TV o radio | Representante | Kit de vocería copiar-pegar, carga <1 s, incluye enlace permanente |
| CU-05 | Duda de la ficha y quiere probar que no fue alterada | Escéptico | Accede al hash de la ficha, a la fuente cruda archivada y al historial de correcciones |
| CU-06 | Construye su propia visualización con nuestros datos | Desarrollador | `/api/v1/fichas.json` estable y documentado; no requiere clave |
| CU-07 | Envía un video o enlace como aporte | Aportante | Formulario con Turnstile; sin registro; IP nunca en claro |
| CU-08 | Solicita derecho a réplica sobre una ficha | Actor verificado | Vía y plazo publicados; la réplica queda enlazada desde la ficha |

**Internos (definen el panel y el flujo editorial)**

| ID | Caso | Actor | Criterio de aceptación |
|---|---|---|---|
| CU-09 | Revisa la cola de candidatas y descarta ruido | Verificador | Ve texto literal, actor, timestamp y contexto ±60 s sin salir del panel |
| CU-10 | Redacta una ficha adjuntando evidencia | Verificador | No puede guardar evidencia sin `fuente_cruda` con hash |
| CU-11 | Aprueba y publica | Revisor | La BD rechaza publicar si revisor = verificador, o si falta evidencia |
| CU-12 | Corrige una ficha ya publicada | Editor | Queda registro público con tipo, campo, valor anterior y fecha |
| CU-13 | Retira una ficha | Editor | La URL sobrevive y explica el retiro. Nunca 404 |
| CU-14 | Consulta quién cambió qué y cuándo | Admin | Auditoría append-only, no borrable ni por la app |
| CU-15 | Gestiona altas, bajas y rotación de accesos | Admin | Revisión trimestral registrada |

**Automáticos (definen cosecha y captura)**

| ID | Caso | Actor | Criterio de aceptación |
|---|---|---|---|
| CU-16 | Cosecha una fuente oficial y la archiva | A2 | Original intacto + SHA-256 + URL + timestamp + snapshot. Reanudable |
| CU-17 | Parsea la fuente a tablas con localizador exacto | A2 | Si no puede, **falla ruidosamente**. Nunca adivina un valor |
| CU-18 | Detecta afirmaciones verificables en un transcrito | A3 | Salida siempre en estado `candidata`. Nunca publica |
| CU-19 | Detecta que una fuente cambió de estructura | A2/A3 | Alerta antes de que el parser produzca datos silenciosamente malos |
| CU-20 | Transcribe y atribuye hablante en audio/video | A3 | Atribución revisada por humano antes de aprobar. Siempre guarda ±60 s |

**Operación y crisis**

| ID | Caso | Actor | Criterio de aceptación |
|---|---|---|---|
| CU-21 | Restaura el archivo de evidencia desde backup | Admin | Probado cada trimestre, con tiempo medido |
| CU-22 | Activa modo bajo ataque | Admin/A5 | Runbook dice quién, cuándo y cómo se revierte |
| CU-23 | Responde a una acusación pública de falsificación | Editor | Puede demostrar integridad en minutos con Git + hash + auditoría |

**Fuera de alcance (explícito, para evitar deriva):** verificación en tiempo real durante una transmisión; app móvil nativa; comentarios de usuarios; cuentas para el público; traducción a otros idiomas.

---

## 0.2 — Requisitos no funcionales

Consolidados desde `arquitectura.md` y convertidos en criterios medibles. Lo que no se puede medir, no se puede aprobar en un gate.

| # | Requisito | Meta | Cómo se verifica |
|---|---|---|---|
| RNF-01 | Visita anónima no genera consulta SQL | 0 queries | Logs de Supabase durante prueba de carga |
| RNF-02 | Carga de ficha (LCP, 4G móvil) | ≤1,5 s | Lighthouse / CrUX |
| RNF-03 | TTFB desde CDN | ≤200 ms | Prueba multi-región |
| RNF-04 | Pico de tráfico soportado sin degradar | 200.000 visitas / 20 min | Prueba de carga sintética |
| RNF-05 | Disponibilidad del sitio público | ≥99,9 % mensual | Monitor externo |
| RNF-06 | Publicar ficha → visible en producción | ≤5 min | Cronometrar el webhook + build |
| RNF-07 | Build completo del sitio | ≤10 min con 5.000 fichas | Medición en CI |
| RNF-08 | RPO (pérdida máxima de datos) | ≤24 h | Diseño de backup |
| RNF-09 | RTO (recuperación del archivo) | ≤4 h | Simulacro trimestral |
| RNF-10 | Cobertura de tests en reglas críticas | 100 % de constraints y RLS | Suite automatizada en CI |
| RNF-11 | Costo mensual de infraestructura en régimen | Definir techo objetivo | Revisión mensual |
| RNF-12 | Ninguna dependencia con vulnerabilidad crítica | 0 abiertas | Dependabot en CI |
| RNF-13 | Rate limit en endpoints dinámicos | Definir umbral por IP/min | WAF de Cloudflare |
| RNF-14 | Todo dato publicado es trazable a fuente archivada | 100 % | Constraint en BD + auditoría |

RNF-11 y RNF-13 requieren que fijes los números. El resto son propuestas mías.

---

## 0.3 — ADRs pendientes de ratificar

Formato: decisión, alternativas, recomendación. Un ADR se ratifica o se cambia, pero no se deja implícito. Los marcados **⚠️** son los caros de revertir.

| ID | Decisión | Alternativas | Recomendación |
|---|---|---|---|
| **ADR-01** ⚠️ | Generador del sitio | Astro SSG · Next.js · Hugo · Eleventy | **Astro SSG.** Cero JS por defecto, ideal para RNF-02/03 |
| **ADR-02** | Hosting del sitio estático | Netlify · Cloudflare Pages · Vercel | **A decidir.** Si Cloudflare va delante igual, Pages simplifica la cadena y elimina un proveedor. Netlify si pesa más que ya lo conoces |
| **ADR-03** ⚠️ | Base de datos y auth | Supabase · Postgres autogestionado · Neon + Auth propio | **Supabase.** RLS + Auth + Storage integrados; ya lo usas |
| **ADR-04** ⚠️ | Panel interno de redacción | App propia (Astro/React) · Supabase Studio · Directus · Retool | **App propia mínima.** El flujo candidata→revisión→publicación y la regla verificador≠revisor son demasiado específicos para un CMS genérico. Studio no sirve para no-técnicos |
| **ADR-05** | Almacenamiento de evidencia | Cloudflare R2 · Backblaze B2 · S3 | **R2** si eliges Cloudflare para todo. Requisito no negociable: object-lock |
| **ADR-06** | Búsqueda | Pagefind → Meilisearch · Typesense · Algolia | **Pagefind** hasta ~5.000 fichas, migración documentada a Meilisearch |
| **ADR-07** | Lenguaje de harvesters | Python · TypeScript | **Python.** Ecosistema de parsing, PDF y datos |
| **ADR-08** ⚠️ | Orquestación de cosecha | GitHub Actions · cron en VPS · Supabase cron · Temporal | **A decidir.** Actions es gratis y auditable pero con límites de tiempo; VPS da control pero es superficie que hay que endurecer |
| **ADR-09** | Estructura de repositorios | Monorepo · repos separados (sitio / harvesters / contenido) | **Contenido en repo aparte** (es el registro inmutable, con commits firmados). Código en monorepo |
| **ADR-10** | CI/CD y pruebas | GitHub Actions + pgTAP/Vitest/pytest | **GitHub Actions.** Tests obligatorios de RLS y constraints |
| **ADR-11** | Transcripción | faster-whisper local · API de transcripción | **Local.** Costo, privacidad de material sensible y control del diccionario |
| **ADR-12** | Modelos LLM por tarea | — | Opus 5 para arquitectura; Sonnet 5 para código; Haiku 4.5 para clasificación masiva. Hermes corre su modelo local |
| **ADR-13** | Gestor de secretos | Variables de entorno del proveedor · 1Password/Bitwarden · Infisical | **A decidir.** Mínimo: nada en el repo, rotación calendarizada |
| **ADR-14** | Observabilidad y alertas | Logs del proveedor · Sentry · Uptime externo | Mínimo: monitor de uptime externo + alerta de fallo de cosecha |
| **ADR-15** ⚠️ | Licencia del contenido y del código | CC BY para contenido · MIT/AGPL para código | **CC BY para contenido.** Que otros repliquen tus fichas citando es difusión, no pérdida |

---

## 0.4 — Qué falta para congelar los contratos (D6)

Se puede congelar C1–C5 cuando estén cerrados:

- [ ] D1 · Independiente vs. partido *(bloquea comunicación y elegibilidad)*
- [ ] D2 · Escala de veredictos con ejemplos
- [ ] D3 · Criterio público de qué se verifica
- [ ] D4 · Dominio y WHOIS
- [ ] D5 · Revisión legal
- [ ] ADR-01 a ADR-15 ratificados
- [ ] RNF-11 y RNF-13 con números fijados
- [ ] Casos de uso 0.1 revisados contra `esquema.sql` (¿falta algún campo?)

### ✅ CHECKPOINT 0 — Gate de fundaciones (actualizado)
Se cruza con las ocho casillas de arriba marcadas. A partir de ahí, A1–A6 trabajan en paralelo.
