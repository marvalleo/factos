# FACTOS — Enmienda 1: operación a costo cero (v1.2, corregida)

> Modifica ADR-02, 03, 04, 05, 08, 13, 14 y RNF-11 del documento `fase-0.md`.
> Registrada según §10 del plan maestro.
>
> **Restricción nueva (R0):** el proyecto no genera costos de infraestructura hasta
> ser validado por resultados. Toda función que exija pago se corta **sólo si existe
> alternativa gratuita documentada**, o se difiere con disparador explícito.
>
> **Corrección respecto a v1.1:** la versión anterior sacaba Supabase por completo.
> Es innecesario. Supabase Free no cobra al superar cuota: restringe el servicio
> hasta el siguiente ciclo de facturación, pero no genera cargo. Con spend cap
> activo (por defecto en el plan gratuito) el costo es estructuralmente cero.
> Supabase **se mantiene** como plataforma, con monitoreo activo de uso.
>
> **Versión:** 1.2 · **Estado:** borrador para ratificar

---

## 1. Supabase se mantiene — con jaula, no con reemplazo

`esquema.sql` vuelve a ser la plataforma operativa, no sólo el contrato C1. RLS, panel y flujo candidata→revisión→publicación funcionan como se diseñaron originalmente en `plan-maestro.md`.

Los límites reales del plan gratuito, a la fecha:

| Recurso | Límite Free | Qué significa para nosotros |
|---|---|---|
| Base de datos | 500 MB | Miles de fichas (texto). El riesgo es meter blobs grandes ahí — no lo hagas |
| Storage (archivos) | ~1 GB | No cuenta contra la base. Ahí van PDFs y XML livianos; nada de video |
| Egreso (bandwidth) | 5 GB/mes | El más fácil de agotar si el sitio público consultara la base directamente — por eso el sitio sigue siendo estático y no la toca |
| Usuarios activos mensuales | 50.000 | Sólo cuenta el panel interno. Nadie del público se autentica |
| Proyectos activos | 2 | Alcanza: producción + staging |
| Pausa automática | a los 7 días sin actividad | Se neutraliza gratis: el mismo cron de GitHub Actions que corre los harvesters hace ping al proyecto |
| Backups automáticos | **no incluidos en Free** | Hay que armar el propio — ver §2 |

Verifica estos números en `supabase.com/pricing` antes de comprometerte: cambian.

## 2. Lo que hay que construir para que "gratis" no sea "frágil"

Free no incluye respaldos automáticos. Eso no es aceptable para el archivo de evidencia, así que se cubre con una tarea propia, también gratuita:

- **Backup**: GitHub Actions programado, `pg_dump` de la base + copia del bucket de Storage → Cloudflare R2 (capa gratuita). Diario o semanal según cuánto cambie el contenido.
- **Keep-alive**: el mismo runner que cosecha `opendata.camara.cl` hace una consulta trivial a Supabase antes de salir. Evita la pausa por inactividad sin gastar un job aparte.
- **Alerta de uso** (el punto que pediste, ver §3): no reemplaza al backup, lo complementa.

Con esto, "gratis" deja de depender de que nunca pase nada raro.

## 3. Alerta de uso y consumo

Dos capas, porque Supabase resuelve una parte y GitHub Actions la otra:

**Nativa de Supabase.** El dashboard permite monitorear usuarios activos, egreso, almacenamiento y llamadas a funciones, con alertas al acercarse a los límites, y al superar la cuota en el plan Free llega una notificación al correo de facturación y el proyecto entra en un período de gracia. Actívalas todas desde el primer día — están ahí y no cuestan nada activarlas.

**Propia, para no depender sólo del correo.** Un job semanal en GitHub Actions que consulta la Management API de Supabase, lee `database_size` y egreso del mes, y si supera el 80 % de 500 MB o de 5 GB, escribe un issue en el repo y notifica al canal del equipo. Es el mismo patrón que ya usas para detectar cuando una fuente oficial cambió de estructura: falla ruidosamente, no en silencio.

**Importante sobre el spend cap:** el spend cap determina si la organización puede exceder la cuota del plan; sin él activado, al superar la cuota el servicio se restringe pero no se cobra. Es exclusivo del plan Pro — en Free el comportamiento equivalente es automático. Verifica igual que está activo si en algún momento pasas a Pro por otra razón: un ataque al sistema o un bug de software son justamente los escenarios de uso alto que el spend cap está diseñado para frenar.

## 4. Lo que sigue igual del esquema original

Con Supabase de vuelta, recupera todo lo de `plan-maestro.md` y `esquema.sql` sin cambios: RLS probada contra `anon`, inmutabilidad por trigger en `captura` y `fuente_cruda`, auditoría append-only, la constraint que impide publicar sin evidencia, panel con Supabase Auth y MFA. Nada de eso se había estropeado; sólo estaba de más sacarlo.

La exportación a Git de las fichas publicadas (commits firmados, hash público) **se mantiene igual**: sigue siendo tu defensa ante una acusación de manipulación, y es independiente de si la base es Supabase o no.

