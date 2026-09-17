# FACTOS — Contrato editorial (D2 y D3)

> Documento público. Se publica íntegro en `/metodologia` y `/que-verificamos`.
> Es el contrato con el lector: define cómo se decide un veredicto y cómo se elige
> qué verificar. Cambiarlo obliga a revisar las fichas ya publicadas bajo el
> criterio anterior.
>
> **Versión:** 1.0 · **Estado:** borrador para ratificar
> **Nota sobre los ejemplos:** son construcciones ilustrativas, sin atribución a
> personas reales. Al ratificar, se reemplazan por casos reales ya verificados.

---

# D2 · Escala de veredictos

## Reglas generales

Antes de la escala, seis reglas que aplican a todo veredicto. Son las que evitan los errores que hunden a un proyecto de verificación.

1. **Se califica la afirmación, no a la persona.** No existe "político falso". Existe una afirmación falsa, en una fecha, en un contexto.
2. **Una afirmación, un veredicto.** Si un enunciado contiene varias afirmaciones verificables, se separan en fichas distintas. Nunca se promedia.
3. **El veredicto se ancla a la fecha del dicho.** Se evalúa contra la información oficial disponible en ese momento. Si un dato oficial se corrige después, no convierte retroactivamente la afirmación en falsa: se anota en la ficha.
4. **La duda favorece al verificado.** Si dos lecturas razonables de la fuente son posibles, se aplica el veredicto más benigno, o `no_verificable`. Nunca el más lesivo.
5. **Tolerancia de redondeo.** Una cifra aproximada acompañada de marcador de aproximación ("cerca de", "casi", "alrededor de") es exacta si cae dentro de ±5 % relativo del valor oficial. Sin marcador de aproximación, el margen es ±1 %. Si la desviación excede el margen pero no altera la conclusión, es `impreciso`, no `falso`.
6. **Todo veredicto exige evidencia archivada.** Sin excepción, incluida `no_verificable`, que debe documentar dónde se buscó.

---

## La escala

### 1 · `exacto`

**Definición.** La afirmación coincide con la fuente oficial, y su uso en contexto no induce a una conclusión errada.

**Se aplica cuando:** la cifra, el hecho o la atribución son correctos, y el marco en que se dicen es fiel.

**No se aplica cuando:** el dato es correcto pero el contexto lo distorsiona → `exacto_descontextualizado`.

> *Ejemplo ilustrativo.* Afirmación: "este proyecto se aprobó con 89 votos a favor". El registro de votación consigna 89 a favor. → `exacto`.

**Importa publicarlos.** Un sitio que sólo publica veredictos negativos no es un verificador, es un archivo de acusaciones. Las fichas `exacto` son las que hacen creíbles a las demás.

---

### 2 · `exacto_descontextualizado`

**Definición.** El dato es correcto, pero se presenta de modo que induce una conclusión que la propia fuente no sostiene.

**Se aplica cuando:** hay selección interesada del período, comparación con una base no comparable, omisión de un factor determinante, o se presenta una correlación como causa.

**No se aplica cuando:** el dato mismo está mal → `impreciso` o `falso`.

> *Ejemplo ilustrativo.* Afirmación: "el gasto en este programa se duplicó desde que asumimos". El monto efectivamente se duplicó, pero el año base elegido es el de menor ejecución de la década, y en términos reales el crecimiento es marginal. → `exacto_descontextualizado`.

**Es el veredicto más difícil y más útil.** Exige que la ficha explique con precisión cuál es el contexto omitido y por qué cambia la lectura. Sin esa explicación, no se publica.

---

### 3 · `impreciso`

**Definición.** La afirmación es parcialmente correcta, pero contiene un error material que altera su magnitud o su alcance.

**Se aplica cuando:** la cifra excede el margen de tolerancia, se atribuye mal una autoría parcial, se confunden unidades o períodos, o se generaliza indebidamente un caso.

