# Las leyes de JET, explicadas desde cero

Este documento cubre exactamente las mismas 234 leyes que `LEYES_CATALOGO.md`, pero construyendo el vocabulario paso a paso para que se entienda todo sin conocimientos previos de fusión nuclear ni de demostración formal. Si en algún punto una palabra te resulta rara, probablemente la definimos unas secciones antes: usá el índice para volver.

## Índice

0. [Qué es este documento](#0-qué-es-este-documento)
1. [El problema en una frase](#1-el-problema-en-una-frase)
2. [Qué es JET y qué está protegiendo](#2-qué-es-jet-y-qué-está-protegiendo)
3. [Qué significa "demostrar" algo acá](#3-qué-significa-demostrar-algo-acá)
4. [El diccionario mínimo](#4-el-diccionario-mínimo)
5. [Cómo leer un fragmento de código de prueba](#5-cómo-leer-un-fragmento-de-código-de-prueba)
6. [Las leyes de comportamiento — 81 leyes](#6-las-leyes-de-comportamiento--81-leyes)
7. [Las leyes de la tabla de configuración — 143 leyes](#7-las-leyes-de-la-tabla-de-configuración--143-leyes)
8. [Las leyes de "la protección siempre llega a tiempo" — 2 leyes](#8-las-leyes-de-la-protección-siempre-llega-a-tiempo--2-leyes)
9. [Las leyes de plomería matemática — 8 leyes](#9-las-leyes-de-plomería-matemática--8-leyes)
10. [Resumen: qué es de JET y qué es nuestro](#10-resumen-qué-es-de-jet-y-qué-es-nuestro)
11. [Glosario rápido](#11-glosario-rápido)

---

## 0. Qué es este documento

`prooflock` es un proyecto que toma un sistema de protección real y publicado —el de la máquina de fusión JET, en Inglaterra—, reconstruye su lógica de decisión como un modelo a partir de las publicaciones abiertas de JET, completando cada hueco con un supuesto declarado (§3), y demuestra matemáticamente que ese modelo cumple ciertas reglas **en todos los casos posibles**, no sólo en los casos que alguien probó a mano. El resultado son 234 enunciados matemáticos ("leyes"), cada uno verificado por un verificador de pruebas, un programa que acepta una demostración sólo si cada paso es válido (el verificador, Bend 2, es a su vez software no calificado: `phase3-safety.md` §5).

Este documento explica, de a poco, todo lo necesario para leer esas 234 leyes: qué problema resuelven, qué es JET, qué significa "demostrar" algo, cómo se lee el código, y después sí, ley por ley, qué dice cada una y de dónde sale.

Las especificaciones, las leyes y las demostraciones las escribió un sistema de IA (Claude), dirigido y auditado por un autor humano; el verificador juzga cada demostración, y las revisiones adversariales que se mencionan más abajo fueron pasadas automatizadas de otras instancias de la misma familia de modelos, no una evaluación humana independiente (README §7).

---

## 1. El problema en una frase

**¿Cómo podés estar seguro de que un sistema de seguridad funciona bien en TODOS los casos, y no sólo en los pocos que alguien probó?**

Pensalo así: si querés confirmar que un puente aguanta camiones pesados, podés hacer pasar 71 camiones distintos y ver que no se cae. Eso te da confianza, pero no certeza: quizás el camión 72, con una combinación de peso y velocidad que nadie probó, sí lo rompe.

JET validó así su secuenciador de protección cuando lo rehízo en 2017 ([S3]): con **71 "pulse schedules"** (guiones de experimento, definidos por el grupo de operaciones de plasma de JET) como casos de prueba, más pruebas unitarias de cada pieza por separado. Es el método estándar en ingeniería y funciona razonablemente bien, pero tiene ese límite: sólo cubre los casos que a alguien se le ocurrió probar.

Este proyecto hace la otra cosa: en vez de probar 71 casos, **demuestra matemáticamente** que una propiedad vale para **todos los casos posibles** del modelo, así sean millones. No es una promesa más fuerte sobre JET en particular (JET validó su secuenciador con esos 71 casos, y esa validación era perfectamente razonable); es una demostración de que existe un método distinto y complementario, usando JET como ejemplo real y publicado porque, entre los sistemas de protección que revisamos (`phase3-sources.md` §1), es el único con su lógica publicada a nivel de tabla en fuentes abiertas.

**Importante, para que quede claro desde el principio:** el objeto de este proyecto no es certificar que JET es seguro. JET operó con sus propias validaciones. El objeto es mostrar que el método de "probar todos los casos con matemática, no sólo unos pocos con pruebas" es aplicable a un sistema de protección real y de tamaño realista, como un primer paso hacia usarlo en sistemas de seguridad nucleares de verdad (ver §2 sobre el tipo exacto de sistema que es).

---

## 2. Qué es JET y qué está protegiendo

**JET** (Joint European Torus) es una máquina de fusión nuclear: calienta un gas hasta convertirlo en plasma (un cuarto estado de la materia; el de JET es más caliente que el centro del Sol) y lo confina con campos magnéticos con la esperanza de producir energía por fusión, igual que el Sol. Cada experimento se llama un **pulso**: dura de segundos a poco más de un minuto, y durante ese tiempo el plasma pasa por varias **fases** (arranque, formación, calentamiento, terminación) con reglas distintas en cada una.

El plasma es difícil de controlar y, si algo sale mal, puede golpear las paredes de la máquina con mucha energía (una "disrupción"). Por eso JET tiene un sistema automático que vigila decenas de señales y, si detecta un problema, apaga cosas o frena el experimento antes de que se dañe el equipo. **Eso es lo que este proyecto modela y demuestra: la lógica de decisión de ese sistema de protección**, no el plasma en sí ni los actuadores físicos.

Tres piezas, de la más simple a la más severa:

- **RTPS** (*Real-Time Protection Sequencer*, "secuenciador de protección en tiempo real"). Es el cerebro: mira qué fase del experimento está corriendo y qué alarma llegó, y decide qué tan grave es la respuesta, con margen para elegir entre varias opciones intermedias.
- **PTN** (*Pulse Termination Network*, "red de terminación de pulso"). Es el botón de pánico final: una señal cableada directo, que cuando se activa **apaga todo y queda trabada** (no se puede "reactivar" a mitad de pulso). Una vez que suena, no hay marcha atrás hasta terminar el experimento.
- **DMS** (*Disruption Mitigation System*, "sistema de mitigación de disrupciones", también llamado DMV por la válvula que dispara). Es la última red de contención: si igual va a haber una disrupción, inyecta gas al plasma para dispersar su energía de forma menos dañina. No se dispara solo: primero hay que apagar los calentadores (si siguen prendidos cuando se inyecta gas, es peligroso para el equipo), y recién después de una confirmación o de esperar un tiempo, se dispara la válvula.

**Una aclaración que aparece una y otra vez en la documentación de JET, y que conviene tener clara desde ya:** este sistema (RTPS + PTN) protege la **inversión** —el equipo, las paredes, los calentadores— no protege directamente a las personas. A las personas las protege otro sistema, el PSACS (Personal Safety & Access Control System, [S2]); por debajo del RTPS y del PTN está además el CISS (Central Interlock and Safety System), que [S1] describe como "basic hardwired plant protection" (traducción nuestra: protección básica cableada de la planta). Ninguno de los dos está modelado. Este proyecto no es evidencia de que un sistema de seguridad nuclear funcione: es evidencia de que el **método** (demostrar en vez de sólo probar) es viable en un caso de este tamaño y complejidad, y por eso el argumento de que el método se puede extender a funciones de seguridad nuclear real se hace aparte, con cuidado, en otro documento (`phase3-safety.md`).

---

## 3. Qué significa "demostrar" algo acá

Cuando decimos que una ley está "demostrada" no queremos decir "la probamos varias veces y funcionó". Queremos decir algo mucho más fuerte: **no puede ser falsa**, dado el modelo y un verificador correcto. (El verificador, Bend, es a su vez software no calificado; por eso el certificado se vuelve a chequear en Python y se corre contra las leyes un banco de errores plantados a propósito, `phase3-safety.md` §5.)

### La idea del "para todo"

Pensemos en un ejemplo simple: la afirmación *"para todo número par n, n+2 también es par"* es cierta para infinitos números. No hace falta probarla con el 2, el 4, el 6... hasta el infinito: se demuestra **una sola vez**, con un argumento general, y esa demostración cubre automáticamente los infinitos casos.

Acá pasa algo parecido, pero más manejable: el número de "casos posibles" no es infinito, es **enorme pero finito** (del orden de cientos de miles). Entonces hay dos maneras de demostrar una ley:

1. **Por fuerza bruta verificada** (le decimos **certificado**): una computadora revisa, una por una, las 462 336 "celdas" del chequeo (todo estado con todo evento y, en cinco de los 28 eventos, cada combinación de dos señales sí/no de los contadores: el paso sólo las lee en los dos ticks de reloj, y en otros tres eventos el verificador no puede descartarlas por su cuenta, §6.7), una vez para cada uno de los dos órdenes de urgencia posibles (§6.1), y confirma que la propiedad vale en cada una. Esto no es "probar unos casos": es probar *todos*, literalmente, uno por uno, con la precisión exacta de una computadora haciendo aritmética (no hay redondeo, no hay azar).
2. **Por argumento general** (le decimos **inducción**): para propiedades sobre secuencias completas de eventos (como "en algún momento la protección siempre llega"), no alcanza con mirar un paso a la vez; hay que razonar sobre secuencias de cualquier largo, como con los números pares de arriba.

Casi todas las 234 leyes usan una de estas dos formas; las celdas de la tabla de configuración de §7 son evaluaciones sueltas, y los 8 lemas de plomería de §9 son revisiones caso por caso, la misma idea en chiquito. En ambos casos, el resultado final lo verifica un programa llamado **Bend**, que no acepta una demostración a menos que esté escrita con total precisión matemática: si falta un paso lógico, Bend se niega a aceptar la prueba. Por eso decimos "demostrado", no "probado" ni "parece que funciona".

### Una distinción que importa mucho: hecho vs. supuesto

Cada ley de este catálogo afirma algo sobre un **modelo** de JET, no sobre la máquina física. El modelo se construyó en dos capas:

- **Hechos documentados**: frases citadas textualmente de los papers publicados sobre JET (identificados como **R-0, R-1, R-2... R-15** en la documentación de origen; desde la revisión 4 también frases de [N1], un paper de De Tommasi y otros de 2013 sobre los stops de JET, citado con la página del PDF). Son citas literales, como transcribir el testimonio de un testigo palabra por palabra. Como los papers están en inglés, cuando damos la frase en castellano es una traducción nuestra: donde la exactitud importa va también el original en inglés, y el original de cada R-n está en `phase3-sources.md` §3.
- **Supuestos nuestros**: decisiones de modelado que tomamos nosotros para rellenar lo que los papers no dicen (identificados como **A-1, A-2... A-35**). Son como las inferencias razonables de un detective: el testigo no dijo todo, pero hay una manera razonable de completar el resto, y la declaramos explícitamente en vez de esconderla.

Por ejemplo: JET publica que el RTPS "was able to act hierarchically so that subsequent alarms could generate a more urgent stop" (traducción nuestra: podía actuar de forma jerárquica, de modo que alarmas posteriores podían generar un stop más urgente; eso es un hecho, R-7, de [S2]). Pero JET **no** publica en qué orden exacto de urgencia van dos de las cuatro respuestas posibles (eso lo decidimos nosotros, es el supuesto A-1). La ley que usa ese orden es entonces una **mezcla**: el mecanismo es de JET, el detalle exacto es nuestro.

Cada ley de este catálogo lleva una etiqueta de origen:

| Etiqueta | Qué significa en criollo |
|---|---|
| **HECHO JET** | Lo que dice la ley está citado, casi palabra por palabra, en un paper publicado sobre JET. Una aclaración declarada que no agrega contenido no cambia la etiqueta; tampoco la cambia que el modelo no tenga reloj (todo efecto ocurre en un paso, A-15), porque eso vale para todas las leyes. Si la ley agrega algo que el paper no dice (lo extiende a casos que el paper no cubre, o fija un detalle que formalizamos nosotros), va como MEZCLA. |
| **SUPUESTO** | Lo que dice la ley es una decisión nuestra. Puede estar *motivada* por algo que JET publicó, pero el contenido exacto no está escrito en ningún lado; lo completamos nosotros, de forma declarada. |
| **MEZCLA** | El mecanismo general es un hecho de JET; la forma exacta (qué orden, qué fase se lee, qué política, a qué casos se extiende) es nuestra. |
| **PLOMERÍA** | La ley existe por cómo funciona la demostración matemática (el método), no dice nada sobre JET. Es "infraestructura" de la prueba. |

---

## 4. El diccionario mínimo

Antes de meternos en las leyes, definimos las piezas que se van a repetir todo el tiempo. Conviene leer esta sección entera una vez; después funciona como referencia.

### 4.1 Estado: una "foto" de la máquina en un instante

Un **estado** es toda la información relevante sobre JET en un instante dado. En este modelo, un estado tiene ocho datos (piensen en ocho casilleros que hay que llenar):

| Casillero | Qué guarda | Valores posibles |
|---|---|---|
| **fase del programa** | En qué etapa del pulso está el experimento | Breakdown (arranque), IpRise (subida de corriente), Limiter, X-point (el plasma pasa a una configuración con punto X), Heating 1, Heating 2, Termination |
| **bandera "jtt"** | Si se aceptó un salto directo a la terminación (ver más abajo) | sí / no |
| **nivel de respuesta en vigor** | Qué tan grave es el stop activo ahora mismo | Ninguno, JTT, RTPS, PTN (de menos a más grave) |
| **estado del DMS** | En qué paso está la secuencia de disparo de la válvula de emergencia | Idle (en reposo), Armed (armado, esperando), Fired (disparado) |
| **plasma** | Si las condiciones básicas del plasma (corriente, densidad) están OK | sí / no |
| **veredicto de habilitación del DMV** | El "veredicto de habilitación" de la válvula de emergencia: si la corriente del plasma **o** la energía almacenada en el plasma están por encima de su umbral, de modo que la válvula se pueda armar (A-22: es la forma de la condición en un ejemplo del paper de PETRA [S7], su figura 2, y del límite para operar sin la válvula en [K15]; el paper anterior de la válvula, [S6], usaba sólo la corriente). El modelo no ve los números, sólo el sí o no | sí / no |
| **unidad de calentamiento NB** | Estado de los haces de partículas neutras (*Neutral Beam*, uno de los dos sistemas que calientan el plasma) | Off, Ramping (bajando), Reduced (potencia parcial), On (potencia plena) |
| **unidad de calentamiento RF** | Estado del calentamiento por radiofrecuencia (el otro sistema) | Off, Ramping, Reduced, On |

A esto se le suman **dos contadores** (números que cuentan ticks del reloj): uno cuenta cuánto hace que no llega una señal de "sigo vivo" del sistema (para el vigía de abajo), y otro cuenta cuánto hace que el DMS está esperando una confirmación.

### 4.2 Evento: algo que pasa

Un **evento** es lo único que puede cambiar un estado: una alarma que suena, un comando, el paso del reloj, un reinicio. Hay 28 tipos posibles: por ejemplo "llegó una alarma que pide tal respuesta", "avanzá a la siguiente fase", "prendé el calentador RF", "pasó un tick del reloj", "llegó la confirmación de la planta de calentamiento", "fin de pulso".

### 4.3 Paso: la regla de "qué pasa después"

El **paso** es la función matemática central del modelo: toma un estado y un evento, y devuelve el estado siguiente. Todo el comportamiento del sistema está descrito por esta única función; las 234 leyes son, en el fondo, todas afirmaciones sobre qué hace (o no hace) esta función.

### 4.4 Traza: la historia completa de un pulso

Una **traza** es una lista ordenada de eventos: la secuencia completa de todo lo que le pasó a JET durante un pulso, desde el arranque hasta el final. "Correr una traza" significa aplicar el paso, evento tras evento, y ver en qué estado se termina.

### 4.5 Invariante: una regla que nunca se rompe

Un **invariante** es una propiedad que es verdadera en el estado inicial y que **sigue siendo verdadera después de cualquier evento, para siempre**. Es como decir "el nivel de agua de este tanque nunca supera la línea roja, pase lo que pase": no hace falta chequearlo en cada instante si podés demostrar que (a) empieza por debajo de la línea y (b) ningún mecanismo del tanque puede hacer que la suba de un salto por encima. En este modelo hay seis invariantes de control (llamados **I1** a **I6**), por ejemplo "si el DMS no está en reposo, el nivel de respuesta tiene que ser PTN" (I4).

### 4.6 Ley: un enunciado matemático demostrado

Una **ley**, en este catálogo, es un enunciado del tipo *"para todo estado y todo evento posible, si pasa tal cosa, entonces pasa tal otra"*, que fue demostrado con certeza matemática (no sólo observado en algunos casos). Cada una de las 234 filas de este catálogo es una ley.

### 4.7 Certificado: la fuerza bruta verificada por computadora

Un **certificado** es el resultado de recorrer, por computadora, absolutamente todas las celdas posibles (un estado, un evento y, en cinco de los 28 eventos (§6.7), los dos verdictos de los contadores: 462 336 celdas por orden de urgencia) y confirmar que ciertas propiedades valen en cada una. Una vez que el certificado existe, muchas de las leyes se deducen de él automáticamente ("por reflexión": la demostración simplemente *lee* el resultado del certificado en vez de razonar de nuevo caso por caso).

### 4.8 Instancia de configuración: "la misma máquina, distinto ajuste"

La **tabla de configuración** de JET dice qué respuesta corresponde a cada combinación de (fase del experimento, tipo de alarma). Esa tabla la fija el jefe del experimento antes de cada pulso: no es fija en el sistema, es un ajuste. Este proyecto certifica cuatro **instancias** (cuatro configuraciones distintas, para probar que el método funciona con cualquiera): la instancia 1 es la tabla que JET publicó, la instancia 2 es una variante razonable (motivada por otro paper) donde una alarma que en la tabla publicada "no hace nada" en realidad sí dispara protección, la instancia 3 es la misma tabla publicada pero con dos chequeos de seguridad extra apagados (para probar que el método detecta esa diferencia), y la instancia 4 (agregada en la revisión 4) es la tabla publicada con otra forma de responder a una **segunda** alarma que llega cuando ya hay un stop en curso: en vez de volver a leer la tabla de siempre, pide el PTN donde la tabla de siempre pide alguna respuesta, y nada donde no pide nada (así que una alarma de modo bloqueado, que la tabla publicada deja sin respuesta, sigue sin respuesta). Esa "tabla secundaria" es **ilustrativa**, inventada por nosotros; la de JET no está publicada (A-35).

---

## 5. Cómo leer un fragmento de código de prueba

Las leyes están escritas en **Bend 2**, un lenguaje de programación de uso general (compila a C, CUDA, Metal y JavaScript) cuyo verificador de tipos también verifica demostraciones matemáticas; acá sólo importa el verificador. No hace falta saber programar para leerlo: es cuestión de aprender un puñado de símbolos. Los traducimos una sola vez acá, con un ejemplo real y simple.

```bend
law ptn_deenergizes:                                              # (1)
  for +o: S.Ord                                                   # (2)
  for +f: S.Fin                                                   # (3)
  for +e: S.Ev                                                    # (4)
  for +bt: Bool                                                   # (5)
  for +bh: Bool                                                   # (5)
  {Spec.pr_p2(f, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}   # (6)
```

1. **`law nombre:`** — el nombre de lo que se está demostrando. Es lo que citan los "tests negativos" (pruebas que introducen un error a propósito y confirman que la demostración lo detecta) cuando dicen "esto viola la ley `ptn_deenergizes`".
2. **`for +o: S.Ord`** — "esto vale **para cualquiera** de los dos órdenes de urgencia posibles". Cuál de los dos es el correcto es un supuesto nuestro (§4.8 y §6.1), así que toda ley que lleva esta línea se demuestra para ambos. (Las pocas leyes de la capa concreta, la de los eventos propios de la planta, corren sólo con el orden que elegimos, `Ord1`: A-1.)
3. **`for +f: S.Fin`** — "para cualquier estado `f`". El prefijo `S.` sólo indica "este tipo viene del archivo que define el modelo". El `+` es un detalle técnico de Bend (permite usar la variable más de una vez) y se puede ignorar al leer.
4. **`for +e: S.Ev`** — "para cualquier evento `e`".
5. **`for +bt: Bool` y `for +bh: Bool`** — "para cualquier valor de los dos verdictos de contador": si al contador de espera del DMS y al del vigía de latido les queda margen o no (§4.1). Entran como Sí/No para que la ley no dependa del número exacto que tenga el contador.
6. **`{... == True{} : Bool}`** — la afirmación concreta: el predicado `pr_p2` (una función que devuelve Sí/No), evaluado en el estado `f` y en el estado siguiente, da **Sí**. `S.step_fin(o, f, e, bt, bh)` es justamente "el estado siguiente": el resultado de aplicar el paso (§4.3) a `f` con el evento `e`. El prefijo `Spec.` indica "viene del archivo que define las propiedades a verificar". El predicado `pr_p2` en criollo dice: *"si el paso hace que el nivel de respuesta llegue a PTN, entonces las dos unidades de calentamiento quedan apagadas"*.

Hay un detalle que conviene mirar de cerca: el estado siguiente **no** se cuantifica como "cualquier estado", se escribe como el resultado del paso. La diferencia no es cosmética. Si la ley dijera "para todo estado siguiente `f2`" sería directamente **falsa**, porque nada impediría elegir un `f2` inventado con el PTN activo y los calentadores prendidos. Lo que se afirma es sobre el estado que el modelo realmente produce, no sobre cualquier estado imaginable.

Entonces, esta ley completa se lee: **"para todo orden de urgencia, todo estado, todo evento y cualquier valor de los dos contadores: si el paso hizo que se llegara a PTN, las dos unidades de calentamiento quedaron apagadas."** Y como es "para todo", cubre de una sola vez todo estado, todo evento y todo par de verdictos, para cada orden (10 752 × 28 × 4 = 1 204 224 casos). El certificado los decide con sus 462 336 celdas: el paso sólo lee los verdictos en los dos ticks de reloj (lo demuestran las leyes `verdict_frame` de §6.7), así que en 23 de los 28 eventos un solo par de verdictos vale por los cuatro; los otros 5 se chequean con los cuatro.

Otros símbolos que van a aparecer:

- **`for +h: {condición}`** — una **hipótesis**: no es parte de la conclusión, es una condición que tiene que cumplirse para que la ley aplique. Ejemplo: `for +h: {S.inv_all(s) == True{} : Bool}` quiere decir "asumiendo que el estado `s` cumple el invariante".
- **`Bool.and(A, B)`**, **`Bool.or(A, B)`**, **`Bool.not(A)`** — Y, O, NO lógicos, como en cualquier clase de lógica proposicional.
- **`S.implies(A, B)`** — "si A entonces B" (si A es falso, la afirmación es automáticamente verdadera: no dice nada sobre B).
- **`match e: case S.Tick{...}: ... case _: ...`** — "según qué tipo de evento sea `e`, hacé una cosa u otra"; el `case _:` es el caso "cualquier otro".
- **`...`** dentro de un bloque de código — una parte que se omite para que el ejemplo sea corto; los bloques de §8 además escriben sus hipótesis en palabras, entre llaves. Esos bloques son esquemáticos, no Bend válido: los enunciados exactos están en los archivos `LAWS_*.bend`.
- **`{A == B : T}`**, donde `T` es el tipo de `A` y `B` (por ejemplo `S.Level`, el tipo de los niveles de respuesta, en §9): la meta es una **igualdad exacta** entre dos valores, no una respuesta Sí/No. Las leyes de "plomería" de §9 atan a esta igualdad un predicado Bool que dice "iguales".

Con esto ya se puede leer cualquiera de las 234 leyes. Vamos a los grupos.

---

## 6. Las leyes de comportamiento — 81 leyes

Este es el archivo principal (`LAWS_JETPROT.bend`). Se organiza en familias, cada una con un propósito distinto. Las presentamos en el orden en que conviene entenderlas, no necesariamente el orden del archivo.

### 6.1 Los certificados (3 leyes) — PLOMERÍA

Antes de cualquier ley individual, hay que construir la base: el chequeo de fuerza bruta sobre las 462 336 celdas de cada orden.

```bend
law finite_check:
  {E.check_fin(S.Ord1{}) == True{} : Bool}
```

`check_fin` es una función que recorre, una por una, todas las celdas (un estado, un evento y, en cinco de los 28 eventos (§6.7), los verdictos de los contadores) bajo el orden de urgencia que elegimos (`Ord1`: Ninguno < JTT < RTPS < PTN) y confirma que cada ley de "paso" de §6.3-§6.5 (salvo F1a, F1c e IP2, que se demuestran directamente) y las cinco de §6.8 sobre el PTN y el primer stop valen en esa celda. Esta ley dice: "ese recorrido dio Sí en absolutamente todas". Es la base sobre la que se apoyan casi todas las demás leyes de esta sección (se deducen de ella "por reflexión": una vez que sabés que vale en todas las combinaciones, sabés automáticamente que vale en cualquiera en particular).

```bend
law finite_check_alt:
  {E.check_fin(S.Ord2{}) == True{} : Bool}
```

Lo mismo, pero con el **otro** orden de urgencia posible (`Ord2`: Ninguno < RTPS < JTT < PTN). ¿Por qué probar los dos? Porque cuál de los dos órdenes es "el correcto" es un **supuesto nuestro** (A-1: JET no publica un orden único entre JTT y RTPS). Al demostrar cada ley abstracta para ambos órdenes, nos aseguramos de que ninguna dependa "por casualidad" de haber elegido uno en particular. (La excepción, declarada en A-1: las leyes de la capa concreta y de la configuración se certifican sólo con el orden elegido, `Ord1`.)

```bend
law corollaries_check:
  {E.check_cor() == True{} : Bool}
```

Un segundo recorrido, esta vez sobre los estados que cumplen el invariante, para verificar cuatro propiedades adicionales ("corolarios", §6.6).

**Origen: PLOMERÍA** las tres. Son el método, no hechos ni supuestos sobre JET.

### 6.2 Los invariantes generales (6 leyes) — SUPUESTO/MEZCLA/PLOMERÍA

```bend
law inv_init:
  {S.inv_all(S.init()) == True{} : Bool}
```

El estado inicial —arranque del pulso, todo apagado, sin ninguna alarma activa, contadores en cero— ya cumple el invariante completo. Es el "punto de partida" de la demostración por inducción. **Origen: SUPUESTO** (que el pulso arranque así es nuestra elección razonable de estado inicial, A-5 y A-12).

```bend
law pres_fin:
  for +o: S.Ord
  for +s: S.St
  for +h: {S.inv_all(s) == True{} : Bool}
  for +e: S.Ev
  {S.inv_fin(...) == True{} : Bool}
```

"Para cualquier orden, cualquier estado que ya cumple el invariante, y cualquier evento: después de dar un paso, el invariante de control (I1-I4) se sigue cumpliendo." Esta es la ley que hace que el invariante sea, efectivamente, invariante: no importa cuánto tiempo pase ni cuántos eventos lleguen, la propiedad nunca se rompe.

Los cuatro invariantes de control que cubre:
- **I1**: una unidad de calentamiento sólo puede estar prendida (plena o parcial) si la ventana de calentamiento está abierta, hay plasma OK y no hay ningún stop activo.
- **I2**: una unidad sólo puede estar "bajando" (`Ramping`) si hay un stop blando en curso o el pulso está terminando.
- **I3**: si el nivel de respuesta en vigor es JTT (hay un salto a terminación en curso), la fase "de forma de onda" es Termination.
- **I4**: si el DMS no está en reposo, el nivel de respuesta tiene que ser PTN (no se puede armar el DMS sin que ya esté sonando la alarma más grave).

**Origen: MEZCLA.** I1 viene de que JET publica un sistema que da "ventanas de habilitación" al calentamiento (hecho, R-12); que se resuma en un solo booleano es nuestra simplificación (A-5, A-8). I4 viene de que JET publica que el DMS se dispara *después* de los stops (hecho, R-11); la forma exacta de "invariante" es nuestra.

```bend
law pres_i5:  ...  {S.i5_ack(...) == True{} : Bool}
```

Mismo tipo de ley, para **I5**: mientras el DMS está armado, el contador de espera nunca llega al límite (siempre queda margen). **Origen: MEZCLA** (el mecanismo de espera con límite de tiempo es hecho, R-11; que se exprese como "contador de ticks con un tope" es supuesto, A-11).

```bend
law pres_i6:  ...  {S.i6_hb(...) == True{} : Bool}
```

Para **I6**: mientras el PTN no está activado, el contador de "hace cuánto no llega una señal de vida" nunca llega al límite. **Origen: MEZCLA** (el vigía de latido de corazón es hecho, R-13; el contador es supuesto, A-12).

```bend
law traces_safe:
  for +o: S.Ord
  for +trace: List<&2, S.Ev>
  {S.inv_all(S.run_o(o, trace, S.init())) == True{} : Bool}
```

El teorema que junta todo: **para cualquier secuencia de eventos, de cualquier largo, corrida desde el arranque, el estado final siempre cumple el invariante completo.** No es una ley de "un paso"; es sobre **pulsos enteros**, de cualquier duración. Se demuestra por inducción (como los números pares de §3): vale al principio (`inv_init`) y cada paso lo preserva (`pres_fin`, `pres_i5`, `pres_i6`), así que vale siempre. **Origen: PLOMERÍA** (es la manera de sumar los invariantes anteriores en un solo teorema sobre trazas completas).

```bend
law traces_safe_concrete:
  for +i: S.Inst
  for +trace: List<&2, S.CEv>
  {S.inv_all(S.run_c(i, trace, S.init())) == True{} : Bool}
```

Lo mismo, pero con los eventos "reales" de la planta (no la versión abstracta) y pasando por una de las cuatro instancias de configuración. **Origen: PLOMERÍA.**

### 6.3 Las leyes "no pasa nada malo" (P1-P21, 18 leyes)

Esta familia dice, para cada situación, **qué NO puede pasar**. Cada ley sigue el molde de §5: para todo estado `f`, todo evento `e`, y los verdictos de los contadores, si algo pasa, entonces algo más tiene que ser cierto.

**P1 — `latched` ("el nivel nunca baja solo").**
```bend
S.implies(Bool.not(is_reset(e)), lvl_le(o, S.level_of(f), S.level_of(f2)))
```
Si el evento no fue un reinicio, el nivel de respuesta después del paso es **igual o más grave** que antes. Nunca se "relaja" solo. **Origen: SUPUESTO** (A-1, A-2): JET publica que el sistema *puede* escalar (subir de gravedad), pero también dice explícitamente que a veces conviene **no** escalar (dejar que un stop en curso termine sin interrumpirlo con uno nuevo). La política "siempre subo al máximo pedido, nunca bajo" es una decisión nuestra, más estricta que la de JET. Ojo, que esta ley mezcla varias cosas. Que el PTN quede trabado es **HECHO JET**, y desde la revisión 4 tiene ley propia (`p1a_ptn_latched`, §6.8). Que un stop nunca vuelva a "ninguno" también tiene ley propia (`p1b_stop_never_cleared`, §6.8), que es **MEZCLA**: para el PTN es hecho de JET, para los stops suaves es lectura nuestra. Lo que es **POLÍTICA NUESTRA** es qué pasa entre los dos stops suaves (JTT y RTPS) cuando llega uno sobre otro.

**P2 — `ptn_deenergizes` ("el botón de pánico apaga todo").** Ya la vimos completa en §5. **Origen: MEZCLA** (R-0: "la salida del PTN es una señal de parada trabada"; R-11: "estos disparos primero apagan los sistemas de calentamiento"; A-9). JET documenta el apagado del calentamiento para las salidas del PTN que disparan la válvula de emergencia (R-11); para las demás salidas sólo dice que cada sistema de control ejecuta una "secuencia de apagado fija" (R-0). Que **todo** camino al PTN deje las dos unidades apagadas es nuestro (A-9), y es la misma parte que hace MEZCLA a `d1a_ptn_honoured` (§6.8). Que pase "en el mismo paso" es la simplificación de un modelo que no tiene reloj (A-15), común a todas las leyes: en la planta los haces neutros tardan 2 ms en apagarse y la radiofrecuencia unos 38 ms.

**P3 — `stop_reduces_power` ("empezar un stop corta la potencia").**
```bend
S.implies(Bool.and(S.is_none(S.level_of(f)), S.is_soft(S.level_of(f2))),
          Bool.and(Bool.not(S.is_hot(S.nb_of(f2))), Bool.not(S.is_hot(S.rf_of(f2)))))
```
Si se pasa de "sin stop" a un stop de gravedad media (RTPS o JTT), ninguna de las dos unidades de calentamiento sigue entregando potencia (ni plena ni parcial) en ese mismo paso. **Origen: MEZCLA** (R-3, R-4 + A-9). Que un stop suave baje la potencia del calentamiento es hecho (R-3, R-4: los "overrides" bajan la referencia de potencia). Que **todo** stop suave saque de potencia a las **dos** unidades, también a la que está a potencia parcial, es nuestro (A-9): JET describe los stops RTPS como "fully programmable" (totalmente programables; traducción nuestra) y no dice que cada uno baje las dos unidades. Es la misma parte que hace MEZCLA a `stop_no_full_power` (§6.6).

**P4 — `ramping_never_returns` ("lo que empezó a bajar, no vuelve a subir").** Una unidad que está `Ramping` (bajando su potencia) nunca vuelve a entregar potencia mientras no haya un reinicio. **Origen: SUPUESTO** (A-9): es una política conservadora nuestra, JET no lo dice explícitamente así. *(Derivada: sale de P5 y P7 juntas; ver §10.)*

**P5 — `heat_permissive` ("el permiso de calentar es todo o nada, y exacto").** Un comando de "prender esta unidad" la prende **si y sólo si** se cumplen las tres condiciones (ventana abierta, plasma OK, sin stop); si no se cumplen, el comando no hace nada. **Origen: MEZCLA**: el mecanismo del permiso es hecho (R-12, el sistema PEWS, que da "ventanas de habilitación"); la forma exacta es nuestra: la ventana fija (A-5), el plasma resumido en un solo Sí/No (A-8) y la condición "sin stop" (A-9). Un límite a tener en cuenta: la "ventana" en la que se permite calentar es fija en el modelo, igual para las dos unidades y para todas las instancias (A-27), mientras que en JET se programa en cada pulso; esta ley no dice nada sobre ventanas distintas.

**P6 — `stop_overrides_heat` ("con un stop activo, nada se prende").** Mientras haya cualquier stop en vigor, ninguna unidad puede pasar de "sin potencia" a "con potencia". **Origen: SUPUESTO** (A-9). *(Derivada: sale de P5 y P7 juntas; ver §10.)*

**P7 — `heat_frame` ("una unidad no se prende sola").** Si una unidad pasa de "sin potencia" a "con potencia", el evento tuvo que ser exactamente el comando de prender esa unidad —no puede ser un efecto colateral de otra cosa. **Origen: SUPUESTO** (A-19): asumimos que "comando = efecto", sin modelar el actuador físico real.

**P9 — `local_is_local` ("una alarma local sólo toca su propia unidad").** Cuando llega una alarma "local" (un punto caliente específico), la unidad afectada pasa de potencia plena a potencia **parcial** (nunca se apaga del todo), y los otros siete casilleros del estado quedan exactamente igual. **Origen: MEZCLA.** JET publica (R-9) que "el PINI correspondiente debería apagarse [...] Esto no debería impedir que el sistema de haces neutros en su conjunto siga entregando al plasma la potencia total pedida, ya que se pueden encender otros PINIs para compensar" — es decir, JET habla de apagar **una parte** de la unidad y compensar con otras partes; nuestro modelo simplifica eso a "la unidad entera baja a potencia parcial", sin modelar la compensación (A-6, A-7). Además hay un solo escalón de reducción: una segunda alarma local sobre la misma unidad no hace nada, cuando en JET sacaría otro PINI (A-33).

**P10 — `no_spurious_stop` ("el nivel sólo cambia por una de cuatro causas").** Si el nivel de respuesta cambió, el evento tuvo que ser: un pedido de stop, un fallo de comunicación, un reinicio, o un tick de reloj con el vigía de latido expirado. Ninguna otra causa puede mover el nivel. **Origen: SUPUESTO** (A-12, A-13): es nuestro cierre de la lista de causas.

**P12 — `commfault_ptn` ("un fallo de comunicación habilitado va directo al PTN").** Si llega un evento de fallo de comunicación y el chequeo correspondiente está habilitado, el nivel queda en PTN, sin importar en qué estado estaba antes. **Origen: HECHO JET** (R-13: "si RTPS detecta fallos de comunicación o de estado... puede disparar el sistema PTN").

**P14 — `phase_monotone` ("las fases nunca retroceden").** Sin un reinicio, ni la fase del programa ni la fase "de forma de onda" (ver P19/F1 más abajo) retroceden nunca. **Origen: SUPUESTO** (A-5): JET dice que las fases están "temporizadas" (hecho, R-1); que estén en un orden total e irreversible es lectura nuestra.

**P15 — `dms_monotone` ("el DMS sólo avanza").** Sin reinicio, el DMS sólo puede ir Idle → Armed → Fired, nunca al revés. **Origen: MEZCLA** ([S6] + A-11): que una vez disparado siga disparado hasta el fin del pulso tiene respaldo en el paper de la válvula ([S6]: la válvula "has to be refilled by an operator in the control room after every injection", o sea, un operador tiene que recargarla desde la sala de control después de cada inyección; traducción nuestra); que el DMS armado nunca se desarme es nuestro (A-11).

**P16 — `dms_armed_on_demand` ("una demanda válida arma el DMS").** Si el DMS estaba en reposo, el veredicto de habilitación de la válvula es "sí" (corriente o energía almacenada por encima del umbral; A-22), y llega un evento que "demanda" el DMS (un stop grave cableado a él, o un fallo de comunicación cableado a él, o el vigía de latido expirado y cableado a él), el DMS queda armado. **Origen: MEZCLA.** Que ciertos stops disparen la válvula de emergencia es hecho (R-11, y el paper sobre la válvula [S6]); *cuáles* stops exactamente están cableados es una decisión nuestra, igual para todas las instancias (supuesto, A-10).

**P17 — `dms_frame` ("nada más arma el DMS").** La recíproca de P16: si el DMS salió de reposo, fue por una de esas demandas válidas y ninguna otra causa. **Origen: MEZCLA** (R-14 + A-10, A-11): que sin el veredicto de habilitación el DMS no se arme es hecho, como en IP1 (R-14); que sólo esas demandas lo armen, y ninguna otra causa, es un marco nuestro (A-10, A-11).

**P18 — `tack_frame` ("una alarma repetida no reinicia la espera").** Con el DMS ya armado, cualquier evento que no sea un tick de reloj ni un reinicio deja el contador de espera exactamente igual (no lo reinicia ni lo adelanta). **Origen: SUPUESTO** (A-11): sonar la alarma de nuevo no debería "resetear el cronómetro" de la espera.

**P19 — `advance_frozen` ("bajo PTN, el programa está congelado").** Un comando de "avanzar de fase" mientras el PTN está activo no hace absolutamente nada: ni mueve el control ni toca los contadores. **Origen: MEZCLA**: que bajo PTN el programa deje de mandar es hecho (R-0: ante la señal del PTN, cada sistema de control ejecuta "una secuencia de apagado fija"); que además los dos contadores queden exactamente igual es formalización nuestra (A-11, A-12), como en `piw_after_ptn_is_noop` (§6.8).

**P20 — `reset_guarded` ("el fin de pulso es todo o nada, según una guarda").** Un reinicio, si se cumple la condición de seguridad (el pulso terminó y el DMS no está armado), vuelve todo al estado inicial; si no se cumple, no cambia absolutamente nada. **Origen: SUPUESTO** (A-14): JET no publica un camino documentado para "limpiar" el PTN a mitad de pulso, así que asumimos que el reinicio sólo se acepta cuando el pulso ya terminó de verdad.

**P21 — `reset_refused_mid_pulse` ("no se puede reiniciar con el DMS armado o el pulso en curso").** Versión explícita de la mitad "no" de P20: si el DMS está armado, o si ni el PTN está activo ni la fase de terminación empezó, un pedido de reinicio no cambia nada. **Origen: SUPUESTO** (A-14).

### 6.4 Las leyes "hace su trabajo, y nada más se mueve" (D1-D18, E2-E11, 26 leyes)

Las leyes P de arriba sólo dicen "no pasa nada malo" — son todas negativas. Pero eso, por sí solo, no demuestra que el sistema **funcione**: un sistema que nunca hiciera nada también cumpliría "no pasa nada malo". Por eso se agregó esta segunda familia, con dos partes en cada ley:

- la parte **"demanda"**: cuando se dan ciertas condiciones, el sistema **sí** tiene que actuar (no sólo "puede");
- la parte **"marco"** (*frame*, del inglés): cuando **no** se dan esas condiciones, **nada más** se mueve (ni un casillero de más cambia).

Estas leyes se agregaron después de dos rondas de revisión adversarial (revisores automatizados con el encargo de "engañar" al modelo con errores sutiles a propósito, README §7; estas leyes son las que hacía falta agregar para atraparlos). De los 76 errores plantados a propósito que tiene hoy el banco, se atrapan 75. Los errores se plantan en el modelo de referencia en Python, no en el de Bend, y los juzgan estas leyes reescritas como predicados de Python, que leen las constantes de la especificación y no las del modelo (`v3/pymodel/`), más un control de que el invariante del modelo es el de la especificación (el error M72 lo atrapa sólo ese control). Así que este puntaje mide las copias en Python de las leyes: una ley de Bend más débil que su copia no se notaría acá. Del que queda, el gate calcula que se comporta exactamente igual que el modelo en todos los casos que compara, así que ninguna ley podría distinguirlo.

**D1 — `d1_stop_honoured` ("el nivel es exactamente el máximo pedido").** Ante un pedido de stop, el nivel siguiente es **exactamente** el más grave entre el que estaba en vigor y el pedido (no sólo "igual o peor", como P1 — acá es "exactamente ese"). **Origen: MEZCLA** (R-7 dice que "subsequent alarms could generate a more urgent stop", traducción nuestra: alarmas posteriores podían generar un stop más urgente; que la regla sea "tomar el máximo" es nuestra, A-2). Separando las partes: que sin stop en curso el primer pedido se atienda es **HECHO JET**, con ley propia desde la revisión 4 (`d1b_primary_honoured`, §6.8). Que un pedido de PTN se atienda siempre también es hecho de JET, pero su ley, `d1a_ptn_honoured` (§6.8), exige además las dos unidades de calentamiento apagadas, y eso es nuestro (A-9, como en P2): por eso es **MEZCLA**. Que un stop suave sobre otro stop suave se resuelva "tomando el máximo" es **POLÍTICA NUESTRA** (A-2, A-16), y corta para los dos lados: pide al menos la autoridad solicitada, pero escalar un aterrizaje suave a un PTN puede provocar justo la disrupción que se quería evitar, y un segundo pedido igual o menor se ignora.

**D2 — `d2_soft_stop_ramps` ("un stop aceptado hace bajar la potencia").** Si el pedido es un stop blando (RTPS o JTT), es más grave que lo que había, y alguna unidad tenía potencia, entonces esa unidad empieza a bajar. **Origen: MEZCLA** (R-4 + A-9). Que el stop suave haga **bajar** la potencia en vez de cortarla es hecho (R-4: "ramp down the plasma current and heating power to give a softer landing", traducción nuestra: bajar la corriente del plasma y la potencia de calentamiento para un aterrizaje más suave). Que todo stop suave aceptado lo haga con las dos unidades, también con la que está a potencia parcial, es nuestro (A-9), como en P3.

**D3 — `d3_advance_to_termination_ramps` ("el fin natural del programa también hace bajar la potencia").** Cuando el programa llega naturalmente al final (sin ningún stop) y avanza a la fase de terminación, también se inicia el descenso de potencia. **Origen: SUPUESTO** (A-9). *(Nota: esta ley es "derivada" — la cubre por completo una ley más general, E4; se conserva documentada por prolijidad, pero no cuenta como evidencia adicional independiente.)*

**D4 — `d4_watchdog_latches` ("el vigía de latido dispara el PTN").** Un tick de reloj, con el vigía expirado y el PTN todavía no activo, hace que el nivel pase a PTN. **Origen: HECHO JET** (R-13: "una señal de vigía por hardware al PTN asegura que el RTPS está operativo").

**D5 — `d5_hb_counts` ("el contador del vigía suma cuando corresponde").** Un tick con margen y sin PTN suma uno al contador de "hace cuánto no llega una señal de vida". **Origen: SUPUESTO** (A-12). *(Derivada: es la mitad de E6.)*

**D6 — `d6_hb_frame` ("sólo un latido de corazón reinicia el vigía").** Si el contador del vigía se reinicia, el evento tuvo que ser una señal de latido, o un reinicio de pulso aceptado. **Origen: SUPUESTO** (A-12).

**D7 — `d7_ack_timeout_fires` ("si se acaba el tiempo, dispara igual").** Con el DMS armado, el PTN activo, y un tick con la espera agotada, el DMS dispara. **Origen: HECHO JET** (R-11: los disparos quedan "conditioned with an acknowledgement from the heating plant (and timeout)", traducción nuestra: condicionados a una confirmación de la planta de calentamiento (y a un tiempo límite); el paper de la válvula [S6] aclara que el sistema de RF no confirma nunca, así que el tiempo límite es, en la práctica, el camino real por el que dispara).

**D8 — `d8_ack_counts` ("el contador de espera del DMS suma cuando corresponde").** Con el DMS armado, PTN activo, y un tick con margen, el contador de espera suma uno. **Origen: SUPUESTO** (A-11).

**D9 — `d9_heatack_fires` ("la confirmación de la planta dispara el DMS").** Con el DMS armado, si llega la confirmación de que los calentadores ya se apagaron, el DMS dispara. **Origen: HECHO JET** (R-11). *(Derivada: es la mitad de E11.)*

**D10 — `d10_reset_accepted_when_safe` ("el reinicio SÍ se acepta cuando es seguro").** La otra mitad de P20, escrita con la condición de seguridad explícita (no citando la función interna del modelo, para que un error en esa condición sea detectable por separado). **Origen: SUPUESTO** (A-14). *(Derivada de P20, se mantiene para evitar que P20 "se demuestre a sí mismo" citando su propia definición interna.)*

**D11 — `d11_advance_is_one_step` ("el programa avanza de a una fase").** Un comando de avanzar, sin PTN y sin estar ya en la última fase, mueve la fase del programa a **exactamente** la siguiente (no salta fases). **Origen: SUPUESTO** (A-5).

**D12 — `d12_phase_frame` ("sólo avanzar o reiniciar mueven la fase del programa").** **Origen: SUPUESTO** (A-5, A-24). *(No es derivada; al revés: F1b, más abajo, es su caso Stop.)*

**D13 — `d13_plasma_is_input` / D14 — `d14_plasma_frame` ("el estado del plasma es una entrada externa").** El estado "plasma OK" se actualiza exactamente con lo que llega del evento correspondiente, y sólo con eso (o con un reinicio aceptado). **Origen: SUPUESTO** (A-8): resumir corriente y densidad en un solo booleano es una simplificación nuestra.

**D15 — `d15_heatoff_is_local` / D16 — `d16_heaton_is_local` ("prender o apagar una unidad sólo la toca a ella").** Un comando de prender o apagar la unidad NB, por ejemplo, no cambia absolutamente nada del estado de la unidad RF ni de ningún otro casillero (salvo el efecto directo sobre esa unidad, que describe P5). **Origen: SUPUESTO** (A-19).

**D17 — `d17_heatack_frame` ("una confirmación sólo toca al DMS").** Ante la señal de confirmación de la planta, sólo cambia el estado del DMS; los otros siete casilleros y ambos contadores quedan iguales. **Origen: SUPUESTO** (A-11).

**D18 — `d18_heartbeat_frame` ("un latido de corazón sólo toca su propio contador").** Ante la señal de latido, el control no cambia nada y sólo se toca el contador del vigía (no el del DMS). **Origen: SUPUESTO** (A-12).

**E2 — `e2_dms_fire_frame` ("el DMS sólo dispara por dos caminos").** Si el DMS pasó de armado a disparado, tuvo que ser por la confirmación de la planta o por agotarse el tiempo de espera — no hay un tercer camino. **Origen: HECHO JET** (R-11: los dos caminos son exactamente los de "acknowledgement from the heating plant (and timeout)", traducción nuestra: la confirmación de la planta de calentamiento y el tiempo límite). Aunque se llame "frame", el "no hay un tercer camino" también es de JET: la misma frase dice que la activación del DMS queda "conditioned with" (condicionada a) esos dos caminos.

**E3 — `e3_stop_phase_exact` ("el salto a terminación mueve la forma de onda exactamente cuando toca").** Ante un pedido de stop, la fase "de forma de onda" pasa a Termination **si y sólo si** se aceptó un salto directo (JTT) más urgente que lo que había; si no, queda igual. **Origen: MEZCLA** (R-4: ante un JTT, el RTPS les avisa a los controladores que avancen "in their waveforms to the termination region", traducción nuestra: en sus formas de onda, hasta la región de terminación; hecho; que sólo mueva la "forma de onda" y no la fase del programa Level-1 es nuestra lectura, A-24 — ver más abajo, familia F1; y "se acepta si es más urgente que lo que había" es nuestra política, A-2).

**E4 — `e4_advance_units` ("un avance de fase determina exactamente qué pasa con cada unidad").** Cubre los seis casos posibles de avance de fase (no sólo el que va a Termination, como hacía D3): según a qué fase se avanza, cada unidad queda exactamente en el estado que corresponde (bajando, apagada si se cierra la ventana, o igual). **Origen: SUPUESTO** (A-5, A-9).

**E5 — `e5_heartbeat_resets_hb` ("un latido de corazón SIEMPRE reinicia el vigía").** La mitad "sí" de D6, sin condiciones. **Origen: SUPUESTO** (A-12).

**E6 — `e6_hb_tick_exact` ("el comando al contador del vigía en un tick es exactamente uno de tres").** En un tick, si hay margen y no hay PTN: sumar. Si hay PTN: no tocar. Si no hay margen: no tocar (porque en ese mismo paso el PTN se dispara, por D4, y deja de tener sentido seguir contando). No hay un cuarto caso posible. **Origen: SUPUESTO** (A-12).

**E7 — `e7_tack_inc_frame` / E8 — `e8_tack_reset_frame` ("el contador de espera del DMS sólo se toca en dos situaciones exactas").** E7: sólo suma en un tick con el DMS armado y margen. E8: sólo se reinicia por un fin de pulso aceptado o por una demanda que realmente arma el DMS. **Origen: SUPUESTO** (A-11, A-14).

**E11 — `e11_heatack_exact` ("la confirmación es de doble vía").** Ante la confirmación de la planta, si el DMS estaba armado pasa a disparado; si estaba en cualquier otro estado, no cambia. Es la versión completa (ambos lados) de D9. **Origen: MEZCLA** (el disparo por confirmación es hecho, R-11; que un `HeatAck` que llega sin el DMS armado no haga nada es supuesto, A-11).

### 6.5 Las leyes de fidelidad a los papers (F1, F2, F3, F4, IP — 13 leyes)

Estas leyes se agregaron en una revisión posterior (llamada "bloqueante 4" en la bitácora del proyecto) para atar cabos sueltos muy específicos que los papers de JET mencionan pero que el modelo inicial no distinguía con suficiente precisión: dos "relojes de fase" distintos, la potencia parcial, las máscaras de los chequeos de fiabilidad, y el veredicto de habilitación del DMV para la válvula de emergencia (corriente o energía almacenada por encima del umbral, A-22).

**Las dos vistas del tiempo (F1a-F1e).** Un paper de JET ([S2], sobre el sistema de control CODAS) dice que durante un salto a terminación "there were two views of time" (traducción nuestra: había dos vistas del tiempo): el tiempo de las formas de onda, que manejan los actuadores, y el tiempo del pulso de plasma tal como se ejecutó. El modelo conserva las dos: la fase del **programa**, que (lectura nuestra, A-24) indexa la tabla de configuración y sólo avanza por comandos explícitos de "avanzar" o por un reinicio, y la fase de la **forma de onda**, que leen el permiso de calentamiento y la ventana de la válvula de emergencia y que un salto directo a terminación lleva a Termination. Antes de esta revisión el modelo tenía una sola fase, así que después de un salto a terminación una alarma posterior leía la fila de Termination; qué fila lee el RTPS de JET en ese caso no está publicado (A-24, A-30).

- **F1a `f1a_table_reads_prog`**: una alarma concreta siempre lee la tabla usando la fase del **programa**, nunca la de forma de onda, en cualquier instancia y cualquier estado. Está escrita contra una transcripción aparte de la tabla (las constantes propias del enumerador en `enum_jetprot.bend`, no la tabla del modelo), así que si el modelo leyera la fase equivocada o la celda equivocada, esta ley lo detectaría. Desde la revisión 4, si ya hay un stop en curso, la alarma lee la **tabla secundaria** de la instancia en vez de la primaria (en las instancias 1 a 3 son la misma cosa, así que para ellas la ley no cambió). **Origen: MEZCLA** (que la tabla se indexe por fase es hecho, R-5; cuál de las dos fases exactamente, es nuestra lectura, A-24). Qué fase lee una alarma que llega **durante** un stop no está documentado (A-24, A-30): un paper de JET dice que el controlador de forma se queda con la configuración de stop de la ventana de tiempo en la que se disparó el stop primario ([N1] p.13 del PDF), o sea, la congela, y el modelo no la congela.
- **F1b `f1b_stop_keeps_prog`**: un pedido de stop nunca mueve la fase del programa (sólo la de forma de onda). **Origen: SUPUESTO** (A-24). *(Derivada: es el caso Stop de D12; se conserva como el enunciado nombrado de A-24.)*
- **F1c `f1c_wave_ahead`**: la fase de forma de onda nunca va "por detrás" de la fase del programa (siempre igual o más adelantada). Vale por construcción, no depende de ningún evento en particular. **Origen: SUPUESTO** (A-24).
- **F1d `f1d_wave_frame`**: la fase de forma de onda sólo se mueve por un avance de programa, un reinicio, o un salto directo aceptado. **Origen: SUPUESTO** (A-24).
- **F1e `f1e_jtt_exact`**: la bandera "se aceptó un salto directo" queda exactamente determinada: se prende cuando se acepta el salto, se apaga en el fin de pulso, y si no, queda igual. Se encontró gracias a una métrica de "qué tan ajustado está el modelo" que descubrió dos estados que sólo diferían en esta bandera y se comportaban exactamente igual — es decir, nada la fijaba todavía. **Origen: SUPUESTO** (A-24; "se acepta si es más urgente" es nuestra política, A-2).

**F4 `f4_units_frame` ("nada mueve las unidades de calentamiento salvo una lista corta de eventos").** Si el nivel de respuesta no cambió y el evento no es ninguno de los que pueden tocar una unidad (un comando directo, un avance de fase, un reinicio, una pérdida de plasma, un stop grave, o un fallo de comunicación habilitado), entonces ninguna unidad cambia. La misma métrica de ajuste encontró que, sin esta ley, nada impedía que las unidades cambiaran "gratis" ante un cambio de corriente o de plasma que no debería afectarlas. **Origen: SUPUESTO** (A-19).

**F2a `f2a_local_reduces` / F2d `f2d_reduced_never_returns` ("la potencia parcial es de un solo sentido").** F2a: una alarma local saca un PINI (una antena en RF) de una unidad a potencia plena: la unidad pasa a `Reduced`, nunca a apagada. **Origen: HECHO JET** (R-9, la cita ya vista en P9). Que `Reduced` signifique potencia **parcial**, sin compensación con otros PINIs, es nuestro (A-6), como en P9. *(Derivada: es la mitad de reducción de P9; se conserva como el enunciado nombrado de R-9.)* F2d: una unidad en potencia parcial no salta directamente a potencia plena. Es una regla de un solo paso: si la unidad se apaga (por una orden de apagado o porque se pierden las condiciones del plasma) y después se vuelve a prender, arranca otra vez a potencia plena y el PINI que se había sacado vuelve a entrar (A-34). **Origen: SUPUESTO** (A-6, A-7: sin esta ley, un evento de "plasma OK" podría restaurar la potencia plena sin que ninguna otra ley lo prohibiera; JET sí permite compensar con otras partes de la unidad, pero eso no está modelado, así que esta política es más estricta que la real — conservadora).

**F3b `f3b_commfault_masked_is_noop` ("un chequeo apagado no hace nada").** Si el chequeo de fallo de comunicación está desactivado en la configuración de esa instancia, el evento correspondiente no cambia absolutamente nada (ni el control ni los contadores). **Origen: MEZCLA** ([S1] + A-21): el paper principal, [S1], publica que estos chequeos se condicionan "so that features or subsystems which are not in use cannot cause problems" (para que las funciones o los subsistemas que no se usan no puedan causar problemas; traducción nuestra), y JET publica que las entradas al PTN "pueden habilitarse o deshabilitarse" (hecho, R-10); que no se mueva absolutamente nada, contadores incluidos, es un marco nuestro, y el detalle de "máscara por instancia, sólo para estos dos chequeos" también es nuestro (A-21).

**IP1 `ip1_low_never_arms` ("sin el veredicto de habilitación, no hay armado").** Sin el veredicto de habilitación de la válvula (ni la corriente ni, desde la revisión 4 del registro, la energía almacenada superan su umbral; A-22) y con el DMS en reposo, ningún evento lo arma. **Origen: HECHO JET** (paper de la válvula [S6]: "The DMV was used systematically for scenarios above 2.5 MA", traducción nuestra: la válvula DMV se usó sistemáticamente en los escenarios de más de 2,5 MA; y el mismo paper reporta **7 disrupciones** detectadas "at a plasma current lower than the minimum current needed for the DMV to be fired" (traducción nuestra: con una corriente de plasma menor que la mínima necesaria para disparar la válvula): la válvula no podía dispararse, porque el primer colapso térmico (thermal quench: la pérdida brusca del calor del plasma con la que empieza una disrupción) había ocurrido con más corriente y ninguna de las señales de detección lo vio).

**IP2 `ip2_arms_on_demand` ("con el veredicto de habilitación, la demanda SÍ arma").** La versión concreta de P16: con el veredicto de habilitación en "sí", DMS en reposo, y una alarma que la tabla de esa instancia manda a PTN y que está cableada al DMS dentro de la ventana habilitada, el DMS se arma en ese mismo paso. **Origen: HECHO JET** (R-11, R-14, y el paper [S6]).

**IP3 `ip3_ip_is_input` / IP4 `ip4_ip_frame` ("el veredicto de habilitación es una entrada externa").** El veredicto de habilitación del DMV (corriente o energía almacenada por encima del umbral, A-22) se actualiza exactamente con el evento correspondiente, y sólo con eso o un reinicio aceptado. **Origen: SUPUESTO** (A-22: en una revisión anterior este umbral estaba directamente fuera del modelo; se agregó después, y desde la revisión 4 se lee como "corriente **o** energía almacenada por encima del umbral", que es la forma de la condición en el ejemplo de la figura 2 de [S7] y del límite de [K15] para operar sin la válvula; las leyes no cambian porque hablan de un sí o no).

### 6.6 Los corolarios (4 leyes) — MEZCLA/SUPUESTO

Son consecuencias que se leen directamente del invariante, sin necesidad de mirar un paso: valen en **cualquier** estado alcanzable, porque `traces_safe` (§6.2) garantiza que todo estado alcanzable cumple el invariante.

- **`ptn_no_heat`**: bajo PTN, las dos unidades están apagadas. **MEZCLA** (R-0, R-11 + A-9): que todo camino al PTN apague el calentamiento es nuestro, como en P2 (JET lo documenta para las salidas del PTN que disparan la válvula de emergencia), y que después nada vuelva a prenderse también es supuesto (A-9).
- **`dms_no_heat`**: con el DMS armado o disparado, las dos unidades están apagadas. **MEZCLA** (R-11, [S6] + A-9): que el calentamiento esté apagado cuando se activa la válvula es hecho (paper de la válvula [S6]: "Heating systems cannot be operating when the DMV is activated", traducción nuestra: los sistemas de calentamiento no pueden estar funcionando cuando se activa la válvula DMV); que siga apagado después de la inyección, hasta el fin del pulso, es supuesto (A-9), como en `ptn_no_heat`.
- **`stop_no_full_power`**: con cualquier stop en vigor, ninguna unidad entrega potencia (ni plena ni parcial). **MEZCLA** (el efecto del stop es hecho; que también valga para potencia parcial es supuesto, A-9).
- **`termination_no_full_power`**: en la fase de forma de onda "Termination", ninguna unidad entrega potencia. **SUPUESTO** (A-9).

### 6.7 Plomería fina (5 leyes) — PLOMERÍA / SUPUESTO

Un grupo chico de leyes técnicas que no aportan contenido nuevo sobre JET, sino que afinan la maquinaria de la prueba:

- **`verdict_frame_step`, `verdict_frame_hb`, `verdict_frame_tack`**: demuestran que, salvo en los eventos de tipo "tick de reloj", el resultado del paso **no depende en absoluto** de los verdictos de los contadores. Esto justifica que el certificado (§6.1) no necesite probar las cuatro combinaciones de verdictos en cada una de las 28 columnas de evento, sino sólo en 5: los dos ticks de reloj y tres eventos donde el verificador no puede descartar los verdictos simbólicamente, aunque, por estas mismas leyes, el paso no los lee — ahorrando trabajo de cómputo sin perder rigor. **PLOMERÍA.**
- **`reset_accepted`, `reset_refused`**: la versión de P20 pero sobre el estado **completo** (incluyendo los dos contadores, no sólo el control): con la condición de seguridad, un reinicio da exactamente el estado inicial completo; sin ella, es la identidad exacta. **SUPUESTO** (A-14).

### 6.8 Lo que P1 y D1 dicen sobre el PTN y el primer stop, con nombre propio (5 leyes), y la segunda alarma en la instancia 4 (1 ley) — revisión 4

Las leyes P1 y D1 mezclaban dos cosas: lo que JET documenta sobre el PTN (el "botón de pánico") y lo que decidimos nosotros para cuando un stop suave llega sobre otro stop suave. Estas cinco leyes separan la parte sobre el PTN y el primer stop, para poder citarla sin arrastrar nuestra política entre stops suaves. Dos son **HECHO JET**; las otras tres son **MEZCLA**, porque cada una agrega algo nuestro, que se dice en su entrada. La fuente principal es [N1], un paper de 2013 sobre los stops de JET; las páginas son las del PDF. En [N1], "PIW" es el proyecto de protección de la pared tipo ITER (*Protection of the ITER-like Wall*, p.12 del PDF), y los "stops PIW" son las respuestas de parada nuevas del controlador de forma que introdujo ese proyecto, disparadas por el RTPS (el JTT es una de ellas, figura 6); nosotros los identificamos con los stops suaves del modelo (JTT y RTPS).

- **`p1a_ptn_latched` ("el PTN queda trabado").** Si el PTN está activo y el evento no es un reinicio, el PTN sigue activo. **Origen: HECHO JET** (la salida del PTN es una señal trabada, R-0: "The PTN output is a latched stop signal"; y [N1] p.14: "a PIW stop can never preempt a PTN stop", o sea, un stop suave nunca desplaza a un PTN; traducción nuestra). *(Derivada: es un caso de P1.)*
- **`p1b_stop_never_cleared` ("un stop no se borra solo").** Si hay un stop en curso (suave o PTN) y el evento no es un reinicio, sigue habiendo un stop. **Origen: MEZCLA**: para el PTN es hecho de JET (la salida trabada del PTN, R-0); para los stops suaves es lectura nuestra: ningún paper publica una forma de cancelar un stop (A-14, un argumento por ausencia), y el paper principal, [S1], presenta los stops como la manera de terminar el pulso (R-8). (El "allowing it to run to completion" de R-6, dejarlo terminar, habla de no pasar a un stop secundario.) No es una frase de [N1]. *(Derivada: es otro caso de P1.)*
- **`d1a_ptn_honoured` ("un pedido de PTN se atiende siempre").** Un pedido de PTN deja el nivel en PTN y las dos unidades de calentamiento apagadas, desde cualquier estado, aunque haya un stop suave en curso. **Origen: MEZCLA**: que un pedido de PTN se atienda aunque haya un stop suave andando es **HECHO JET** ([N1] p.13: los PTN "can be triggered even after a PIW stop is in execution", o sea, se pueden disparar aunque ya haya un stop suave andando; traducción nuestra); que las dos unidades queden apagadas es nuestro (A-9, como en P2): JET documenta el apagado del calentamiento para las salidas del PTN que disparan la válvula de emergencia (R-11), para las demás sólo como una "secuencia de apagado fija" (R-0). *(Derivada: sale de D1, P2 y P6, en los estados que cumplen el invariante.)*
- **`d1b_primary_honoured` ("el primer stop se atiende").** Sin stop en curso, un pedido suave (JTT o RTPS) pasa a ser la respuesta en vigor, con cualquiera de los dos órdenes. **Origen: HECHO JET** (la tabla primaria, R-5; [N1] p.13: "RTPS will select the stop and send it to SC", o sea, el RTPS elige el stop y se lo manda al controlador de forma). *(Derivada: es un caso de D1.)*
- **`piw_after_ptn_is_noop` ("un pedido suave después del PTN no hace nada").** Con el PTN activo, un pedido que no es PTN no cambia absolutamente nada, ni el estado ni los dos contadores. **Origen: MEZCLA**: [N1] p.13 llama "invalid task", tarea inválida, a pedir un stop PIW "after a PTN stop was already being executed" (cuando ya se está ejecutando un PTN), en las pruebas de aceptación del simulador del controlador de forma, que igual "still follows the correct path of action" (sigue el camino correcto; traducción nuestra); que ese pedido deje igual todo el estado y los dos contadores es formalización nuestra (A-14; los comandos a los contadores son los de A-11 y A-12), y es justo la parte que hace que la ley no sea derivada. **No es derivada**: ninguna ley anterior impedía que ese pedido moviera el contador del vigía de latido, y la medida de "qué tan ajustado está el modelo" lo mostró (los comandos a los contadores quedaron fijados en 243 de 400 casos de la muestra, contra 212 antes).
- **`inst4_second_alarm_ptn` ("en la instancia 4, una segunda alarma lleva al PTN").** En la instancia 4, si hay un stop suave en curso y llega una alarma que la tabla primaria no manda a "ninguna", el paso concreto dispara el PTN. Es justo el caso que en las instancias 1 a 3 se ignora: un punto caliente en el divertor durante un stop RTPS, con la fase en Heating 2. **Origen: MEZCLA**: el mecanismo de dos niveles de respuesta, primaria y secundaria, es **HECHO JET** ([S1], R-6); el contenido de la tabla secundaria es **inventado** por nosotros (A-35), porque la de JET no está publicada. Se inspira en el epígrafe de la figura 7 de [N1] (p.23 del PDF), "The preferred secondary plasma stop is the PTN slow stop" (traducción nuestra: el stop secundario preferido es el PTN lento), que es una estadística de uso, no una regla.

El tope de [N1], "a maximum of two in sequence" (p.13 del PDF; traducción nuestra: como máximo dos seguidas; que sean dos stops suaves es lectura nuestra), **no** tiene ley propia: con sólo dos niveles suaves y un orden estricto, se cumple solo, por cómo está armado el modelo. Presentarlo como una demostración de la regla de JET sería exagerar.

---

## 7. Las leyes de la tabla de configuración — 143 leyes

Este archivo (`LAWS_JETPROT_CONF.bend`) no habla de "qué pasa cuando algo cambia" (eso ya lo cubrió la sección 6); habla de **qué dice exactamente la tabla de configuración**, celda por celda.

### 7.1 Por qué existen tantas leyes casi idénticas

La tabla de configuración de JET es una tabla de consulta: fila = fase del experimento (7 posibles), columna = tipo de alarma (8 posibles) → celda = qué tan grave es la respuesta. Eso son 56 combinaciones por instancia (hay cuatro instancias, pero la cuarta copia la tabla de la primera), más el cableado de la válvula de emergencia, las máscaras y, desde la revisión 4, las tablas secundarias. Cada celda se transcribió **dos veces, por separado** (una vez en el modelo, otra vez en este archivo de leyes) y se demuestra, celda por celda, que las dos transcripciones coinciden. Es literalmente el mismo truco que usás cuando copiás un número de teléfono largo: lo escribís, y después lo volvés a leer en voz alta comparándolo con el original, para atrapar un error de tipeo.

Cada ley individual tiene esta forma:

```bend
law pub_Heating2_Dhs:
  {Spec.lvl_eq(S.table1(S.Heating2{}, S.Dhs{}), S.LJtt{}) == True{} : Bool}
```

Se lee: "en la tabla número 1, la celda (fase Heating2, alarma Dhs) es exactamente JTT". El nombre codifica la celda (`prefijo_Fase_Alarma`), así que no hace falta memorizar 143 nombres distintos: hace falta entender **4 prefijos**.

| Prefijo | Qué celda es | Origen |
|---|---|---|
| `pub_` | Una celda que la Tabla 1 de JET publica directamente (impresa, o marcada con una "comilla" `\|` de repetición del valor de arriba) | **HECHO JET** |
| `asm_` | Una celda de una columna que la Tabla 1 **no** publica (falta esa columna entera) | **SUPUESTO** |
| `inst2_` | Una celda donde la instancia 2 (nuestra variante) cambia el valor publicado | **SUPUESTO** |
| `inst2_same_` | Una celda donde la instancia 2 copia exactamente el valor de la instancia 1 | **SUPUESTO** (define nuestra variante) |

### 7.2 La tabla publicada por JET — 28 leyes `pub_*` — HECHO JET

Esta es la Tabla 1 tal como aparece en el paper original de JET [S1]. De las 28 celdas, **15 están impresas directamente** y **13 se leen de una marca de "ídem"** (el símbolo `|`, que en la tabla original significa "repetí el valor de la celda de arriba"). Esa lectura de las marcas se verificó forense y cuidadosamente (dos revisiones automatizadas separadas, ver README §7, confirmaron que cada `|` era realmente el símbolo de repetición y no una línea de la tabla, midiendo la posición del glifo en el PDF original), así que las 28 cuentan como hecho documentado.

| Fase | Alarma "Slow" (lenta) | Alarma "MHD" (inestabilidad) | Alarma "MCHS" (punto caliente, cámara) | Alarma "DHS" (punto caliente, divertor) |
|---|---|---|---|---|
| Breakdown (arranque) | PTN | Ninguna | Ninguna | PTN |
| Ip Rise (subida de corriente) | PTN | Ninguna | Ninguna | PTN |
| Limiter | PTN | Ninguna | Ninguna | PTN |
| X-point (formación) | PTN | Ninguna | Ninguna | PTN |
| Heating 1 (calentamiento) | RTPS | Ninguna | RTPS | PTN |
| Heating 2 (calentamiento) | RTPS | Ninguna | RTPS | **JTT** |
| Termination | PTN | Ninguna | PTN | PTN |

Una aclaración importante que está en la documentación de origen: la columna "MHD = Ninguna" **no** quiere decir que JET ignore esa inestabilidad. Otros papers de JET muestran que la señal de modo bloqueado sí protegía: frenaba suavemente el pulso y disparaba la válvula de emergencia ([S6]), y PETRA "triggers a stop and MGI" (traducción nuestra: dispara un stop y la inyección masiva de gas) ante ella ([S7]). Y las tablas que JET configuraba sí la respondían: en las campañas de 2011-2012 con la pared tipo ITER, los stops disparados por MHD fueron, junto con los de puntos calientes, "the vast majority of primary PIW stops" (traducción nuestra: la gran mayoría de los stops primarios PIW, que son los que dispara el RTPS; [N1] p.12 y p.14 del PDF). La Tabla 1 sólo ilustra una configuración; la instancia 2 de §7.4 certifica nuestra versión del otro camino documentado, del MHD al PTN y a la válvula.

Otra aclaración: que la columna "Slow" sea la alarma genérica de "terminación lenta" es una inferencia nuestra (A-31). Los valores de esas 7 celdas están impresos, pero el paper no dice explícitamente qué es esa columna. Por eso las 7 leyes `pub_*_Slow` son hecho de JET más una inferencia nuestra.

### 7.3 Las columnas que faltan en la tabla publicada — 21 leyes `asm_*` — SUPUESTO

JET publicó una tabla con sólo 4 de las 8 columnas de alarma posibles (dejó afuera 3 tipos de alarma más y la fila del "aviso ciego"; esta última se trata aparte en §7.5). Para poder demostrar leyes sobre **todas** las alarmas posibles, rellenamos las columnas que faltan con un criterio conservador y declarado: la alarma "rápida" siempre va directo a PTN en cualquier fase (motivado por otro paper que menciona ese mecanismo, aunque no publica la tabla completa), y las otras dos columnas que faltan se completan con una regla simple y explícita.

| Fase | `_Fast` (rápida) | `_MhdB` (segunda inestabilidad) | `_BothHs` (ambos puntos calientes a la vez) |
|---|---|---|---|
| Breakdown | PTN | Ninguna | PTN |
| Ip Rise | PTN | Ninguna | PTN |
| Limiter | PTN | Ninguna | PTN |
| X-point | PTN | Ninguna | PTN |
| Heating 1 | PTN | Ninguna | PTN |
| Heating 2 | PTN | Ninguna | **RTPS** |
| Termination | PTN | Ninguna | PTN |

Etiqueta de la documentación de origen: **"fabricada"**, la más honesta de las etiquetas de supuesto — son valores inventados por nosotros para completar el modelo, no una inferencia de una cita ambigua. Dos precisiones. "Rápida siempre a PTN" es **una configuración posible** entre varias: otro paper de JET ([N1]) lista también un stop suave llamado "Fast" (A-4). Y "ambos puntos calientes" es el más grave de los dos por separado, una **cota inferior** razonable que depende del orden elegido (A-1, A-32): en Heating 2 da RTPS porque ponemos JTT por debajo de RTPS; con el otro orden, esa celda daría JTT. En JET, "los dos a la vez" es una alarma que se configura por su cuenta.

### 7.4 La segunda instancia de configuración — 14 + 42 leyes `inst2_*` — SUPUESTO

La instancia 2 es idéntica a la instancia 1 en todo (por eso hacen falta 42 leyes `inst2_same_*`, que simplemente confirman "esta celda es igual a la de la instancia 1"), excepto en una cosa: la inestabilidad "MHD" y su variante sí llegan al PTN a partir de la fase X-point en adelante.

| Fase | `inst2_*_Mhd` | `inst2_*_MhdB` |
|---|---|---|
| Breakdown, Ip Rise, Limiter | Ninguna | Ninguna |
| X-point, Heating 1, Heating 2, Termination | **PTN** | **PTN** |

Por qué existe esta segunda instancia: otro paper de JET, sobre la válvula de emergencia, menciona que la señal de modo bloqueado "is already used at JET to soft-stop the pulse" (traducción nuestra: ya se usa en JET para frenar suavemente el pulso); un tercer paper sobre un sistema posterior de detección (PETRA, [S7]) dice explícitamente que, ante esa alarma, PETRA "triggers a stop and MGI" (traducción nuestra: dispara un stop y la inyección masiva de gas, que es lo que hace la válvula de emergencia). Es decir: hay indicios sólidos de que en la práctica esa alarma sí protege, aunque la tabla de 2011 que citamos como "instancia 1" no lo muestre. En vez de discutir cuál tabla es "la verdadera", certificamos las dos, y así el método queda probado para ambas.

### 7.5 La fila del aviso ciego — 7 leyes `asm_*_Blind` — SUPUESTO

Un "aviso ciego" es la respuesta de emergencia cuando un sensor deja de mandar datos (el sistema se queda "ciego" sobre esa señal). JET menciona que existe esta categoría de aviso, pero no publica su fila en la tabla. Asumimos, de forma declarada, que en las siete fases manda directo a PTN.

### 7.6 El cableado de la válvula de emergencia — 17 leyes — SUPUESTO/HECHO JET/MEZCLA

- **8 leyes `dms_trig_*`** (SUPUESTO, A-10): dicen qué alarmas están cableadas a la válvula de emergencia (las que anuncian una disrupción probable: rápida, ambas inestabilidades) y cuáles no (las de punto caliente, el "ambos a la vez", el aviso ciego).
- **7 leyes `dms_window_*`** (**HECHO JET**, R-14, seis de ellas; `dms_window_Termination` es **MEZCLA**, R-14 + A-10): la ventana de fases en la que la válvula puede dispararse — desde la formación del punto X (cuando el plasma, ya formado, pasa a la configuración con punto X) hasta el final. Con dos salvedades (A-10): en JET esa ventana se programa en cada pulso y en el modelo es fija; y el paper dice que "en general" se cierra al terminar la etapa posterior al calentamiento, mientras que el modelo la deja abierta durante toda la terminación (`dms_window_Termination` extiende la ventana del paper, y por eso es MEZCLA).
- **2 leyes `dms_on_commfault_off`, `dms_on_watchdog_off`** (SUPUESTO, A-10, A-12, A-13): ni un fallo de comunicación ni el vigía de latido expirado arman la válvula de emergencia en ninguna instancia — decisión nuestra; JET permitiría cualquiera de las dos opciones. Es un **compromiso, no algo conservador**: cortar de golpe con mucha corriente puede provocar una disrupción, y en ese caso quedaría sin mitigar.

### 7.7 La tercera instancia y las máscaras — 5 leyes — SUPUESTO

La instancia 3 usa la misma tabla publicada que la instancia 1, pero con los dos chequeos de fiabilidad (fallo de comunicación y aviso ciego) **apagados**. Esto muestra que la configuración queda fijada celda por celda, máscaras incluidas: un chequeo apagado es parte de los datos verificados, no un cambio de comportamiento silencioso. JET sí perdió disrupciones por configuración ([S6], R-15: 5 por bloqueos, *inhibits*, en los sistemas de protección en tiempo real que impidieron disparar la válvula, y 4 porque la ventana de tiempo de la válvula estaba mal configurada), pero ninguno de los dos casos está modelado acá: la ventana de la válvula es fija en el modelo (A-10), y los bloqueos y puenteos de las entradas y salidas del PTN quedan afuera (A-21); las máscaras cubren sólo los dos chequeos de fiabilidad.

### 7.8 Una alarma universal — 1 ley `fast_ptn` — MEZCLA

```bend
law fast_ptn:
  for +i: S.Inst
  for +s: S.St
  {S.is_ptn(S.level_of(...)) == True{} : Bool}
```
"Para cualquier instancia y cualquier estado, la alarma rápida siempre lleva a PTN." A diferencia de las leyes de celda (que son sobre una fase fija), ésta es universal sobre **todas** las fases y estados a la vez, porque en nuestra tabla la alarma rápida es PTN en las siete fases sin excepción. **Origen: MEZCLA** (el mecanismo es hecho, R-7; que sea uniforme en las siete fases es supuesto, A-4, y es una configuración posible entre varias). Vale para las cuatro instancias; con un stop ya en curso, la alarma pasa por la tabla secundaria.

### 7.9 La capa "concreta" — 2 leyes — PLOMERÍA

Dos leyes técnicas que conectan el "alfabeto abstracto" de eventos (el que usan las leyes de la sección 6) con el "alfabeto concreto" (los eventos tal como los vería la planta real). Comparan contra una **cuarta** transcripción, separada, de la tabla y de las ventanas, y confirman que traducir un evento de la planta al evento abstracto correspondiente usa exactamente la instancia que corresponde (no mezcla, por ejemplo, la tabla de la instancia 1 con la ventana de la instancia 2). Desde la revisión 4 también revisan, para cada nivel de stop en curso, que se lea la tabla primaria o la secundaria según corresponda (5 376 casos en total: 4 instancias × 7 fases × 2 × 4 niveles × 24 eventos de planta). Qué fase de la tabla se lee es nuestra lectura, no algo documentado (A-24, A-30). **Origen: PLOMERÍA.**

### 7.10 La instancia 4 y las tablas secundarias — 6 leyes — SUPUESTO/MEZCLA (revisión 4)

Cuando llega una alarma y **ya hay un stop en curso**, el modelo ahora consulta una **tabla secundaria** propia de cada instancia. Que existan dos niveles de respuesta, primaria y secundaria, lo dice JET ([S1], R-6); lo que no se publicó es qué dice la tabla secundaria de JET.

- **`inst4_table`, `inst4_mask`** (SUPUESTO): la instancia 4 usa la tabla publicada, celda por celda, con los dos chequeos de fiabilidad prendidos. Es la definición de nuestra instancia, igual que las `inst2_same_*`.
- **`sec_legacy`** (MEZCLA): en las instancias 1 a 3, la tabla secundaria es la primaria otra vez. Es la forma en que el modelo funcionaba antes, que se conserva: una segunda alarma vuelve a leer la tabla de siempre y se queda con la respuesta más grave (A-2, A-16).
- **`sec_inst4`** (MEZCLA): en la instancia 4, la tabla secundaria dice PTN donde la primaria pide alguna respuesta, y nada donde no pide nada. Se compara contra una transcripción separada. El contenido es **ilustrativo e inventado** (A-35).
- **`sec_monotone`** (MEZCLA): ninguna respuesta secundaria es menos grave que la primaria, con cualquiera de los dos órdenes.
- **`sec_primary_ptn`** (MEZCLA): si la tabla primaria dice PTN, la secundaria también. Coincide con [N1] p.14: "any primary PTN stop can never be followed by a PIW secondary" (traducción nuestra: a un PTN primario nunca lo sigue un stop suave secundario).

Una advertencia honesta: el teorema de seguridad del modelo ya valía para cualquier pedido de stop, así que decir "es seguro con las dos tablas" es casi automático. Lo que aportan estas leyes es otra cosa: el mecanismo que JET sí documenta, una demanda concreta demostrada en la instancia 4, y el contenido de la tabla secundaria como un dato explícito y declarado. Y más autoridad no es necesariamente más seguridad: en la instancia 4, un PTN secundario puede provocar una disrupción, y para las alarmas Slow, MCHS, DHS y de los dos puntos calientes ese PTN no arma la válvula de emergencia.

---

## 8. Las leyes de "la protección siempre llega a tiempo" — 2 leyes

Aparte de los dos teoremas de trazas de §6.2, que dicen que el invariante sobrevive a cualquier secuencia de eventos, todo lo anterior dice **qué no puede pasar** y **qué tiene que pasar en un paso**. Pero ninguna de esas leyes garantiza, por sí sola, que la protección **llegue**: en principio, un sistema podría cumplir todas las leyes de un paso y aun así quedarse "esperando para siempre" sin nunca disparar. Estas dos leyes cierran ese hueco: son las únicas que hablan de lo que **tiene que terminar pasando** a lo largo de una secuencia de eventos de cualquier largo (respuesta acotada). Como `traces_safe`, se demuestran por inducción sobre la traza (§3), a partir de hechos de un paso que el certificado ya da.

Los dos bloques de abajo son esquemáticos: las hipótesis están escritas en palabras, y los enunciados exactos están en `LAWS_JETPROT_LIVE.bend`.

```bend
law watchdog_responds:
  for +o: S.Ord
  for +s: S.St
  for +h_inv: {invariante de s}
  for +trace: List<&2, S.Ev>
  for +h_nohb: {la traza no tiene "latido de corazón" ni reinicio}
  for +h_len: {la traza tiene al menos hb_max ticks}
  {el PTN quedó activo al final}
```

En criollo: **desde cualquier estado válido, si pasa el tiempo suficiente sin ninguna señal de "sigo vivo" (y sin un reinicio de por medio), el PTN termina activándose, garantizado, sin importar qué otra cosa haya pasado en el medio.** No es "probablemente"; es "matemáticamente inevitable" dado el modelo. **Origen: MEZCLA** (el vigía de latido al PTN es hecho, R-13; el contador de ticks sin señal de vida, que arranca en Breakdown y se reinicia con cada latido, es formalización nuestra, A-12; que se cuente en ticks y no en milisegundos es la simplificación sin reloj, A-15, común a todas las leyes: el modelo no tiene noción de tiempo real, sólo de "cuántos eventos pasaron").

```bend
law dms_responds:
  ... (mismo esquema) ...
  for +h_armed: {el DMS ya está armado}
  for +h_noreset: {la traza no tiene reinicio}
  for +h_len: {la traza tiene al menos ack_max ticks}
  {el DMS terminó disparado}
```

En criollo: **una vez que el DMS está armado, si pasa el tiempo suficiente sin un reinicio, termina disparando, sí o sí** —ya sea porque llegó la confirmación de la planta o porque se agotó el tiempo de espera. **Origen: MEZCLA** (la secuencia "apagar calentadores → confirmación o tiempo límite → disparar" es hecho, R-11, y el paper de la válvula [S6]; el contador de espera y su tope `ack_max` son formalización nuestra, A-11; que se cuente en ticks es la simplificación sin reloj, A-15, común a todas las leyes).

Estas dos leyes se demuestran a partir de ocho "hechos de una celda" ya probados en la sección 6 (P1, D4, D7, D8, P15, P18, E11 y un lema de preservación), combinados con inducción sobre la traza completa en un archivo aparte (`PROOF_JETPROT_LIVE_CORE.bend`).

---

## 9. Las leyes de plomería matemática — 8 leyes

Este último grupo (`LAWS_JETPROT_SOUND.bend`) no dice nada sobre JET. Es el equivalente a verificar que la balanza con la que pesás todo lo demás está bien calibrada.

**El problema que resuelven.** Muchas leyes de las secciones 6 y 7 terminan concluyendo cosas como "estos dos estados son iguales" — pero lo dicen a través de un **predicado** (una función que compara dos valores y devuelve Sí/No comparando un número interno asociado a cada uno, un "rango"). El riesgo: si ese predicado tuviera un error — por ejemplo, si confundiera por accidente dos valores distintos tipo `Off` y algún otro estado, asignándoles el mismo número interno — todas las leyes que dependen de él podrían estar "vacías" (técnicamente demostradas, pero sin decir nada real), sin que nada lo detectara. Estas 8 leyes son el puente que ata "el predicado dijo Sí" con "los dos valores son **realmente, matemáticamente**, el mismo valor".

Ejemplo, con la traducción línea a línea:

```bend
law lvl_eq_sound:
  for a: S.Level                                    # cualquier nivel de respuesta a
  for b: S.Level                                    # cualquier nivel de respuesta b
  for h: {Spec.lvl_eq(a, b) == True{} : Bool}        # asumiendo que el predicado dice "son iguales"
  {a == b : S.Level}                                 # entonces a y b son el mismo valor, de verdad
```

Hay una de éstas para cada tipo de dato que el modelo compara: igualdad de niveles de respuesta (`lvl_eq_sound`), de fases (`phase_eq_sound`), de estados del DMS (`dms_eq_sound`), de estados de una unidad de calentamiento (`unit_eq_sound`), de booleanos (`beq_sound`), y del estado de control completo —los ocho casilleros juntos— (`fin_eq_sound`). Se suman dos más sobre el **orden** de urgencia entre niveles: que todo nivel es "igual o menos urgente" que sí mismo (`lvl_le_refl`), y que si A es igual-o-menos-urgente que B y B es igual-o-menos-urgente que A, entonces A y B son el mismo nivel (`lvl_le_sound` — esto es lo que hace que la ley P1 de la sección 6, escrita con ese predicado de orden, hable realmente de "urgencia" y no de un truco de comparación de números.

**Origen: PLOMERÍA**, las 8. Se demuestran sin inducción: las siete que tratan de tipos chicos, revisando todos los casos (tipos de 2, 3, 4 o 7 valores), y `fin_eq_sound` campo por campo, aplicando esos lemas a los ocho campos del estado de control.

---

## 10. Resumen: qué es de JET y qué es nuestro

| Origen | Qué significa | Cantidad |
|---|---|---|
| **HECHO JET** | Citado casi textualmente de un paper publicado | 44 |
| **SUPUESTO** | Decisión de modelado nuestra, declarada | 140 |
| **MEZCLA** | Mecanismo de JET, forma exacta nuestra | 32 |
| **PLOMERÍA** | Método de la prueba, no habla de JET | 18 |
| **Total** | | **234** |

Qué cambió en la revisión 4: 5 leyes nuevas en §6.8 (2 HECHO JET y 3 MEZCLA, tras una auditoría del mismo día), 2 SUPUESTO (`inst4_table`, `inst4_mask`) y 5 MEZCLA (`inst4_second_alarm_ptn` y las cuatro `sec_*`). La misma auditoría pasó de HECHO JET a MEZCLA siete leyes que ya existían, porque cada una afirma algo que ningún paper dice: `dms_window_Termination` (extiende la ventana de la válvula a toda la fase de terminación, A-10); `ptn_deenergizes` (P2) y `ptn_no_heat`, que apagan el calentamiento en todo camino al PTN (A-9); `stop_reduces_power` (P3) y `d2_soft_stop_ramps` (D2), que bajan las dos unidades en todo stop suave (A-9); `heat_permissive` (P5), cuya forma exacta es nuestra (A-5, A-8, A-9); y `advance_frozen` (P19), que fija los comandos a los contadores (A-11, A-12). Las demás leyes que ya existían conservan su etiqueta, pero varias dicen ahora qué parte es hecho y qué parte es política nuestra (P1, D1, E3, F1a, F1e, `fast_ptn`, las celdas `_Fast` y `_BothHs`, `dms_on_*`). Una revisión del 2026-09-23 aplicó la misma regla a cuatro leyes más: `dms_no_heat` pasó de HECHO JET a MEZCLA (que el calentamiento siga apagado después de la inyección es A-9), y `dms_monotone` (P15), `dms_frame` (P17) y `f3b_commfault_masked_is_noop` pasaron de SUPUESTO a MEZCLA, porque además de su parte nuestra enuncian algo que JET publica ([S6], R-14, [S1]).

**¿Por qué hay tantas más leyes "supuesto" que "hecho"?** No es que el modelo se aleje de JET. 101 de las 140 son celdas y datos de configuración que JET no publica o que son de nuestras instancias: las columnas y la fila que faltan en la Tabla 1, las instancias 2, 3 y 4, el cableado de la válvula y las máscaras (`asm_*`, `inst2_*`, `dms_trig_*`...). Entre las 39 leyes de comportamiento "supuesto", unas 18 son leyes de **marco** (las que dicen "y nada más se mueve"). Ningún paper de ingeniería publica jamás una frase como "y ninguna otra cosa pasa" — eso es exactamente el tipo de detalle que hay que completar para poder demostrar algo con precisión matemática, y por eso esas leyes quedan clasificadas como nuestras. No es una debilidad del modelo: es, literalmente, el trabajo que hace falta hacer para poder demostrar algo en primer lugar.

Doce leyes son **"derivadas"**. Las doce están en la lista canónica del proyecto (`pymodel/jetprot_laws.py`): `d3_advance_to_termination_ramps`, `d5_hb_counts`, `d9_heatack_fires`, `d10_reset_accepted_when_safe`, `f1b_stop_keeps_prog`, `f2a_local_reduces` y, desde la revisión 4, `p1a_ptn_latched`, `p1b_stop_never_cleared`, `d1a_ptn_honoured` y `d1b_primary_honoured`, y desde la auditoría del 2026-09-22 `ramping_never_returns` (P4) y `stop_overrides_heat` (P6). Estas dos últimas salen de P5 y P7 juntas: una unidad sólo puede volver a tener potencia con su propio comando de "prender" (P7), y ese comando sólo funciona desde apagada y sin stop (P5). Lo encontró esa auditoría, que lo comprobó en todas las celdas del modelo de referencia en Python. La quinta ley nueva de la revisión 4, `piw_after_ptn_is_noop`, no es derivada. Quedan documentadas porque cada una es el enunciado con nombre propio de algo que importa (una cita de JET, una hipótesis declarada), pero cada una está cubierta por otras leyes más generales (`d1a_ptn_honoured` sólo en los estados que cumplen el invariante), así que no deberían contarse como evidencia independiente adicional. Ser derivada no cambia su origen: `f2a_local_reduces` sigue siendo HECHO JET, por ejemplo.

---

## 11. Glosario rápido

| Término | Qué es |
|---|---|
| **Bend** | El lenguaje de programación en el que están escritas las demostraciones; una computadora las verifica con precisión matemática total. |
| **Certificado** | Verificación por fuerza bruta, hecha por computadora, de todas las combinaciones posibles de un chequeo. |
| **CISS / PSACS** | Dos capas de JET que no se modelan acá: el CISS (Central Interlock and Safety System), protección cableada de la planta ([S1]), y el PSACS (Personal Safety & Access Control System), que protege a las personas ([S2]). Este proyecto modela RTPS+PTN, que protege el equipo. |
| **DMS / DMV** | Sistema/válvula de mitigación de disrupciones: inyecta gas de emergencia al plasma. |
| **Estado** | La "foto" de todos los datos relevantes de JET en un instante. |
| **Evento** | Algo que ocurre y puede cambiar el estado (alarma, comando, tick de reloj, reinicio). |
| **Invariante** | Una propiedad que se cumple siempre, sin excepción, desde el arranque hasta el fin. |
| **JTT** | *Jump-to-Termination*: un stop suave que lleva las formas de onda directamente a la región de terminación, sin pasar por el PTN. |
| **Ley** | Un enunciado demostrado matemáticamente sobre el modelo. |
| **PTN** | *Pulse Termination Network*: la parada de emergencia final, cableada y trabada. |
| **RTPS** | *Real-Time Protection Sequencer*: el "cerebro" que decide la gravedad de la respuesta. |
| **Traza** | La secuencia completa de eventos de un pulso, de principio a fin. |

---

Para ver el código exacto, sin las explicaciones extendidas, y con el detalle línea a línea de cada predicado, usar `LEYES_CATALOGO.md` en esta misma carpeta.