---

## 5. Stack revisado

| Componente | Decisión $0 | Límite del plan gratuito | Qué pasa si se supera |
|---|---|---|---|
| **Sitio + CDN + WAF** | Cloudflare Pages + Cloudflare free | Ancho de banda sin tope; builds mensuales acotados | Nada. Es el punto más sólido del stack |
| **Base de datos + Auth + Storage** | Supabase Free | 500 MB base, ~1 GB storage, 5 GB egreso/mes, 50k MAU, 2 proyectos | Alerta al 80 %; migrar a Pro (~USD 25/mes) sólo si el disparador se cruza |
| **Panel de redacción** | App mínima sobre Supabase Auth (como en el plan original) | Cuenta como parte de los 500 MB/50k MAU | Se sostiene igual al escalar; sólo cambia el plan de pago |
| **Orquestación de cosecha, backup y keep-alive** | GitHub Actions con cron | Minutos ilimitados en repos **públicos**; cuota mensual en privados | Mover jobs al repo público |
| **Respaldo de la base** | `pg_dump` vía GitHub Actions → Cloudflare R2 | Free no incluye backup automático; este lo reemplaza | — |
| **Archivo de evidencia** | Supabase Storage + Cloudflare R2 + snapshot en archive.org | Storage ~1 GB, R2 con capa gratuita propia | Sólo documentos y datos livianos. Nada de video |
| **Snapshot de terceros** | archive.org / archive.today | Gratis | Además suma credibilidad: el testigo no eres tú |
| **Búsqueda pública** | Pagefind (índice estático) | ~5.000 fichas | Meilisearch autohospedado |
| **Buzón de aportes** | Formulario → tabla `aporte` en Supabase, con Turnstile | Dentro de la cuota general | — |
| **Secretos** | GitHub Secrets + variables de entorno de Supabase/Cloudflare | Gratis | — |
| **Monitoreo** | Alertas nativas de Supabase + UptimeRobot + alerta propia de uso (§3) | Gratis | — |
| **Transcripción** | `faster-whisper` local | Tu hardware | — |
| **Captura** | Hermes local | Tu hardware | — |
| **Repositorio de contenido publicado** | Export a Git, commits firmados, hash público | — | — |

**Verifica los límites vigentes antes de comprometerte.** Las capas gratuitas cambian y estos números son de mi conocimiento, no de la documentación de hoy.

### Regla de disciplina para no acercarte a los límites sin darte cuenta

- Nada de blobs grandes ni logs verbosos dentro de tablas Postgres — eso es lo que llena los 500 MB antes de tiempo. Texto de fichas y metadatos sí; PDFs y XML van a Storage.
- El sitio público sigue siendo estático y **no consulta la base en runtime**. Es la decisión que evita agotar el egreso de 5 GB en el primer pico de tráfico.
- El export a Git es adicional, no un reemplazo: sirve como copia legible fuera de Supabase y como prueba de integridad independiente del proveedor.

---

## 6. Lo que se corta, y con qué se reemplaza

Con Supabase de vuelta, la lista de cortes reales es más corta que en la v1.1. Ninguna función se elimina sin alternativa.

| Función cortada | Por qué costaba | Alternativa $0 | Qué pierdes de verdad |
|---|---|---|---|
| Almacenamiento de video | Egreso caro en cualquier proveedor, Supabase incluido | Embed original + snapshot de terceros + hash del archivo + **sólo audio** si hace falta transcribir | Si el video original desaparece y no lo respaldaste, pierdes la prueba. Mitigación: guardar audio, que pesa 20 veces menos |
| Meilisearch (búsqueda pública) | VPS | Pagefind | Facetas complejas y tolerancia a errores de tipeo |
| Sentry | Plan pago al crecer | Logs de Cloudflare/Supabase + alertas de CI | Menos detalle al depurar |
| Espejo en otra jurisdicción | Hosting extra | Diferido. El export a Git en un repo público ya es un espejo de facto | Redundancia formal ante una orden de bajada |
| Backups gestionados de Supabase | Sólo en plan Pro | `pg_dump` propio vía GitHub Actions → R2 (§2) | Menor comodidad; misma protección si el job se prueba trimestralmente |

---

## 7. Lo que se degrada, y el riesgo que asumes

Sé explícito con esto, porque es lo que un plan honesto tiene que decir:

- **Dependencia de un proveedor gratuito para el dato vivo.** Supabase Free puede pausar el proyecto por inactividad o restringir un servicio si se agota una cuota. Mitigación: keep-alive (§2), alertas (§3), y el export a Git como copia legible fuera de Supabase — si el proveedor falla, el contenido publicado sobrevive igual.
- **Sin backup gestionado.** Hay que operar el propio `pg_dump` con disciplina real, no como una tarea que "algún día" se automatiza. Un backup no probado no es un backup — pruébalo cada trimestre desde el día uno.
- **Archivo de evidencia acotado.** ~1 GB de Storage más R2 alcanzan para muchos miles de documentos, XML y PDF. No alcanzan para video. La regla es: documentos sí, audio si es necesario, video nunca.
- **Cuenta única como punto de falla.** Si pierdes acceso a la organización de Supabase o GitHub, pierdes todo a la vez. Mitigación gratuita: dos administradores con llave de seguridad en cada plataforma, y el `pg_dump` como copia fuera de Supabase.