**No se aplica cuando:** el error invierte el sentido de la afirmación → `falso`.

> *Ejemplo ilustrativo.* Afirmación: "esta medida beneficia a más de un millón de personas". La fuente oficial consigna 640.000. La medida existe y beneficia a mucha gente, pero la magnitud está inflada en más de un 50 %. → `impreciso`.

---

### 4 · `falso`

**Definición.** La afirmación contradice la información oficial disponible.

**Se aplica cuando:** existe una fuente que dice lo contrario. La clave es que **hay dato y no coincide**.

**No se aplica cuando:** no hay dato con el cual contrastar → `no_verificable`. Confundir estos dos es el error más caro que puede cometer este proyecto.

> *Ejemplo ilustrativo.* Afirmación: "voté en contra de ese proyecto". El registro nominal de votación consigna su voto a favor. → `falso`.

---

### 5 · `insostenible`

**Definición.** No existe base fáctica alguna que sustente la afirmación, y no es posible identificar de dónde podría provenir.

**Se aplica cuando:** se cita una cifra que ninguna fuente registra, se atribuye a un organismo un informe inexistente, o se afirma un hecho que ninguna fuente documenta.

**Diferencia con `falso`:** en `falso` hay un dato oficial que contradice. En `insostenible` no hay dato de ningún tipo, ni a favor ni en contra, y la afirmación se presenta como si lo hubiera.

**Diferencia con `no_verificable`:** en `no_verificable` la información podría existir pero no es pública. En `insostenible` se buscó donde tendría que estar y demostradamente no está.

**Exigencia probatoria alta.** Para calificar así hay que documentar todas las fuentes consultadas y por qué son el lugar donde el dato debería aparecer. Es el veredicto más grave; se usa poco y con evidencia sobrante.

---

### 6 · `no_verificable`

**Definición.** No existe información pública suficiente para evaluar la afirmación.

**Se aplica cuando:** el dato no se publica, está en un organismo que no lo entrega, o la afirmación depende de información privada o de proyecciones.

**No es un veredicto negativo.** No dice que la afirmación sea falsa. Dice que el Estado no permite comprobarla, lo que en sí mismo es información relevante para el lector.

**Obligación adicional:** la ficha debe consignar qué fuentes se consultaron, y si se presentó una solicitud por Ley de Transparencia. Si la respuesta llega después, la ficha se actualiza y el veredicto puede cambiar, con registro en el historial de correcciones.

> *Ejemplo ilustrativo.* Afirmación: "este programa tiene una tasa de deserción del 8 %". El organismo no publica tasas de deserción y no respondió la solicitud de transparencia dentro del plazo. → `no_verificable`, con la solicitud documentada.

---

## Presentación en la ficha

- El veredicto va visible junto al título, con etiqueta de texto además de color. Nunca sólo color: excluye a lectores con daltonismo y no sobrevive a una captura en blanco y negro.
- La escala completa se enlaza desde cada ficha.
- El veredicto nunca aparece en el título. El título replica la pregunta que la gente busca.

---

# D3 · Criterio de selección — qué verificamos

Este es el documento que decide si el proyecto sirve para convencer a alguien que no está de acuerdo contigo. Si el criterio no es público y no se aplica parejo, la base se convierte en un archivo de munición y su veredicto deja de importarle a nadie fuera del propio sector.

## Qué es una afirmación verificable

Se verifica una afirmación cuando cumple **las cuatro condiciones**:

1. **Es fáctica.** Afirma algo sobre el mundo que puede ser contrastado. No es una opinión, una promesa, una predicción ni un juicio de valor.
2. **Es contrastable con fuente oficial o documentada.** Existe —o debería existir— un registro público contra el cual medirla.
3. **Es sobre actos públicos.** Votaciones, gasto, regulación, gestión, declaraciones previas, cifras invocadas para justificar una política. Nunca sobre vida privada.
4. **La hace alguien con poder o influencia sobre política pública, en un canal público.** Autoridades, parlamentarios, candidatos, dirigentes de partido, altos funcionarios. En sesión, prensa, redes oficiales o acto público.

