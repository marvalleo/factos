# FACTOS — D1 y D4 resueltos, brief para revisión legal (D5)

> Registrada según §10 del plan maestro. Afecta el contrato C5 (plantilla de ficha)
> y agrega un contrato nuevo, C6 (variante de sitio).
>
> **Versión:** 1.0 · **Estado:** D1 y D4 resueltos · D5 pendiente de gestión externa

---

## D1 — Resuelto: doble salida desde una sola fuente de verdad

No hay que elegir entre independiente y partido. La arquitectura de tres capas que ya tenías (`arquitectura.md`, contrato C5) hace esto posible sin duplicar trabajo: **una sola base de verificaciones, dos sitios construidos desde ella.**

### Cómo funciona

- **Capa 1 (hecho)** y **Capa 2 (evidencia)** son idénticas en ambos sitios. Es el mismo dato, la misma fuente archivada, el mismo hash. Nunca varían.
- **Capa 3 (análisis)** es donde difieren:
  - **Sitio A — independiente.** No muestra Capa 3, o muestra un análisis neutro sin lenguaje de campaña. `Organization` en el JSON-LD es la entidad editorial, no el partido.
  - **Sitio B — partido.** Muestra Capa 3 completa, con la lectura libertaria explícita. `Organization` es el partido.
- El build genera **dos salidas estáticas** desde el mismo contenido, con configuración de variante (dominio, `Organization`, si se renderiza Capa 3, colores/marca). Eso es el contrato nuevo:

**C6 · Variante de sitio** — contrato entre A4 (Frontend) y A6 (Editorial). Cada verificación se construye dos veces con un parámetro `variante: independiente | partido`. La plantilla decide qué capas renderiza; el contenido de Capa 1 y 2 es un solo origen, nunca se bifurca.

### El punto que no es negociable

Esto resuelve la *presentación*. No resuelve la elegibilidad real ante Google/IFCN, que evalúa **control editorial efectivo**, no sólo el nombre o el dominio. Si quieres que el Sitio A sea elegible para esos programas algún día, la independencia tiene que ser real: gobernanza propia, quién puede vetar una ficha, de dónde sale el financiamiento. Maquetar dos salidas es gratis y se hace ahora; la independencia editorial genuina es una decisión organizacional que se toma aparte y más adelante, si llega el caso. Por ahora, ambos sitios son legítimamente tuyos y eso está bien — sólo no prometas ante terceros una independencia que todavía es sólo de presentación.

### Impacto técnico

- A4 añade la configuración de variante al build (dos targets, no dos repos).
- A6 redacta el análisis dos veces por ficha cuando corresponda, o marca "sin análisis" para el sitio A.
- El JSON público (C4) expone ambas variantes o un flag `analisis_partido` opcional — a decidir con A1 al implementar.

---

## D4 — Resuelto: Netlify, sin dominio comprado, durante el período de prueba

Uso el subdominio gratuito de Netlify (`algo.netlify.app`) hasta validar el producto. Es consistente con lo que ya recomendaba `arquitectura.md` (Astro SSG en Netlify + Cloudflare) — no hay conflicto con ADR-02, sólo se pospone la compra del dominio.

Que ya tengas la página regional del partido corriendo en Netlify con dominio comprado y sin problemas es una buena señal: es la misma plataforma, así que no hay riesgo nuevo que descubrir en producción cuando llegue el momento de migrar.

**Una sola condición de la enmienda de costo cero se mantiene:** no anuncies ni distribuyas masivamente el sitio de verificación en el subdominio `.netlify.app`. Sirve perfecto para pruebas internas, mostrar avances y validar con el equipo. Cuando decidas que está listo para que lo use un representante en público, compra el dominio antes de ese momento, no después — un sitio de verificación en un subdominio ajeno pierde credibilidad antes de que lo lean, y cambiar de dominio después implica redirecciones 301 permanentes que conviene evitar desde el día uno si se puede.

WHOIS privado se activa recién cuando compres el dominio real; no aplica al subdominio de prueba.

---

## D5 — Brief para gestionar la revisión legal

Esto es lo que llevas al abogado o a la clínica jurídica. No es la revisión en sí — es lo que necesitas tener listo para que la consulta sea eficiente y barata.

### Alcance de la consulta (para acotar el costo)

Pide una **revisión de criterio**, no una revisión ficha por ficha. Es decir: que el abogado valide la metodología y los procesos antes de que generen contenido, no que revise cada verificación publicada. Eso es lo que hace la consulta barata y escalable.

### Preguntas concretas a llevar

**1. Difamación e injurias**
- ¿La escala de veredictos (`contrato-editorial.md`, D2) y la regla de "cita textual, cero adjetivos sobre personas" son suficientes como estándar de diligencia debida en Chile?
- ¿El veredicto `falso` o `insostenible` sobre una autoridad, cuando está bien documentado, tiene alguna protección reforzada por tratarse de un funcionario público y un acto de su función?

**2. Derecho de cita y uso de material audiovisual**
- Uso de fragmentos de video/audio (entrevistas, sesiones, prensa) con fines de crítica y verificación, bajo la Ley 17.336. ¿Cuánto material y con qué encuadre es defendible como cita legítima?
- Uso de transcripciones automáticas de contenido de terceros.

**3. Protección de datos personales (Ley 19.628 y su actualización)**
- Tratamiento de datos de los actores verificados (RUT, declaraciones patrimoniales públicas).
- Hash con sal de IP de aportantes y de colaboradores seudónimos: ¿es suficiente o se requiere algo adicional?
- Retención y eliminación de datos del buzón de aportes.

**4. La estructura de doble salida (D1)**
- Implicancias de que la misma verificación se publique con y sin el análisis partidario. ¿Cambia la responsabilidad editorial entre un sitio y otro?
- Si en algún momento se busca elegibilidad IFCN/ClaimReview para el sitio independiente, qué separación de gobernanza es la mínima defendible.

**5. Derecho a réplica**
- Validar el mecanismo descrito en `contrato-editorial.md` (vía, plazo, publicación de la réplica) contra cualquier estándar o buena práctica local.

**6. Términos de uso y responsabilidad**
- Términos de uso del sitio, exención de responsabilidad razonable sin debilitar la credibilidad del contenido.
- Financiamiento: qué se está legalmente obligado a declarar, dado que el sitio tiene relación con el partido.

### Documentos a llevar

- `contrato-editorial.md` completo (D2 y D3).
- 2–3 fichas de ejemplo ya redactadas, con su evidencia, para que el abogado vea el formato real, no sólo la teoría.
- Este documento (D1/D4/D5).

### Cómo abaratarlo

- Clínica jurídica de una facultad de Derecho: suelen tomar casos de interés público sin costo, y "metodología de verificación de hechos" encaja bien en ese perfil.
- Si no hay clínica disponible, una consulta acotada de 2–3 horas con un abogado de confianza del partido, enfocada sólo en las seis preguntas de arriba, es preferible a un contrato abierto.
- No se requiere resolver esto antes de CP-1 o CP-2 (datos y primeras fichas internas). **Sí debe estar resuelto antes de CP-3** (sitio público, aunque sea en subdominio de prueba visible por terceros) y obligatoriamente antes de comprar el dominio y anunciar el sitio.

### Urgencia relativa

No bloquea el trabajo técnico inmediato. A1 y A2 pueden avanzar con CP-1 mientras gestionas esto en paralelo. Sí es gate duro para CP-3.