---

## 8. El costo irreducible

No te voy a vender que todo es gratis. Hay dos cosas que no lo son:

**El dominio.** Un `.cl` cuesta del orden de USD 10–15 al año. Puedes arrancar en un subdominio `pages.dev` para las pruebas técnicas, pero no lances públicamente sin dominio propio: un proyecto de verificación en un subdominio ajeno pierde credibilidad antes de que lo lean, y además te ata a un proveedor en la URL, que es justo lo que las URLs estables no deben tener.

**La revisión legal (D5).** Es una gestión externa y probablemente el mayor desembolso inicial. Alternativas de menor costo: consulta acotada sobre el criterio y no sobre cada ficha, apoyo pro bono de una clínica jurídica universitaria, o de abogados afines al proyecto. No la elimines. Es el único gasto donde ahorrar te puede salir caro de verdad.

Todo lo demás puede esperar a que haya resultados.

---

## 9. Disparadores de escalamiento

No se escala por antojo ni por fecha. Se escala cuando se cruza un umbral medible, y cada disparador tiene su costo estimado.

| Disparador | Qué se activa | Costo aproximado |
|---|---|---|
| Base de datos sobre 400 MB (80 % de 500) | Migrar a Supabase Pro | ~USD 25/mes |
| Egreso sobre 4 GB/mes (80 % de 5) | Revisar qué consulta la base directamente, o subir a Pro | ~USD 25/mes o $0 si es un bug de arquitectura |
| Más de 5.000 fichas | Meilisearch en VPS | ~USD 5–10/mes |
| Storage de evidencia sobre el límite gratuito combinado | R2 pago | ~USD 0,015/GB/mes |
| Necesidad real de archivar video propio | Almacenamiento en frío | Variable. Evaluar caso a caso |
| Aparece mecenas o financiamiento | Espejo en otra jurisdicción, auditoría de seguridad externa, abogado permanente, backups gestionados | — |

**Regla de gasto:** ningún costo recurrente se activa sin que el disparador esté cruzado y registrado en la bitácora. Que el gasto sea consecuencia de un hecho, no de una expectativa.

---

## 10. Impacto en los checkpoints

El orden del plan maestro se mantiene, esencialmente tal como estaba antes de v1.1, con la capa de monitoreo añadida:

- **CP-1 (Datos)** — sin cambios respecto al plan original: el harvester escribe a Supabase, con `fuente_cruda` archivada y hash. Se suma la tarea de keep-alive.
- **CP-2 (Editorial + acceso)** — sin cambios: panel con Supabase Auth, MFA, verificador ≠ revisor forzado por constraint. Se suma configurar y probar el backup por `pg_dump`.
- **CP-3 (Producción pública)** — sin cambios: sitio estático, no toca la base en runtime.
- **CP-4 (Descubribilidad)** — sin cambios.
- **CP-6 (Aportes)** — vuelve a ser tabla `aporte` en Supabase, como en el diseño original.
- **Nuevo criterio transversal, todos los checkpoints desde CP-1:** las alertas de uso (§3) están activas y probadas antes de dar el gate por cerrado.

**RNF-11 se reemplaza:** techo de costo de infraestructura **USD 0/mes** mientras el uso esté bajo el 80 % de cualquier cuota de Supabase. Gasto autorizado antes de eso: el dominio. Al cruzar el 80 %, se evalúa Pro (~USD 25/mes) como disparador, no como decisión anticipada.

---

## 11. ADRs revisados

| ID | Antes de v1.1 | v1.1 (revertido) | v1.2 (esta enmienda) |
|---|---|---|---|
| ADR-02 | Netlify o Cloudflare Pages | Cloudflare Pages | **Cloudflare Pages.** Se mantiene: ancho de banda sin tope y un proveedor menos |
| ADR-03 | Supabase | Git como registro | **Supabase Free, con monitoreo de uso y spend cap.** Se revierte el cambio de v1.1 |
| ADR-04 | Panel propio | PR + CI | **Panel propio mínimo sobre Supabase Auth.** Se revierte el cambio de v1.1 |
| ADR-05 | R2 con object-lock | R2 free + archive.org | **Supabase Storage + R2 free + archive.org.** Object-lock queda diferido a cuando haya presupuesto |
| ADR-08 | A decidir | GitHub Actions | **GitHub Actions**, ahora también para backup y keep-alive |
| ADR-13 | A decidir | GitHub Secrets | **GitHub Secrets + variables de entorno de Supabase/Cloudflare** |
| ADR-14 | A decidir | Monitor de uptime | **Monitor de uptime + alertas nativas de Supabase + alerta propia de uso (§3)** |
