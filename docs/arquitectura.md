# Arquitectura — seguridad, escalabilidad y descubribilidad

Documento complementario a `esquema.sql`.

---

## 1. La decisión que resuelve tres problemas a la vez

**El sitio público es estático.**

Cada ficha se pre-renderiza a HTML en el build y se sirve desde CDN. Supabase queda detrás, sólo para el panel interno de redacción y para el build. El visitante anónimo nunca toca la base de datos.

Esto resuelve simultáneamente:

- **DDoS** — no hay backend que tumbar. Un archivo HTML en CDN absorbe tráfico que ningún servidor propio aguantaría, y un ataque volumétrico no te cuesta disponibilidad, sólo ancho de banda del CDN.
- **Escalabilidad** — el día que un diputado cite una ficha en TV nacional y entren 200.000 personas en veinte minutos, no pasa nada. Sin autoescalado, sin optimizar consultas, sin sorpresas en la factura de Postgres.
- **Velocidad** — que es factor de posicionamiento.

Cualquier arquitectura donde una visita anónima genere una consulta SQL es una arquitectura que se cae el día que importa. Rebuild incremental cuando se publica una ficha (webhook de Supabase → build de Netlify).

---

## 2. Modelo de amenazas, ordenado por daño real

El DDoS es el que más asusta y el menos peligroso. El orden real es este.

### 2.1 Manipulación de contenido (la amenaza número uno)

El ataque que te destruye no es tumbar el sitio: es alterar una ficha, capturar pantalla, y difundir que inventas datos. Un sitio caído vuelve en una hora. Una acusación de falsificación no se limpia nunca.

Defensas:

- **Contenido versionado en Git.** Las fichas publicadas se exportan a Markdown/JSON en un repositorio con historial inmutable. La base de datos es la herramienta de trabajo; el repo es el registro. Si alguien altera un registro en Postgres, el diff de Git lo delata.
- **Commits firmados** (GPG/sigstore) por quien publica.
- **Hash público de cada ficha.** Publicar el SHA-256 del contenido y de cada fuente cruda. Permite a un tercero probar que la ficha no cambió.
- **Historial de correcciones visible** — ya está en el esquema. Convierte la edición legítima en un acto transparente y la ilegítima en un acto detectable.
- **Inmutabilidad en la BD** — triggers sobre `captura` y `fuente_cruda`.
- **Auditoría append-only** — con permisos que impidan `DELETE` incluso al rol de aplicación.

### 2.2 Toma de cuentas de colaboradores

Vector: phishing dirigido. Es cómo caen la mayoría de los proyectos de este tipo.

- MFA obligatorio, sin excepciones, con llaves de seguridad (WebAuthn) para roles `editor` y `admin`. TOTP como mínimo para el resto.
- Cero cuentas compartidas.
- Principio de mínimo privilegio: los roles del esquema no son decorativos.
- La `service_role key` de Supabase **jamás** en el frontend, jamás en el repo, jamás en un `.env` commiteado. Sólo en variables de entorno del build y del panel interno.
- Rotación de claves calendarizada y al salir cualquier persona del equipo.
- Revisión trimestral de quién tiene acceso a qué.

### 2.3 Pérdida o compromiso del archivo de evidencia

Sin el archivo, el proyecto vale cero: cada ficha se vuelve una afirmación sin respaldo.

- Regla 3-2-1: tres copias, dos medios, una fuera de sitio.
- Almacenamiento en Cloudflare R2 o Backblaze B2 (egreso barato o gratis) con versionado y **object lock / retención inmutable** activada. Eso impide que un atacante con credenciales borre el histórico.
- Restauración probada cada trimestre. Un backup no probado no es un backup.
- Espejo estático en otra jurisdicción y, opcionalmente, en IPFS, por si aparecen intentos de bajada.

### 2.4 Seguridad de los colaboradores

En un proyecto que verifica políticos, el doxxing y el hostigamiento son riesgo operativo real.