## Qué no se verifica

- Opiniones y juicios de valor ("esta es la peor reforma de la historia").
- Promesas y predicciones a futuro. *Sí* se verifica después si se afirma haberlas cumplido.
- Declaraciones sobre intenciones o estados mentales propios o ajenos.
- Vida privada, familia, patrimonio no sujeto a declaración obligatoria.
- Afirmaciones de personas sin rol público, aunque circulen mucho.
- Chistes, ironías y figuras retóricas evidentes.
- Afirmaciones cuya verificación exigiría revelar la identidad de una fuente en riesgo.

## Cómo se prioriza

Cuando hay más candidatas que capacidad —siempre—, se ordenan por estos criterios, en este orden:

1. **Impacto.** La afirmación se usa para justificar gasto público, una regulación o una decisión de política.
2. **Alcance.** Circula ampliamente, o la repiten terceros como hecho establecido.
3. **Verificabilidad.** Existe fuente primaria clara. Entre dos candidatas equivalentes, se prioriza la que se puede probar mejor.
4. **Vacío.** Nadie más la ha verificado.

**Nunca es criterio de priorización:** quién la dijo, ni si el resultado esperado favorece o perjudica a algún sector.

## Las reglas de simetría

Son el mecanismo concreto contra el sesgo de selección. Sin ellas, el resto de este documento es decorativo.

**S1 · El criterio se aplica sin mirar el sector.** Una afirmación que cumple las cuatro condiciones entra a la cola, venga de donde venga.

**S2 · Se verifica al propio sector.** Toda afirmación de autoridades, parlamentarios o dirigentes afines que cumpla las cuatro condiciones se verifica con el mismo estándar. Esta regla no es un gesto: es lo que hace que las demás fichas sean caras de refutar.

**S3 · Transparencia estadística trimestral.** Se publica la composición de las fichas del trimestre por sector político del actor verificado y por veredicto. El lector puede juzgar el sesgo con datos, no con nuestra palabra.

**S4 · Revisión de criterio, nunca de veredicto.** Si la distribución trimestral queda muy concentrada en un sector, se revisa **el criterio de selección y las fuentes de detección** para ver si hay un sesgo en cómo se buscan candidatas. Jamás se ajusta un veredicto ni se fuerza una cuota para equilibrar. El veredicto responde a la evidencia y a nada más.

**S5 · Las candidatas descartadas quedan registradas.** Con el motivo del descarte. El registro es auditable internamente y su resumen agregado se publica junto a S3.

## Conflicto de interés

- Quien tenga relación laboral, familiar, contractual o de militancia directa con el actor verificado no puede ser verificador ni revisor de esa ficha. Se declara y se reasigna.
- El financiamiento del proyecto es público y está en `/financiamiento`.
- Si un financista aparece como actor verificado, se consigna en la ficha.

## Derecho a réplica

- Toda persona verificada puede solicitar réplica. La vía y el plazo son públicos.
- La réplica se enlaza desde la ficha, sin edición de su contenido.
- Si la réplica aporta evidencia nueva, se abre una corrección con el procedimiento estándar y el veredicto puede cambiar.
- Bajar la temperatura por esta vía es más barato que ganar una discusión pública.

---

## Compromiso de corrección

Cuando nos equivocamos:

1. La corrección es visible en la ficha, con fecha, campo afectado y valor anterior.
2. La URL nunca cambia y nunca da 404, ni siquiera si la ficha se retira.
3. Si el error fue material y la ficha circuló, la corrección se difunde por los mismos canales.
4. El historial completo es público en `/correcciones`.

Un proyecto que corrige a la vista es más difícil de atacar que uno que nunca se equivoca.