- Seudónimos permitidos y por defecto en el rol `colaborador`.
- No almacenar PII de colaboradores más allá de lo indispensable.
- En el buzón de aportes: hash con sal de la IP, nunca la IP en claro. Correo de contacto opcional.
- Firma institucional en las fichas ("Equipo editorial"), no personal, salvo que la persona lo pida.

### 2.5 Presión legal

- Nada se publica sin fuente primaria archivada — la constraint de la BD ya lo garantiza.
- Cita textual, cero adjetivos sobre personas, hechos sobre actos públicos.
- Política de derecho a réplica pública y con plazo: baja mucho la temperatura y sube la credibilidad.
- Registro del dominio con protección de privacidad WHOIS.
- Un abogado revisando el criterio antes de que el proyecto sea visible. No soy abogado.

### 2.6 DDoS y capa de red

Con el sitio estático esto es casi un trámite, pero igual:

- **Cloudflare delante de todo.** El plan gratuito ya trae mitigación L3/L4 ilimitada, y con WAF y rate limiting cubres lo demás.
- **Nunca exponer la IP de origen.** Si el origen se filtra, el CDN deja de servir de escudo. Usa Cloudflare Tunnel o restringe el origen a las IPs de Cloudflare.
- Rate limiting agresivo en los dos únicos endpoints dinámicos: buzón de aportes y login del panel.
- Turnstile (no reCAPTCHA) en el formulario de aportes.
- Modo "Under Attack" documentado en el runbook, con quién lo activa y cuándo.
- Panel interno en subdominio separado, idealmente con acceso restringido por lista de IPs o Cloudflare Access.
- Cabeceras: HSTS, CSP estricta, `X-Content-Type-Options`, `Referrer-Policy`. Una CSP bien puesta es lo que evita que un XSS se convierta en manipulación de contenido.
- Dependabot y escaneo de dependencias activos desde el día uno.

---

## 3. Escalabilidad

| Componente | Decisión | Por qué |
|---|---|---|
| Sitio público | Astro SSG en Netlify + Cloudflare | Costo casi fijo, resiste picos virales |
| Base de datos | Supabase, sólo panel interno y build | Carga proporcional al equipo, no al tráfico |
| Búsqueda | Pagefind (índice estático) hasta ~5.000 fichas | Cero infraestructura, funciona en el navegador |
| Búsqueda (fase 2) | Meilisearch o Typesense autohospedado | Cuando necesites facetas complejas y typo-tolerance |
| Archivo de evidencia | R2/B2, **no servido públicamente** | El egreso de video te quiebra; se sirve bajo demanda |
| Video | Nunca lo hospedas. Embed + tu copia en frío | Costo y licencias |
| Imágenes OG | Generadas en build, cacheadas | Se piden mucho al compartir en WhatsApp/X |

Punto de costo a vigilar: **no sirvas los videos archivados desde el sitio**. Muestra el embed original y ofrece la copia archivada sólo bajo pedido o con enlace firmado y temporal. Si un clip se viraliza y lo estás sirviendo tú, la factura de egreso te puede sorprender.

---

## 4. Descubribilidad: que lo encuentre quien lo necesita

### 4.1 El caso de uso real

Alguien escucha una afirmación en TV, saca el teléfono y busca. Tienes unos treinta segundos. Tu ficha debe aparecer buscando **la afirmación como se dice hablando**, no como tú la titularías.

Consecuencia práctica sobre los títulos:

- ✅ `¿Es cierto que el gasto público creció 3% en 2025?`
- ❌ `Verificación N°142: análisis del discurso presupuestario`

El título contiene la afirmación en lenguaje natural. El veredicto va visible, pero el título replica la pregunta que la gente escribe.

### 4.2 Datos estructurados: la situación en 2026

Aquí hay una novedad importante y un obstáculo que te afecta directamente.

**La novedad:** Google deprecó el resultado enriquecido de fact-check en la búsqueda. El marcado `ClaimReview` sigue existiendo en schema.org y sigue alimentando Fact Check Explorer, pero ya no te va a pintar la cajita de verificación en los resultados. La recomendación actual para publicadores es apoyarse en `NewsArticle`, `Organization` y `Person` con señales fuertes de autoría y experiencia.

Sin embargo, ClaimReview ganó otro público: **los sistemas de IA**. Cada vez más, quien "consulta" tus fichas no es una persona con un navegador sino un asistente respondiendo una pregunta. Marcar bien tu contenido hoy es apostar a que te citen ahí. Yo lo implementaría igual, pero entendiendo que el retorno es a mediano plazo y por ese canal.

**El obstáculo, y es serio:** las directrices de elegibilidad de fact-check de Google excluyen explícitamente a los **sitios políticos**. Si `factos.cl` se presenta como órgano del partido, quedas fuera de ese ecosistema — y probablemente también fuera de la IFCN y de los acuerdos de verificación de las plataformas.

Esto no es un detalle técnico, es una decisión de estructura que tienes que tomar temprano, porque después es carísimo revertirla:

- **Opción A** — El sitio es un proyecto editorial independiente, con enfoque declarado pero separación jurídica y editorial del partido. El partido lo cita como cualquier tercero. Conserva elegibilidad, alcance y capacidad de convencer a quien no es de los tuyos.
- **Opción B** — El sitio es del partido. Ganas control y alineamiento, pierdes el ecosistema de verificación y la audiencia externa.

La opción A es la que hace que se cumpla tu objetivo original de "fuente de la verdad que usen los representantes". Una fuente que es del propio partido no es una fuente: es material de campaña.

### 4.3 Checklist técnico de SEO

- URLs estables y legibles: `/verificacion/2026/gasto-publico-crecio-3-por-ciento`. **Nunca cambiarlas.** Si hay que cambiar, redirección 301 permanente.
- `NewsArticle` + `Organization` + `Person` (autor) en JSON-LD. `ClaimReview` adicional, uno por página.
- Página de metodología, política de correcciones, financiamiento y equipo — enlazadas desde el home. Son señales de confianza y además requisito de cualquier red de verificación.
- Sitemap XML segmentado y actualizado en cada build. `robots.txt` limpio.
- Core Web Vitals: con SSG esto sale gratis, no lo arruines con JavaScript innecesario.
- Feed RSS y **endpoint JSON público** con todas las fichas. Esto último es lo que permite que el partido, medios o terceros construyan encima sin depender de ti.
- OG image por ficha, generada en build: afirmación + veredicto + logo. Es lo que se ve cuando alguien pega el link en WhatsApp, que en Chile es el canal donde esto realmente circula.

### 4.4 Búsqueda interna

- Buscador con autocompletado sobre nombres de actores (el índice trigram del esquema ya está puesto para eso).
- Filtros por: político, tema, veredicto, rango de fecha, institución.
- Página perfil por político con todas sus verificaciones y un contador por veredicto. Es la página que más se comparte en proyectos de este tipo.
- **Kit de vocería**: en cada ficha, un bloque de copiar-pegar con el hecho, la cifra, la fuente y el enlace permanente. Es lo que hace que un representante la use en vivo. Que sea estático y que cargue en un segundo.

---

## 5. Orden de implementación

1. Esquema + Storage + políticas RLS
2. Un harvester determinista contra `opendata.camara.cl` con archivado y hash
3. Panel interno de redacción (Supabase Auth + MFA)
4. Build estático con 10 fichas reales, Cloudflare delante
5. Páginas de metodología, correcciones y financiamiento
6. Búsqueda con Pagefind, OG images, JSON-LD
7. Recién ahí, Hermes sobre las actas de sesiones
8. Buzón de aportes, con Turnstile y rate limiting
9. Audio/video, transcripción y diarización
