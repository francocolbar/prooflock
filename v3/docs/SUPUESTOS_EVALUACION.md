# Supuestos del modelo JET: evaluación contra el código, la documentación de JET y la física

Fecha: 2026-09-22, versión 3. La versión 1 evaluaba los supuestos sólo contra el código del modelo. La versión 2 agregó dos miradas más: la documentación publicada de JET y la física de fusión de nuestra biblioteca. La versión 3 corrige errores de la versión 2 (citas mal atribuidas, alcances exagerados y traducciones puestas entre comillas como si fueran la cita) y marca cada pasaje corregido con *(corregido en v3)*; agrega la columna "Tras corregir" al resumen y la sección final **Estado tras la corrección (2026-09-22)**: qué se aplicó al registro, qué cambió en el modelo, qué quedó diferido y qué preguntas hay que hacerle a JET. Fuera de los pasajes marcados, la evaluación original de cada supuesto se deja como estaba, para que se vea la historia; la versión 2 completa no quedó guardada en el repositorio. El 2026-09-23 se agregó a esa sección una nota con los cambios de ese día (Bend 2.0.25, el gate en paralelo y la equivalencia del mutante sobreviviente, calculada por el gate).

## Cómo se hizo

Cada uno de los 26 supuestos del registro (`phase3-sources.md` §4) y los 7 supuestos implícitos que encontré en el código se contrastaron contra tres cosas:

1. **El código** del modelo, `jetprot.bend`. ¿El supuesto describe lo que el modelo realmente hace?
2. **La documentación de JET.** ¿Lo que suponemos coincide con lo que JET publicó sobre su propio sistema?
3. **La física de fusión.** ¿Tiene sentido para un tokamak real, y la etiqueta de dirección es correcta?

Las miradas 2 y 3 las hicieron cuatro investigaciones en paralelo. Después verifiqué contra el texto de las fuentes las 22 citas en las que se apoyan las conclusiones principales; todas aparecen literalmente. Los números de página vienen de las notas de esas investigaciones. Después, al revisar el registro, se re-verificaron contra el texto las citas de [N1], [N2], [S3], [S6], [S7], [K15] y [M13] que usa el registro. En [N1] las páginas son las del PDF del preprint (la página impresa es la del PDF menos 4). *(corregido en v3)*

Una aclaración de fondo: nada de esto dice si un supuesto es verdad sobre la máquina real. Dice si está bien fundado, si es coherente con lo publicado y si su etiqueta describe bien el riesgo.

## Fuentes

**Documentación de JET.** Las siete del registro original, más cuatro nuevas encontradas en esta revisión:

| Clave | Fuente | Nota |
|---|---|---|
| [S1] | Stephen et al. 2011, ICALEPCS FRAAULT04 | Fuente principal; Tabla 1 en p.1295 |
| [S2] | Waterhouse et al. 2025, *JET CODAS — the final status*, §3.4 | |
| [S3] | Edwards et al. 2019, configuración del RTPS en Level-1 | Preprint UKAEA-CCFE-CP(19)30 |
| [S4] | Alves et al. 2011, ICALEPCS WEPMN014 | |
| [S5] | Jouve et al. 2011, ICALEPCS WEPMU018 | **Ojo:** ahí "RTPS" es el sistema de procesamiento de las cámaras, no el secuenciador. No sirve como fuente sobre el secuenciador. |
| [S6] | Reux et al. 2013, la válvula DMV en operación rutinaria | Preprint EFDA-JET-CP(12)05/22 |
| [S7] | Stuart et al. 2021, PETRA | Copia del repositorio de UKAEA; dice "All rights reserved": se cita, no se copia |
| **[N1]** | **De Tommasi et al. 2013, *PPCC System Enhancements for the JET ITER-like Wall*** | **Nueva.** Preprint EFDA-JET-PR(13)06. Es el único texto abierto encontrado que cuenta cómo se configuraron y usaron las paradas primarias y secundarias; el mecanismo ya está en [S1] (R-6). *(corregido en v3)* Dice "may not be further circulated": se cita, no se copia. |
| **[N2]** | **Neto et al. 2011, ICALEPCS MOPMU035** | **Nueva.** CC BY 3.0. Describe el salto a terminación en el controlador de forma. |
| **[K15]** | **Kruezi et al. 2015, el nuevo DMS de JET** | **Nueva.** Preprint CCFE-PR(17)36 |
| **[M13]** | **Mayoral et al., arXiv:1309.0948** | **Nueva.** Calentamiento con la pared metálica |

No se consiguieron: Lehnen et al. 2011 sobre inyección masiva de gas en JET, Huber et al. 2018 y 2019, el preprint de WALLS y Arnoux 2012. No existe un paper abierto dedicado a PEWS.

**Física.** De `papers/`: los capítulos 2, 3, 6 y 8 del *ITER Physics Basis* de 1999 (IPB99), los capítulos 3, 6 y 8 del *Progress in the ITER Physics Basis* de 2007 (IPB07: Hender, Gormezano, Gribov), *Fusion Physics* del IAEA 2012, Eich 2013, Loarte 2007, y Wesson 2004. Wesson es un escaneo sin texto; una de las investigaciones lo pasó por OCR y contrastó cada cita con la imagen de la página.

## Escala

| Veredicto | Significa |
|---|---|
| ✅ **Correcto** | Coherente con el código, con JET y con la física; bien etiquetado. |
| ⚠️ **Con reservas** | Defendible, pero hay algo que corregir en el texto, la etiqueta o las consecuencias declaradas. |
| ❌ **Revisar** | Contradice al código, a JET o a la física, o su etiqueta describe mal el riesgo. Hay que cambiar el registro, y en algunos casos el modelo. |

En las columnas de JET y física: **Sí** o **Sólido** quiere decir respaldado; **Parcial** o **Con reservas**, respaldado en parte; **Contradice** o **Cuestionable**, en contra; **—**, las fuentes no lo tratan.

## Resumen

| # | Supuesto | Código | JET | Física | **Final** | **Tras corregir** |
|---|---|---|---|---|---|---|
| A-1 | Orden de urgencia Ninguna < JTT < RTPS < PTN | ⚠️ | Parcial | Con reservas | ⚠️ | ✅ |
| A-2 | Escalar siempre al máximo | ⚠️ | Parcial | Cuestionable | ❌ | ⚠️ |
| A-3 | Matriz secundaria fuera del alcance | ❌ | Parcial | — | ❌ | ⚠️ |
| A-4 | Columnas faltantes de la Tabla 1 | ⚠️ | Parcial | Con reservas | ⚠️ | ✅ |
| A-5 | Fases y ventanas de calentamiento | ❌ | Parcial | Cuestionable | ❌ | ⚠️ |
| A-6 | Dos unidades de calentamiento | ⚠️ | Parcial | Con reservas | ⚠️ | ✅ |
| A-7 | La reducción local dura todo el pulso | ✅ | Parcial | Sólido | ✅ | ✅ |
| A-8 | Un booleano para el plasma | ✅ | Parcial | Con reservas | ⚠️ | ✅ |
| A-9 | Efecto de los stops sobre el calentamiento | ⚠️ | Parcial | Sólido | ⚠️ | ✅ |
| A-10 | Qué alarmas arman el DMS | ✅ | Sí, con correcciones | Sólido | ⚠️ | ⚠️ |
| A-11 | Secuencia del DMS | ⚠️ | Parcial | Con reservas | ⚠️ | ✅ |
| A-12 | Vigía de latido | ✅ | — | Con reservas | ⚠️ | ⚠️ |
| A-13 | Fallo de comunicación y alarma ciega | ✅ | Sí | — | ✅ | ✅ |
| A-14 | Fin de pulso protegido | ✅ | Sí | — | ✅ | ✅ |
| A-15 | Sin tiempo real | ✅ | Sí | — | ✅ | ✅ |
| A-16 | No hay matriz secundaria | ⚠️ | Sí, pero ver consecuencia | Cuestionable | ❌ | ⚠️ |
| A-17 | Un paso para software y hardware | ✅ | Sí | — | ✅ | ✅ |
| A-18 | Mensajes siempre bien formados | ✅ | Parcial | — | ✅ | ✅ |
| A-19 | Comando igual a efecto | ✅ | Sí | — | ✅ | ✅ |
| A-20 | Un solo nivel de PTN | ✅ | Parcial | — | ✅ | ✅ |
| A-21 | Bypass sólo en dos chequeos | ✅ | Sí | — | ✅ | ✅ |
| A-22 | Umbral de corriente de la válvula | ✅ | Parcial | Sólido | ⚠️ | ⚠️ |
| A-23 | Configuración fija durante el pulso | ✅ | Sí | — | ✅ | ✅ |
| A-24 | Dos relojes de fase | ⚠️ | Parcial | Cuestionable | ❌ | ⚠️ |
| A-25 | Alarma ciega como columna de la tabla | ✅ | Parcial | — | ✅ | ✅ |
| A-26 | No existe "inhibido" | ✅ | Sí | — | ✅ | ✅ |

| Implícito | Decisión del código | JET | Física | **Final** | **Tras corregir** |
|---|---|---|---|---|---|
| #1 | Ventana de calentamiento fija, igual para las dos unidades | Contradice | Cuestionable | ❌ | ⚠️ (A-27) |
| #2 | Perder el plasma apaga todo en el mismo paso | — | Con reservas | ⚠️ | ✅ (A-28) |
| #3 | Salir de la ventana apaga; entrar a Termination baja | — | Sólido | ✅ | ✅ (A-29) |
| #4 | El programa sigue avanzando de fase durante un stop | Contradice | Cuestionable | ❌ | ⚠️ (A-30) |
| #5 | La columna "Slow" es el disparador de terminación lenta | Parcial | — | ⚠️ | ✅ (A-31) |
| #6 | "Ambos puntos calientes" es el máximo de los dos | Contradice | Con reservas | ⚠️ | ✅ (A-32) |
| #7 | Una segunda alarma local no tiene efecto | Parcial | Cuestionable | ❌ | ⚠️ (A-33) |

**Balance de los 26 supuestos:** 12 correctos, 9 con reservas, 5 para revisar. Contra la versión 1 empeoraron siete: A-2, A-8, A-10, A-12, A-16, A-22 y A-24. Ninguno mejoró.

**Tras corregir** (versión 3) quiere decir: ✅ = el registro describe bien el supuesto y su etiqueta, y lo que difiere de JET está declarado, como límite del modelo o como invento nuestro; ⚠️ = además queda una diferencia con JET que cambia lo que afirma alguna ley, o una pregunta abierta a JET (Q1 a Q9, en la sección final) de la que depende el supuesto. ✅ no quiere decir "igual a JET": A-17 (un solo paso para software y hardware), A-19 (comando igual a efecto) y A-20 (un solo nivel de PTN), por ejemplo, son simplificaciones declaradas. El balance mide cuán bien está descrito y etiquetado cada supuesto, no cuánto se parece el modelo a JET. **Balance tras corregir:** de los 26, 18 ✅ y 8 ⚠️ (A-2, A-3, A-5, A-10, A-12, A-16, A-22 y A-24), ninguno ❌; de los 7 implícitos, ahora registrados como A-27 a A-33, 4 ✅ y 3 ⚠️ (#1, #4 y #7). Los dos supuestos nuevos, A-34 (la reducción local se olvida al apagar la unidad) y A-35 (la tabla secundaria ilustrativa de la instancia 4), quedan ⚠️: están declarados, pero dependen de preguntas abiertas (A-34 de Q5; A-35 de Q2 y Q4). (Una primera redacción de esta columna usaba un criterio más estricto, "no queda una divergencia conocida con JET", sin aplicarlo parejo, y daba 21 ✅; A-3, A-12 y A-22 pasaron a ⚠️ porque dependen de Q2 y Q4, de Q6 y de Q9.)

## Las cuatro conclusiones que importan

**1. El punto débil del modelo es qué pasa cuando llega una alarma durante un stop en curso.** Cinco hallazgos apuntan al mismo lugar: A-2, A-3, A-16, A-24 y el implícito #4. Sobre las paradas en secuencia, [N1] publica dos reglas, un mecanismo y una estadística; el modelo no sigue la primera regla ni el mecanismo tal como JET lo describe *(corregido en v3)*:

- una vez que empieza un stop, la configuración queda **congelada** en la ventana de tiempo donde se disparó el stop primario (p.13 del PDF; la frase original está en la decisión (a) de la sección final);
- JET configura **stops secundarios** aparte ("seven primary stops and six secondary", p.13 del PDF; traducción nuestra: siete stops primarios y seis secundarios), que arrancan cuando el primario no logra mitigar el evento o cuando la propia estrategia de parada genera un evento de terminación más prioritario (p.14 del PDF). El secundario más usado fue el PTN lento (figura 7, p.23 del PDF): es una estadística de uso, no una regla. Si toda alarma nueva durante un stop dispara la secundaria es justamente la pregunta Q4;
- el RTPS limita las paradas a "a maximum of two in sequence" (p.13 del PDF; traducción nuestra: como máximo dos seguidas). Que se trate de dos stops suaves es lectura nuestra. En [N1], "PIW" es el proyecto de protección de la pared tipo ITER (p.12 del PDF), y los stops PIW son las respuestas de parada nuevas del controlador de forma, disparadas por el RTPS (el JTT es una de ellas, figura 6); identificarlos con los stops suaves del modelo (JTT y RTPS) también es nuestro. *(corregido en v3)*

El modelo hace otra cosa: sigue avanzando el reloj del programa, vuelve a leer la tabla primaria y toma el máximo (desde la revisión 4, eso vale para las instancias 1 a 3; la instancia 4 lee una tabla secundaria ilustrativa, A-35). El tope de dos seguidas, en cambio, el modelo lo cumple sin proponérselo: como el orden es estricto y hay sólo dos niveles suaves, no puede haber más de dos stops suaves seguidos (JTT y después RTPS). Y hay que leer bien la primera regla: [N1] la describe para el controlador de forma, es decir, qué configuración de stop ejecuta, no para cómo elige la respuesta el RTPS. Sobre eso no hay texto publicado. *(corregido en v3)* La física agrega dos cosas. La tabla debería indexarse por el estado del plasma, no por un reloj. Y la rampa de bajada es justo cuando más importan las alarmas de MHD y de densidad, porque el límite de densidad baja junto con la corriente.

Consecuencia concreta: un punto caliente en el divertor durante un stop RTPS se ignora en el modelo cuando la fase de programa es Heating 2 (en Heating 1 y en Termination la fila dice PTN y sí se atiende); eso pasa en las instancias 1 a 3, porque en la instancia 4, agregada en la revisión 4, da PTN (A-35). En JET, cuando se disparó una secundaria, la más usada fue el PTN lento (figura 7, una estadística de uso); qué se configuró para ese caso, o si se dejaba terminar el primario como permite R-6, no está publicado. *(corregido en v3)*

**2. "Apagar el calentamiento" no es conservador por defecto en JET.** Es conservador respecto de las cargas térmicas sobre la pared, pero no respecto de las disrupciones. JET no tiene histéresis en la transición del modo H al modo L ([IPB99-C2]), y su límite de densidad crece con la potencia ([IPB99-C3]). Un corte brusco puede terminar en colapso radiativo y disrupción. Escalar a un PTN es en sí mismo un riesgo de disrupción: un cambio grande y rápido de los parámetros puede hacer perder el control vertical ([IPB99-C3] p.2336), y la parada rápida se reserva para cuando la disrupción parece inevitable ([IPB07-C3] p.S189). Si el PTN de JET aterriza el plasma o lo disrumpe no está en la biblioteca. *(corregido en v3)* Las etiquetas de A-2, A-7, A-9, A-12 y del implícito #2 tienen que decir respecto de qué son conservadoras.

**3. Hay configuración por pulso que el modelo tiene fija.** La ventana de calentamiento y la ventana de la válvula se programan por pulso en JET ([S2], [S6]); en el modelo están fijas. Además, calentar durante la subida de corriente es rutina en JET ([IPB99-C6], [IPB07-C6]). Justamente una ventana de la válvula mal configurada explica 4 de las disrupciones no mitigadas (R-15).

**4. El umbral de la válvula es "corriente o energía", y el modelo sólo mira la corriente.** En el ejemplo de la figura 2 de [S7] (p.2, pulso #93912), una alarma de PETRA está condicionada a "plasma current > 1.6 MA OR plasma energy > 5 MJ" (traducción nuestra: corriente del plasma mayor a 1,6 MA **o** energía del plasma mayor a 5 MJ); el usuario configura ese condicionamiento dentro de límites ([S7] p.4), así que es un ejemplo de la forma de la condición, no la regla fija de PETRA. *(corregido en v3)* Con el DMS nuevo ([K15]) la regla tenía la misma forma con otros números: se operaba sin DMS sólo con corriente de hasta 2 MA y energía menor a 5 MJ. En el modelo, un plasma de baja corriente y mucha energía nunca arma el DMS. Eso es no conservador. Tiene arreglo barato, sin tocar el código (ver acciones). *(corregido en v3)* *(Resuelto en la revisión 4: A-22 redefine `ip` como el veredicto "corriente o energía almacenada por encima del umbral", sin tocar el código ni las leyes; sigue abierta la diferencia con PETRA de la pregunta Q9. Ver la sección final.)*

---

## Evaluación uno por uno

### A-1. Orden de urgencia — ⚠️

**Qué dice.** Ninguna < JTT < RTPS < PTN. El PTN arriba lo fuerza JET; el orden entre JTT y RTPS es nuestro.

**Código.** Las leyes abstractas se prueban para los dos órdenes, pero la instancia concreta sólo con éste.

**JET.** Confirma el PTN arriba: "a PIW stop can never preempt a PTN stop" ([N1] p.14). [N1] cuenta el JTT entre los stops PIW (figura 6), que identificamos con los stops suaves del modelo (JTT y RTPS), y no publica un orden entre ellos. Un PIW después de otro PIW se resuelve con los stops secundarios configurados, no con un orden global. *(corregido en v3)*

**Física.** El registro dice bien que es un orden de "autoridad, no de seguridad". El PTN tiene más autoridad, pero no protege más: un corte duro puede provocar una disrupción, con riesgo de desplazamiento vertical y de electrones desbocados; si el PTN de JET aterriza o disrumpe el plasma no está en la biblioteca. *(corregido en v3)* La física no da un orden entre JTT y RTPS; el mejor depende del estado del plasma.

**Veredicto.** Defendible y honesto. La etiqueta "neutral" vale para las leyes abstractas, no para la instancia concreta.

### A-2. Escalar siempre al máximo — ❌

**Qué dice.** Ante una alarma, el nivel pasa a ser el más urgente entre el actual y el pedido.

**JET.** JET sí escala, pero distinto: "When the primary stop fails to mitigate the event [...] or the stopping strategy itself generates a higher priority termination event, then a secondary stop is started" ([N1] p.14). La secundaria sale de configuración, no de un máximo, y hay "a maximum of two in sequence" ([N1] p.13).

**Física.** Cuestionable como regla universal. Un cambio grande y rápido de los parámetros del plasma puede hacer perder el control de posición vertical ([IPB99-C3] p.2336 de la revista; p.87 del PDF). *(corregido en v3)* Escalar una bajada suave a un PTN puede causar la disrupción que se quería evitar; por eso existe R-6.

**Veredicto.** La decisión está declarada como política distinta de la de JET, y eso está bien. Lo que hay que revisar es la etiqueta: "no conservador" es incorrecto. El efecto va para los dos lados, y las leyes P1 y D1, que exigen "al menos tan grave", pueden premiar un comportamiento físicamente peligroso.

### A-3. Matriz secundaria fuera del alcance — ❌

**Qué dice.** La tabla secundaria no está publicada; se justifica diciendo que en el modelo el caso era inalcanzable.

**Código.** La justificación quedó desactualizada con A-24: después de un JTT en Heating 2, una alarma de punto caliente en la cámara lee la fila de Heating 2 y pasa a RTPS. Eso es una respuesta secundaria, y ahora es alcanzable.

**JET.** Las secundarias eran rutina: JET registró 420 stops secundarios, "of which 111 (22 %) were programmed to be a PIW stop" ([N1] p.14).

**Veredicto.** Dejar la matriz afuera se justifica sólo porque no está publicada, no porque el caso no ocurra. Hay que reescribir la justificación.

### A-4. Columnas faltantes de la Tabla 1 — ⚠️

**Qué dice.** Se inventan 21 celdas: rápida a PTN en todas las fases, la segunda MHD igual a la primera, "ambos puntos calientes" como el máximo.

**JET.** Los disparadores existen: la figura 6 de [N1] lista los stops PIW "Slow, Fast, MHD, MHD 2, MCHS, DHS, MCHS+DHS, MHD Fast, JTT". Pero "Fast" también existe como stop PIW, así que "rápida a PTN siempre" es sólo una configuración posible. Y "MCHS+DHS" es un disparador configurado por separado, no el máximo de los otros dos.

**Física.** Rápida a PTN en el arranque y la subida de corriente tiene sentido: hay poca energía acumulada y nada que aterrizar suave. Dos puntos calientes a la vez sugieren una causa global, como demasiada potencia llegando al borde; "al menos la respuesta más severa" es razonable como cota inferior.

**Veredicto.** Bien etiquetado como fabricado. Falta registrar que "ambos puntos calientes" depende del orden de A-1.

### A-5. Fases y ventanas de calentamiento — ❌

**Qué dice.** Siete fases en orden; `Advance` es el reloj; bajo PTN no se avanza; las ventanas de PEWS se resumen en una función de la instancia.

**Código.** Dos errores: el JTT ya no escribe la fase (contradice a A-24), y la ventana de calentamiento no es parte de la instancia, está fija en el modelo.

**JET.** Confirma fases temporizadas y configuradas: "Pulses are split into several timed 'phases'" ([S3] p.5). Pero las ventanas de calentamiento son "programmed time windows" por pulso ([S2]), y [S6] lista "current ramp-up" entre las fases en las que se puede habilitar la válvula (es la ventana del DMS, no la de calentamiento, pero muestra que las fases de habilitación se eligen por pulso). *(corregido en v3)*

**Física.** Calentar durante la subida de corriente es rutina: "In JET, early LHCD is found to be the most efficient profile shaping method" ([IPB99-C6]); "Most of the experimental scenarios use a substantial amount of heating and/or current drive in the current ramp-up phase" ([IPB07-C6]).

**Veredicto.** Hay que corregir el texto. Y conviene decidir si la ventana pasa a la instancia, por unidad.

### A-6. Dos unidades de calentamiento — ⚠️

**Qué dice.** 16 PINIs se resumen en una unidad NB, la radiofrecuencia en otra; una alarma local deja la unidad en potencia parcial.

**JET.** **Corrige mi evaluación anterior:** aplicar la protección local a la radiofrecuencia no es una extensión nuestra. [S1] p.1295 dice "Similar relationships and control rules can be determined for the RF antennae, and the LH klystrons". El modelo deja afuera un tercer sistema, el LH.

**Física.** Sacar un PINI es una acción realmente local, porque cada haz tiene su propia huella en la pared. Vale a escala JET, uno de 16, pero no a escala ITER, con dos o tres haces. Compensar con otros PINIs recupera la potencia pero no la misma huella, así que no modelarlo es seguro.

**Veredicto.** Defendible. Falta declarar el sistema LH y que "local" depende de la escala.

### A-7. La reducción local dura todo el pulso — ✅

**JET.** "local protection, which inhibits individual heating components but allows the discharge to proceed" ([S1] p.1293). "Inhibir" es coherente con que el PINI quede afuera el resto del pulso.

**Física.** Los puntos calientes son térmicos y se relajan en segundos, por eso JET habla de límites dinámicos. No volver nunca a plena potencia es innecesario, pero seguro para la pared.

**Veredicto.** Correcto. La etiqueta "conservador" vale respecto de las cargas térmicas, no respecto del confinamiento: menos potencia puede hacer perder el modo H. Además, "todo el pulso" es falso si se miran trazas completas: la ley F2d prohíbe pasar de `Reduced` a `On` en un paso, pero si la unidad pasa por `Off` (una orden de apagado o una pérdida del permiso) y después se prende, vuelve a plena potencia (A-34; verificado corriendo el modelo de referencia en Python). *(corregido en v3)*

### A-8. Un booleano para el plasma — ⚠️

**JET.** Hay dos sistemas en paralelo: PEWS, con "basic interlocks with plasma current and density", y PEWS2, con cálculos de shine-through "on a PINI-by-PINI basis", "used in parallel" ([S2]).

**Física.** Son tres magnitudes distintas. Los haces necesitan densidad a lo largo de su camino, que depende de la geometría de cada PINI; con poca densidad el haz atraviesa el plasma y pega en la pared (shine-through), con mucha se deposita en el borde. La corriente es global. La radiofrecuencia necesita densidad frente a la antena; sin ella la antena queda sin carga, el voltaje sube y aparecen arcos.

**Veredicto.** La etiqueta "neutral" esconde dos direcciones. `plasma_ok` verdadero habilita todos los PINIs a la vez, lo que es no conservador frente a PEWS2. `plasma_ok` falso apaga todo, lo que es conservador. El registro debería definir el booleano como el Y de todos los permisos.

### A-9. Efecto de los stops sobre el calentamiento — ⚠️

**JET.** Los stops suaves bajan el calentamiento ([S2]: "ramp down the plasma current and heating power"). Que todo se apague en un paso bajo PTN está documentado sólo para las salidas del PTN que disparan el DMS; para las otras sólo existe la "secuencia fija" de R-0.

**Física.** Bajar en rampa es lo correcto para un stop suave. En JET, un corte brusco lleva a perder el modo H, después al colapso radiativo o al límite de densidad, y después a la disrupción.

**Veredicto.** La sustancia está bien. Quedan las reservas de la versión 1: "bajando" mezcla ir a cero con bajar a un nivel menor, todo stop baja las dos unidades, y la fila del registro se ve rota por las barras `|`.

### A-10. Qué alarmas arman el DMS — ⚠️

**JET.** Los disparadores reales de la válvula fueron el modo bloqueado y los picos de corriente o de voltaje de lazo ([S6] p.2); desde 2018, también los desplazamientos verticales ([S7]). Ninguna fuente muestra un punto caliente cableado a la válvula, lo que confirma la elección. Dos correcciones:

- la ventana de la válvula se configura por pulso ([S6]), y en el modelo está fija;
- el modelo la extiende hasta el final de Termination, mientras que [S6] dice "generally ... end of the post-heating phase".

**Física.** Correcta. El modo bloqueado es un precursor real de disrupción; un punto caliente es un problema lento de la pared que la inyección de gas no resuelve. Como la inyección es en sí una disrupción provocada, tiene sentido el diseño de JET de dos umbrales: uno bajo para el stop suave y uno alto para la válvula.

**Veredicto.** La lógica de disparo es correcta; la ventana hay que revisarla.

### A-11. Secuencia del DMS — ⚠️

**JET.** En 2012 no había confirmación de la radiofrecuencia y se usaba un retardo fijo de 50 ms ([S6]). Hacia 2014-15 aparece una señal de "safe state" de los haces neutros, y el estado seguro incluye también diagnósticos ([K15]: "all auxiliary heating and diagnostic systems"), como el haz de litio, que tarda 30 ms en apagarse ([S6]). *(corregido en v3)* Ninguna fuente dice qué hace JET si la confirmación nunca llega.

**Física.** Apagar primero el calentamiento está respaldado: al colapsar el plasma, los haces atraviesan y pegan en la pared, y las antenas quedan sin carga y pueden hacer arcos. Disparar por tiempo es físicamente necesario.

**Veredicto.** La etiqueta tiene que nombrar el activo: disparar por tiempo es conservador para la máquina y no conservador para el equipo de calentamiento. Falta declarar que el estado seguro incluye diagnósticos.

### A-12. Vigía de latido — ⚠️

**JET.** No hay más información que R-13.

**Física.** Cortar un pulso que perdió su protección es correcto. Pero el corte duro a alta corriente puede disruptir, y como el vigía no arma el DMS (A-10), esa disrupción no estaría mitigada. Es un compromiso, no algo claramente conservador.

**Veredicto.** Revisar la etiqueta.

### A-13. Fallo de comunicación y alarma ciega — ✅

**JET.** Confirmado y con detalle: "If the communication between RTPS and SC is lost for more than a configurable number of control cycles (typically 3, i.e. 6 ms)" se dispara el PTN ([N1] p.12). "Configurable" respalda la máscara por instancia. La detección también ocurre del lado del actuador, cosa que el modelo junta en un solo paso (A-17).

### A-14. Fin de pulso protegido — ✅

**JET.** Ninguna fuente publica un camino para destrabar el PTN a mitad de pulso. [N1] considera inválido pedir un stop suave cuando ya hay un PTN en curso.

### A-15. Sin tiempo real — ✅

**JET.** Los números existen y conviene agregarlos a la lista del registro: haz de litio 30 ms ([S6]), plazo de tiempo real de PETRA 2 ms ([S7]), tiempos de confirmación de alarma de 0 a 20 ms ([S6], tabla 1; [S7] muestra un ejemplo de 20 ms), tiempo de vuelo del gas de 1,1 a 4,8 ms ([K15]). *(corregido en v3)*

**Física.** El tiempo es central: el retardo de 50 ms para apagar el calentamiento compite con avisos de modo bloqueado de decenas de ms. Está bien declarado como límite.

### A-16. No hay matriz secundaria — ❌

**Qué dice.** La tabla secundaria no está publicada. Consecuencia declarada: con el orden elegido, un punto caliente en el divertor durante un stop RTPS se ignora.

**JET.** La matriz secundaria sigue sin publicarse, pero ahora sabemos tres cosas de ella: el PTN siempre se impone, hay como máximo dos stops seguidos (que sean suaves es lectura nuestra), y "The preferred secondary plasma stop is the PTN slow stop" ([N1], figura 7). En la figura 7 no aparece ningún JTT como secundario (lectura visual del gráfico). Sobre el tope, el texto de [N1] dice "a maximum of two in sequence" (p.13 del PDF); que se refiera a stops suaves es lectura nuestra. *(corregido en v3)*

**Física.** Bajar calentamiento y corriente suele aliviar el divertor, lo que apoya dejar correr el stop. Pero un stop puede mantener potencia reducida, los cambios de forma mueven los puntos de impacto, y la transición del modo H al L es brusca. Ignorar un punto caliente en el divertor durante todo el resto de un stop no es seguro en general.

**Veredicto.** La decisión de dejar afuera la matriz es correcta. Lo que hay que revisar es la consecuencia aceptada: el modelo ignora la alarma. *(corregido en v3)* Cuando JET disparó una secundaria, la más usada fue el PTN lento (figura 7, estadística de uso); pero la figura cuenta sólo secundarias que arrancaron, así que no puede pesar un PTN contra dejar terminar el primario, que R-6 permite. Qué configuró JET para un DHS durante un stop RTPS no está publicado (Q2, Q4).

### A-17. Un paso para software y hardware — ✅

**JET.** Las capas están separadas en hardware: las fuentes del DMS se disparan desde el PTN "utilizing a direct fiber connection" ([K15]). Dato nuevo: la diversidad se redujo desde 2018, cuando PETRA pasó a ser "the sole disruption mitigation trigger" ([S7]).

### A-18. Mensajes siempre bien formados — ✅

**JET.** JET no supone mensajes perfectos, los verifica: cada mensaje tiene un identificador único "used to allow run-time verification that all systems on a virtual circuit are coherent" ([S1] p.1296). Eso confirma que el supuesto es una brecha real, bien declarada.

### A-19. Comando igual a efecto — ✅

**JET.** La brecha entre orden y efecto es real: "no feedback signal is sent by RF plant to confirm that power supplies have been switched off" ([S6]), unos 38 ms para la radiofrecuencia.

### A-20. Un solo nivel de PTN — ✅

**JET.** Hay al menos cinco clases de PTN: "Slow, Fast, P1, Blind, Magnetic Emergency" ([N1] figura 6), y un PTN primario sólo puede ser seguido por un PTN secundario ([N1] p.14 del PDF); en la figura 7 hay PTN rápidos entre las secundarias, aunque el texto no dice explícitamente que ocurra un PTN lento seguido de uno rápido. *(corregido en v3)* Es una simplificación declarada.

### A-21. Bypass sólo en dos chequeos — ✅

**JET.** Respalda directamente la máscara: "The Level-1 user interface provides intelligent conditioning of these checks so that features or subsystems which are not in use cannot cause problems" ([S1] p.1296). Mucho más es configurable por pulso de lo que el modelo captura, y eso está declarado.

### A-22. Umbral de corriente de la válvula — ⚠️

**JET.** Los valores cambiaron con los años: 2,5 MA, 2,0 MA y 1,75 MA en 2012 ([S6]); "plasma current > 1.6 MA OR plasma energy > 5 MJ" en el ejemplo de la figura 2 de [S7] (p.2, una alarma de PETRA en el pulso #93912; traducción nuestra: corriente mayor a 1,6 MA o energía mayor a 5 MJ), con un condicionamiento que el usuario configura dentro de límites ([S7] p.4). *(corregido en v3)* El umbral se evalúa al detectar el evento, lo que coincide con "se evalúa al armar". Dos diferencias:

- el término de energía falta en el modelo, lo que es no conservador;
- en PETRA, si no se cumple la condición de una alarma, la alarma ignora sus entradas de evento, sin stop ([S7] p.3); el modelo igual manda el PTN y sólo se saltea el armado.

**Física.** Correcta. Todas las cargas de una disrupción crecen con la corriente: la energía, las fuerzas por corrientes de halo y la ganancia de avalancha de electrones desbocados, que escala como exp(2,5 × I en MA) ([IPB07-C3]). Una corriente que cae después de armar suele indicar que empezó la extinción, justo cuando la inyección ayuda. No desarmar es conservador.

**Veredicto.** Falta el término de energía.

### A-23. Configuración fija durante el pulso — ✅

**JET.** "Each pulse has bespoke protection configurations, loaded into the run-time at pulse setup" ([S3] p.6). Advertencia: [N1] menciona como desarrollo futuro que el RTPS cambie a "up to four alternative sequences" durante el pulso. Algo construido sobre eso rompería este supuesto.

### A-24. Dos relojes de fase — ❌

**Qué dice.** La tabla se lee con la fase del programa, que el JTT no toca y que sigue avanzando.

**JET.** Los dos relojes existen: el JTT adelanta el controlador de forma "to the time window corresponding to the pre-programmed termination time, ignoring any time windows in between" ([N2]). Pero ninguna fuente dice qué fase usa el RTPS para una alarma nueva después de un JTT. Lo que sí está publicado:

- la respuesta depende "as a function of pulse phase and state history" ([S3]), o sea también del historial, no sólo de la fase;
- "The stop configuration will always be the one associated with the time-window where the primary stop was issued" ([N1] p.13).

Ni la lectura del modelo, fase del programa que sigue avanzando, ni la anterior, fila de Termination, están documentadas.

**Física.** Una fila de la tabla es una aproximación del estado del plasma, y durante un stop el reloj del programa ya no describe el plasma. Caso concreto: un stop RTPS empieza en Heating 1 y el reloj avanza a Heating 2. Un punto caliente en el divertor lee ahora la fila de Heating 2, que dice JTT en lugar de PTN, y ese JTT se ignora. Frente a una tabla indexada por estado, esto es no conservador. Pero el efecto va para los dos lados. Comparado con la regla de congelar la configuración, el modelo es más débil en 4 combinaciones: un stop RTPS que empezó en Heating 1 por Slow o por MCHS y, con el reloj ya en Heating 2, un punto caliente en el divertor o en las dos zonas. Y es más fuerte cuando el reloj llega a Termination, donde Slow, MCHS, DHS y los dos puntos calientes pasan a PTN. *(corregido en v3)*

**Veredicto.** La etiqueta "neutral" no se sostiene. La regla documentada de [N1], congelar la configuración en la ventana del stop primario, resolvería A-24 y el implícito #4. *(corregido en v3)* Esa regla es del controlador de forma; aplicarla a la tabla del RTPS sería una inferencia nuestra (decisión (a) de la sección final), y en el modelo de referencia en Python congelar sola saca más escaladas a PTN de las que agrega (decisión (b)). Queda condicionado a Q1.

### A-25. Alarma ciega como columna de la tabla — ✅

**JET.** "Blind" aparece en [N1] como una clase de PTN, no como una columna de la tabla primaria del RTPS. Elegir PTN está bien fundado. La diferencia de estructura conviene anotarla.

### A-26. No existe "inhibido" — ✅

**JET.** "Inhibir" se aplica a componentes, a PINIs individuales, no a unidades enteras ([S1] p.1293). Coherente con el estado `Reduced` y con no tener `Inhibited`.

---

## Supuestos implícitos

**#1. Ventana de calentamiento fija e igual para las dos unidades — ❌.** En JET las ventanas se programan por pulso y por sistema ([S2], [S6]). La física dice que cada sistema necesita una ventana distinta: el LH se usa lo antes posible, con baja densidad; los haces necesitan densidad por PINI y corriente; la radiofrecuencia necesita densidad frente a la antena. Hay que declararlo como no conservador, en el sentido de cobertura, o pasarlo a la instancia por unidad.

**#2. Perder el plasma apaga todo en el mismo paso — ⚠️.** Ninguna fuente de JET lo trata. En física, apagar los haces de inmediato es correcto por el shine-through. Pero una caída breve del permiso, por ejemplo por un ELM, que apague todo, puede hacer perder el modo H. (El modelo sí permite volver a prender: un `HeatOn` posterior, con el permiso de vuelta y sin stop en curso, enciende la unidad otra vez, y a plena potencia aunque antes estuviera reducida; ver A-34 en el registro.) *(corregido en v3)* Es conservador sólo respecto de las cargas térmicas.

**#3. Salir de la ventana apaga; entrar a Termination baja — ✅.** Coincide con una terminación natural ([IPB99-C8]: una ventana de densidad de 0,2 a 1,0 del límite de Greenwald para bajar la corriente de forma estable).

**#4. El programa sigue avanzando de fase durante un stop — ❌.** Contradicho por JET para el controlador de forma: "Once the execution of a stop has started the timewindows are ignored until the end of the experiment" ([N1] p.12 del PDF, sobre los stops del controlador de forma anteriores a la mejora PIW; para los stops PIW, la p.13 dice que la configuración es la de la ventana del stop primario). *(corregido en v3)* No hay texto sobre el RTPS mismo, pero la regla de congelar la configuración (A-24) apunta en la misma dirección. *(corregido en v3)* Esa regla es del controlador de forma; aplicarla a la tabla del RTPS sería inferencia nuestra, y en el modelo de referencia en Python congelar sola saca más escaladas a PTN de las que agrega: ver decisiones (a) y (b). La física lo considera cuestionable (ver A-24).

**#5. "Slow" es el disparador de terminación lenta — ⚠️.** Parcialmente respaldado: el encabezado "Phase Slow MHD MCHS DHS" está confirmado ([S1] p.1295) y existe un stop PIW llamado "Slow" ([N1]). La identificación nunca está dicha de forma explícita. Las 7 leyes `pub_*_Slow` deberían etiquetarse "hecho de JET más inferencia nuestra".

**#6. "Ambos puntos calientes" es el máximo de los dos — ⚠️.** En JET, "MCHS+DHS" es un disparador propio, configurado por separado ([N1] figura 6). El máximo es un valor fabricado razonable como cota inferior, pero hay que registrarlo así y notar que depende de A-1.

**#7. Una segunda alarma local no tiene efecto — ❌.** Cada alarma saca su propio PINI ([S1] p.1295: "the relevant PINI should be turned off"), así que una segunda alarma sobre otra huella debería bajar más la potencia. La física coincide. Hay que declararlo como no conservador para la capa de protección local.

---

## Lo que el modelo no representa

Cosas que encontraron las investigaciones y que ningún supuesto cubre. No son errores: son límites que conviene declarar o decidir.

**Estructura de la protección.**

1. **Tipos de parada que faltan.** "MHD Fast", usado sobre todo como secundario, y las clases de PTN "P1" y "Magnetic Emergency" ([N1]). La cantidad de disparadores es configuración.
2. **Disparadores de la válvula sin columna en la tabla.** Picos de corriente, voltaje de lazo y variación de corriente (2011-12), y desplazamiento vertical (desde 2018). El modelo presumiblemente los asimila a "Fast"; hay que declararlo.
3. **Los actuadores también disparan el PTN.** El controlador de forma "can also trigger the stop of a JET pulse through PTN, or CISS" ([N2]), no sólo el RTPS.
4. **Sistemas de calentamiento con protección propia**, fuera del RTPS. El LH detecta arcos por su cuenta, y 4 de 16 arcos no se cortaron a tiempo y causaron disrupciones ([M13]). La radiofrecuencia se dispara sola con los ELMs ([IPB07-C6]: "trip off the RF system").

**Válvula de emergencia.**

5. **Más de un canal.** Dos válvulas, DMV1 y DMV2 ([K15]); varias salidas del PTN disparan el DMS; hay además un inyector experimental de pellets fragmentados ([S2]).
6. **La válvula se recarga a mano después de cada inyección** ([S6]): como máximo una inyección por pulso. **Esto respalda** que "disparado" sea definitivo en el modelo.
7. **Las alarmas de PETRA manejan su propia validez**: cada una tiene su alarma ciega, una salida de validez de datos y un tiempo de confirmación (20 ms en el ejemplo de [S7]; de 0 a 20 ms en la tabla 1 de [S6]). *(corregido en v3)* Relevante para A-18 y A-25.

**Física durante los stops.**

8. **La rampa de bajada también puede disruptir.** Al bajar la corriente baja el límite de densidad de Greenwald, y hay disrupciones típicas de esa etapa ([IPB99-C8]: "Two types of disruptions are observed during the plasma current ramp down"). Con la tabla publicada, donde MHD no tiene respuesta, un modo bloqueado durante un stop suave no produce nada; sólo la instancia 2 lo cubre. No hay disparador por límite de densidad, aunque JET lo monitorea para el aterrizaje suave.
9. **Escalar puede hacer daño**, y el modelo no tiene esa noción. Leyes del tipo "llegar al menos a X" pueden premiar un comportamiento físicamente peligroso.
10. **El calentamiento puede ser una acción de reparación**: en ASDEX Upgrade se sube la potencia de los haces ante un desprendimiento profundo del divertor ([IPB07-C3]).
11. **La carga en el divertor depende de la potencia y de la corriente**: el ancho de la capa de calor se achica al subir el campo poloidal ([Eich13]). Según esa escala, bajar la corriente ensancha la capa y, a igual potencia, baja el pico de flujo; [Eich13] no respalda que bajar la corriente más rápido que el calentamiento aumente el flujo. Lo que la escala no dice es cómo evoluciona el flujo en un transitorio donde cambian a la vez la corriente, la potencia y la forma, y eso el modelo no lo representa. *(corregido en v3)*
12. **El riesgo de electrones desbocados depende del campo y de q95**, no sólo de la corriente: en JET se observan "for BT > 2.2 T and q95 > 2.5" ([IPB07-C3]). El umbral de corriente es una aproximación de la carga, no del riesgo de desbocados.
13. **La inyección de gas agrega su propia carga radiada** sobre la pared, algo que importa si la pared ya está caliente.
14. **Los cambios de forma del plasma durante un stop**, como pasar a baja triangularidad ([S6]), quedan fuera del alfabeto (A-19).

---

## Acciones sugeridas, ordenadas por costo

*(Versión 3: las acciones 1, 2 y 3 están hechas; de la 4 se hizo una versión reducida de la respuesta secundaria y el resto quedó condicionado a las preguntas a JET; la 5 se convirtió en la lista de preguntas. Detalle en la sección final.)*

**1. Sólo texto del registro, sin tocar el modelo.**

- Reescribir A-3 y A-5 para que sean coherentes con A-24 y con el código.
- Corregir las etiquetas de A-2, A-8, A-11, A-12 y A-24, y especificar "conservador respecto de las cargas térmicas" en A-7, A-9 y el implícito #2.
- Registrar los siete implícitos como A-27 en adelante.
- Etiquetar las leyes `pub_*_Slow` como "hecho de JET más inferencia".
- Escapar las barras `|` de la fila de A-9.
- Agregar a la sección de fuentes [N1], [N2], [K15] y [M13], como citas, sin copiar los PDFs: [N1] dice "may not be further circulated" y [S7] dice "All rights reserved".
- Aclarar que en [S5] "RTPS" no es el secuenciador.
- Completar los tiempos de A-15.

**2. Umbral de la válvula con energía, sin tocar el código.** El modelo no mide corriente: recibe un veredicto de sí o no, el campo `ip`. Alcanza con redefinir en el registro ese veredicto como "corriente mayor a 1,6 MA **o** energía mayor a 5 MJ" y citar [S7]. Las leyes no cambian. *(corregido en v3)* En [S7] esos números son el condicionamiento de una alarma en el ejemplo de la figura 2 (pulso #93912), que el usuario configura dentro de límites (p.4); A-22 adoptó la forma "corriente o energía almacenada por encima del umbral", sin números en el modelo.

**3. Declarar en la lista corta de límites del README** el comportamiento ante una alarma durante un stop en curso, y la diferencia con la práctica documentada de JET.

**4. Cambios del modelo candidatos**, que obligan a recertificar. En la versión 3 quedan **condicionados a las preguntas** de la sección final, salvo la respuesta secundaria, que se hizo en versión reducida:

- **Congelar la configuración en la ventana del stop primario**, la regla de [N1]. Es la regla publicada más fuerte que el modelo hoy no cumple, y resolvería A-24 y el implícito #4. *(corregido en v3)* Esa regla es del controlador de forma; aplicarla a la tabla del RTPS sería una inferencia nuestra (decisión (a)), y en el modelo de referencia en Python congelar sola saca más escaladas a PTN de las que agrega (decisión (b)). Queda condicionado a Q1.
- **Modelar la respuesta secundaria**: como máximo dos stops suaves seguidos, con PTN lento como secundaria por defecto, la más usada según la figura 7 de [N1] (estadística de uso, no regla). *(corregido en v3)* La tabla completa no está publicada, pero se podría dejar como parámetro de la instancia.
- **Pasar a la instancia** las ventanas de calentamiento, por unidad, y la ventana de la válvula.
- **Contar las reducciones locales** por unidad, para que una segunda alarma tenga efecto.

**5. Confirmar con alguien de JET o UKAEA**, en este orden (en la versión 3 esto se convirtió en las preguntas Q1 a Q9 de la sección final):

- qué configuración responde a una alarma nueva después de un JTT;
- qué pasa si la confirmación del calentamiento nunca llega;
- si un punto caliente en el divertor durante un stop RTPS dispara una secundaria.

---

## Estado tras la corrección (2026-09-22)

Esta sección dice qué se hizo con la evaluación de arriba. La evaluación queda como estaba, salvo los pasajes marcados *(corregido en v3)*, para que se vea la historia; la columna "Tras corregir" del resumen muestra el veredicto nuevo.

### Qué se corrigió en el texto

- **El registro** (`phase3-sources.md` §4, revisión 4). Se reescribieron A-3, A-5, A-16, A-22 y A-24. Se corrigieron las etiquetas de dirección de A-1, A-2, A-6, A-7, A-8, A-9, A-11, A-12, A-16 y A-24, y ahora cada etiqueta dice respecto de qué es conservadora: cargas térmicas sobre la pared, cargas de una disrupción, equipo de calentamiento o cobertura. Los siete implícitos quedaron registrados como A-27 a A-33, y hay dos supuestos nuevos, A-34 y A-35. Se agregaron [N1], [N2], [K15], [M13] y las referencias de física como citas, sin copiar los PDFs. También se aclaró el choque de siglas de [S5], se completaron los tiempos de A-15 y se escaparon las barras de la fila de A-9.
- **El umbral de la válvula** (A-22). El veredicto `ip` se redefinió como "corriente **o** energía almacenada por encima del umbral". El código y las leyes no cambian, porque hablan de un booleano (un valor de sí o no).
- **Los otros documentos.** `phase3-design.md`, `phase3-safety.md`, `phase3-traceability.md`, los dos README y los tres catálogos de leyes. En los catálogos, cada ley dice ahora si lo que afirma es un hecho que JET documenta o una política nuestra.
- **Este documento.** Las dieciséis correcciones de la revisión del registro: citas mal atribuidas (por ejemplo, los 30 ms del haz de litio son de [S6], no de [K15]) y alcances exagerados (por ejemplo, el tope de [N1], "a maximum of two in sequence", como máximo dos seguidas, que el modelo ya cumple). Una auditoría posterior, del mismo día, encontró que esas correcciones se habían escrito sobre el texto sin marca, y agregó otras: la conclusión 1 presentaba como reglas de JET lo que en [N1] es un mecanismo y una estadística de uso; las conclusiones 1 y 4 no avisaban qué cambió con la revisión 4; la condición de PETRA ([S7]) figuraba dos veces traducida entre comillas, como si fuera la cita; y la columna "Tras corregir" no aplicaba parejo su propio criterio. Cada pasaje corregido de la evaluación lleva ahora la marca *(corregido en v3)*.

### Qué cambió en el modelo

**1. Cinco leyes nuevas para lo que P1 y D1 dicen sobre el PTN y el stop primario.** Hasta ahora, lo que JET documenta sobre el PTN estaba mezclado, dentro de P1 y D1, con nuestra política entre los dos stops suaves (JTT y RTPS). Ahora esa parte tiene leyes propias, que se pueden citar sin arrastrar esa política. Dos reformulan fuentes de JET (`p1a_ptn_latched`, `d1b_primary_honoured`); las otras tres juntan un enunciado de JET con una formalización nuestra, y se etiquetan como mixtas (corrección de una auditoría posterior del mismo día):

- `p1a_ptn_latched`: un PTN, una vez disparado, queda trabado hasta el fin del pulso. La salida del PTN es una señal trabada (R-0: "The PTN output is a latched stop signal"), y [N1], p.14 del PDF: "a PIW stop can never preempt a PTN stop" (traducción nuestra: un stop PIW nunca desplaza a un stop PTN; que los stops PIW sean los stops suaves del modelo es identificación nuestra, A-1).
- `p1b_stop_never_cleared`: un stop en curso, suave o PTN, no vuelve a "sin stop" salvo con el fin de pulso. Mixta. Para el PTN, la salida trabada (R-0). Para los stops suaves es lectura nuestra: ninguna fuente publica una forma de cancelar un stop (A-14, un argumento por ausencia) y [S1] presenta los stops como la manera de terminar el pulso (R-8). El "allowing it to run to completion" de R-6 habla de no pasar a una secundaria, no de borrar un stop. No es una frase de [N1].
- `d1a_ptn_honoured`: un pedido de PTN se atiende desde cualquier estado, también con un stop suave en curso, y deja las dos unidades de calentamiento apagadas. Mixta. [N1], p.13 del PDF: los stops PTN "can be triggered even after a PIW stop is in execution" (traducción nuestra: se pueden disparar aunque ya se esté ejecutando un stop PIW). Que las dos unidades queden apagadas en el mismo paso es A-9: está documentado para las salidas del PTN que disparan el DMS (R-11), para las demás sólo como la "fixed shutdown sequence" de R-0.
- `d1b_primary_honoured`: sin stop en curso, un pedido suave (JTT o RTPS) pasa a ser la respuesta, o sea, el stop primario se atiende. Respaldo: la tabla primaria (R-5) y [N1], p.13 del PDF: "RTPS will select the stop and send it to SC".
- `piw_after_ptn_is_noop`: con el PTN trabado, un pedido que no es PTN no cambia nada, tampoco los contadores. Mixta. [N1], p.13 del PDF, llama "invalid task" (tarea inválida) a pedir un stop PIW "after a PTN stop was already being executed", en las pruebas de aceptación del simulador del controlador de forma. Que ese pedido no cambie nada en el paso del RTPS, tampoco los comandos a los contadores, es formalización nuestra (A-14), y es justo la parte que la hace no derivada.

Cuatro de las cinco son **derivadas**: son casos con nombre de P1, D1, P2 y las leyes de marco, así que no cuentan como evidencia independiente. La quinta, `piw_after_ptn_is_noop`, resultó no ser derivada: ninguna ley anterior prohibía que el contador del vigía de latido sumara un tic ante un stop con el PTN ya trabado. Se nota en la medida de ajuste: los comandos a los contadores quedan fijados en 243 de las 400 celdas de la muestra, contra 212 antes.

El tope de [N1], "a maximum of two in sequence" (p.13 del PDF; traducción nuestra: como máximo dos seguidas; que sean dos stops suaves es lectura nuestra), **no** es una ley aparte. Con dos niveles suaves y un orden estricto se cumple por construcción, y presentar esa propiedad del modelo como prueba de la regla de JET sería exagerar. Queda anotado en A-2.

**2. La respuesta secundaria, como parámetro de cada instancia.** El mecanismo primario/secundario sí está documentado: [S1] habla de "two levels of stop response, primary, and secondary" (R-6). Lo que no está publicado es el contenido de la tabla secundaria. Por eso:

- Una alarma que llega con un stop ya en curso lee ahora una **tabla secundaria** propia de la instancia, `sec_table`, en vez de la primaria. Se lee en la fase de programa, que sigue avanzando: no se congela nada.
- Las **instancias 1 a 3** conservan la lectura de antes: su tabla secundaria es otra vez la primaria, combinada por el máximo. Sus números no cambian (por ejemplo, siguen teniendo 804 estados alcanzables en la capa concreta).
- Una **instancia 4 nueva**, igual a la 1 en todo lo demás, usa una tabla secundaria **ilustrativa**: PTN donde la primaria pide alguna respuesta, nada donde no pide nada. Se inspira en la figura 7 de [N1] ("The preferred secondary plasma stop is the PTN slow stop", p.23 del PDF), que es una estadística de uso y no la tabla de JET. Está declarada como contenido inventado, A-35. En esta instancia, el caso de A-16 (un punto caliente en el divertor durante un stop RTPS, con la fase en Heating 2) da PTN, y hay una ley que lo certifica: `inst4_second_alarm_ptn`.
- La capa abstracta no cambió: ni el paso, ni el orden, ni P1, ni D1, ni las leyes de respuesta acotada, ni las de solidez. El certificado sigue siendo de 462 336 celdas por orden.

Una advertencia honesta. El teorema de seguridad ya valía para **cualquier** pedido de stop, así que decir "la seguridad vale con las dos lecturas" es casi automático. Lo que esta parte agrega de verdad es otra cosa: el mecanismo documentado, controlado por leyes de conformidad; una demanda concreta certificada en la instancia 4; y el contenido de la secundaria como un parámetro explícito y declarado, en vez de estar escondido en el máximo de D1. Y más autoridad no es necesariamente más seguridad: un PTN secundario puede provocar la disrupción que se quería evitar, y en la instancia 4 los PTN secundarios de Slow, MCHS, DHS y los dos puntos calientes no arman la válvula (A-35).

**3. Resultado del gate.** `py -3.14 v3/run.py all --full` pasó el 2026-09-22 con todas las etapas bien ("all: ok in 7305.5 s", unas dos horas). Los números:

- leyes: 81 en `LAWS_JETPROT.bend` (antes 75), 143 de conformidad (antes 137), 2 de respuesta acotada y 8 de solidez; 234 en total (antes 222);
- 12 tests negativos, todos rechazados como corresponde (antes 10);
- 75 de 76 mutantes muertos; el único sobreviviente es M06, un mutante equivalente (en esta corrida el gate todavía lo aceptaba por su nombre; desde el 2026-09-23 calcula la equivalencia, ver la nota que sigue);
- estados alcanzables en la capa concreta: 804 en las instancias 1, 2 y 3, y 744 en la 4, todos dentro del invariante;
- testing diferencial: 88 corridas. Cinco combinaciones de defecto plantado e instancia no se pueden observar por construcción, y el gate las declara. Antes de la revisión 4 había una sola (la falla de comunicación en la instancia 3). Cuatro son nuevas: el defecto nuevo de secundaria ignorada no se ve en las instancias 1 a 3 (su secundaria es la primaria), y en la instancia 4 no se puede ver un defecto de "des-escalada", porque bajo un stop toda alarma pide PTN o nada.

### Nota del 2026-09-23: Bend 2.0.25, el gate en paralelo y la equivalencia calculada

Después de esta evaluación cambiaron el compilador y el gate. El modelo y las leyes no cambiaron: en sus archivos sólo se corrigieron comentarios.

- **Bend 2.0.25.** El pin pasó de 2.0.24 a 2.0.25 (commit `c65bcb78…`, tag `v2.0.25`; detalle en `env/SETUP.md`). Para el verificador, la versión nueva cierra dos agujeros en cómo se chequean los literales: un archivo que declaraba su propio `Nat` podía aceptar `1n` por el nombre y derivar un `Empty` cerrado (#941), y un conteo de arreglo por encima del tope de los naturales armaba un literal fraccionario que burlaba el chequeo de terminación (#954). Ninguno de los dos alcanza a este proyecto, ni con el pin viejo ni con el nuevo: no declara tipos propios `Nat` ni `String` y no usa arreglos. Bend 2 es nuevo: la versión 2.0.0 salió el 2026-09-17, y la 2.0.25 es la número 26 en cinco días (`CHANGELOG.md` de Bend; `phase3-safety.md` §5).
- **El gate en paralelo.** `run.py` y `recheck.py` aceptan `--jobs N` y corren las etapas en paralelo; `--jobs 1` es el camino serial de siempre. Con Bend 2.0.25, `py -3.14 v3/run.py all --full` pasó el 2026-09-23 ("all: ok in 1728.9 s" y "all: ok in 1299.8 s") y, después de las últimas correcciones del día (comentarios, docstrings y la comparación de `concretize` de la nota que sigue), otra vez: "all: ok in 1199.8 s", de las 09:26 a las 09:46 (un primer intento, lanzado a las 06:17, se cortó cuando se reinició la máquina y no escribió resultados). Después de las correcciones de cierre del mismo día (entre ellas, el chequeo exacto de la versión de Bend en `env/check_env.sh`, la validación de `--update` en `env/bend.sh` y la descripción de M65), pasó una vez más: "all: ok in 1306.1 s", de las 11:12 a las 11:34; contra la de las 09:46 cambian sólo los tiempos, los datos de la corrida, los hashes de los archivos editados en el medio y la descripción de M65. Tras un último cambio en `env/bend.sh` (ya no baja Bend a un directorio que no está vacío y no tiene un checkout de Bend) pasó otra vez: "all: ok in 1226.0 s", de las 12:01 a las 12:22; contra la de las 11:34 cambian sólo los tiempos, los datos de la corrida y el hash de `env/bend.sh` (el de `v3/run.py`, también editado, no se compara). Después de corregir un comentario en la cabecera de `v3/LAWS_JETPROT_LIVE.bend` (las dos cotas de respuesta se chequean sólo para los límites del modelo, `hb_max` = 3 y `ack_max` = 2), pasó una última vez: "all: ok in 1222.4 s", unos 20 minutos, contra "all: ok in 7305.5 s" en serie el 2026-09-22. Esa última, de las 12:52 a las 13:13, es la corrida de referencia que queda en el repositorio; contra la de las 12:22 cambian sólo los tiempos, la marca de tiempo de la corrida y el hash de `v3/LAWS_JETPROT_LIVE.bend`. `v3/compare_runs.py` la comparó hoja por hoja con la serial (6 433 hojas): los veredictos, los recuentos de arriba, el censo de mutantes y las trazas del testing diferencial son los mismos. Aparte de los tiempos y de los datos de la corrida, cambian sólo la versión de Bend, los hashes de los archivos editados en el medio (17 entradas del gate, más los dos scripts del gate), el campo nuevo de la equivalencia y la descripción de cinco mutantes (M63, M64, M65, M67 y M68), que citaban mal el número de supuesto.
- **La equivalencia de M06, calculada.** Antes el gate aceptaba al único sobreviviente por su nombre, y la cuenta "difiere del modelo en 0 celdas" se había hecho aparte. Ahora el gate compara, para cada sobreviviente, el paso y los dos comandos a los contadores con los del modelo en las 924 672 celdas del certificado, el paso con los contadores en 12 042 240 celdas con valores concretos de los contadores, y la traducción de los eventos de planta (`concretize`) en 1 032 192 celdas (instancia, estado de control, evento de planta); falla si difiere en alguna. M06 difiere en 0 en las tres cuentas (`C6.equivalence` en `results.json`). La tercera cuenta se agregó el mismo día: dos mutantes de prueba de `concretize` (una alarma que se pierde con el NB prendido; el bit del DMS que se pierde sin plasma) pasaban todas las leyes del oráculo en Python y coincidían con el modelo en las dos primeras cuentas, así que se habrían aceptado como equivalentes; con la tercera difieren en 18 144 y 50 688 celdas y se rechazan (`phase3-design.md` §9a H39).
- **Leyes derivadas y etiquetas.** La lista canónica `DERIVED` (`pymodel/jetprot_laws.py`) tiene ahora las doce leyes derivadas, P4 y P6 incluidas; ningún gate la lee. Con la misma regla de los catálogos, cuatro leyes cambiaron de etiqueta de origen: `dms_no_heat` pasó de hecho de JET a mixta, y `dms_monotone`, `dms_frame` y `f3b_commfault_masked_is_noop`, de supuesto a mixtas. El recuento queda en 44 de JET, 140 supuestos, 32 mixtas y 18 técnicas (`LEYES_CATALOGO.md` §0).

### Decisión (revisión 4 del registro, versión 3 de este documento, 2026-09-22)

(a) **No se congela la tabla** (el cambio que la versión 2 llamaba "congelar la configuración"). La frase de [N1] es "The stop configuration will always be the one associated with the time-window where the primary stop was issued" (p.13 del PDF; traducción nuestra: la configuración del stop es siempre la de la ventana de tiempo en la que se disparó el stop primario). Esa regla es del controlador de forma, y la misma página dice que el que elige la respuesta es el RTPS: "RTPS will select the stop and send it to SC". Aplicarla a la tabla del RTPS sería una inferencia nuestra.

(b) Medido en el modelo de referencia en Python (no es una demostración), congelar sola **saca más escaladas a PTN de las que agrega**: se pierden las de la fila de Termination y se ganan las de un punto caliente después de pasar de Heating 1 a Heating 2. Con la tabla secundaria PTN de la instancia 4, congelar no cambia nada observable en el modelo de referencia en Python (0 de 144 escenarios de dos alarmas; lo observable es el nivel, el DMS y las dos unidades después de la segunda alarma); en las instancias 1 a 3, que conservan la lectura anterior, congelar cambiaría 40 de 144 en cada una (36 escaladas a PTN perdidas, 4 ganadas). Y agregaría un mecanismo que JET no documenta para el RTPS.

(c) **Qué se ignora hoy.** En las instancias 1 a 3, las alarmas que llegan durante un stop suave y se ignoran se reducen a 7 casos distintos por instancia. Seis son el mismo nivel pedido de nuevo. Uno es un pedido menor: un stop RTPS, con la fase de programa en Heating 2, y después un punto caliente en el divertor, que esa fila manda a JTT.

(d) **El mecanismo primario/secundario**, que sí está documentado ([S1]), es ahora un parámetro de la instancia. Las instancias 1 a 3 conservan la lectura de antes. La instancia 4 usa el PTN como secundaria donde la primaria pide alguna respuesta (y nada donde no pide nada), con la etiqueta de ilustrativa (A-35).

(e) **Lo que P1 y D1 dicen sobre el PTN y el stop primario queda en leyes con nombre** (las cinco de arriba: dos de hecho de JET y tres mixtas). El tope "a maximum of two in sequence" ([N1], p.13 del PDF; como máximo dos seguidas) se cumple por construcción si se lee como dos stops suaves, que es lectura nuestra, y queda anotado en A-2, no como ley.

### Qué quedó diferido, y por qué

- **Congelar la fase o la fila de la tabla en el stop primario**, en todas sus variantes (también con un registro aparte de la ventana congelada). Motivos en (a) y (b). Pregunta Q1.
- **El contenido de la tabla secundaria de JET**, y una versión completa con un campo nuevo en el estado. La tabla se diseña por pulso y no está publicada; la frase de la figura 7 de [N1], "The preferred secondary plasma stop is the PTN slow stop" (p.23 del PDF; traducción nuestra: el stop secundario preferido es el PTN lento), es una estadística, y 111 de 420 secundarias fueron stops suaves ([N1], p.14 del PDF). Preguntas Q2, Q3 y Q4.
- **Contar las reducciones locales**, y una ley de trazas "la reducción dura todo el pulso". El modelo olvida la reducción al pasar por `Off` (A-34), y contar reducciones es una inferencia de [S1] p.1295. Costaría del orden de 1,56 veces más celdas para una sola ley de demanda. Queda declarado en A-33 y A-34. Pregunta Q5.
- **Que el vigía de latido y la falla de comunicación armen el DMS.** Ninguna fuente lo dice. La elección actual (no lo arman) quedó re-etiquetada como un compromiso, no como algo conservador (A-12). Pregunta Q6.
- **La ventana de la válvula como dato de la instancia.** No hay valores publicados por pulso, y tomar al pie de la letra la ventana de [S6] impediría armar el DMS después de un JTT, porque el modelo la lee en la fase de la forma de onda. Queda como límite en A-10. Pregunta Q7.
- **Ventanas de calentamiento por unidad y por instancia.** Los valores no están publicados, y el cambio agrandaría el alfabeto (de 43 a 48 columnas) y tocaría el invariante I1. Queda como límite en A-27. Pregunta Q8.
- **La semántica de PETRA**: si no se cumple la condición de una alarma (en el ejemplo de [S7], corriente o energía), la alarma ignora sus entradas de evento, sin stop ([S7] p.3). La diferencia está registrada en A-22; el modelo igual emite el PTN, que es conservador para el stop. Pregunta Q9.

### Preguntas abiertas para JET/UKAEA (y qué haríamos con cada respuesta)

Las preguntas van en inglés, tal como se mandarían. Destinatarios: De Tommasi y Neto, por la interfaz entre el RTPS y el controlador de forma ([N1], [N2]), y Stephen, por el Stop Selector ([S1]). Q4 es la decisiva para el contenido de la tabla secundaria.

**Q1.** "When a new alarm reaches the RTPS Stop Selector while a PIW stop (JTT or RTPS) is already running, which phase row does the Selector use to look up the response: the phase in which the primary stop was issued, the current programme phase, or neither (a separate secondary configuration that ignores the phase)?"

- La fase del stop primario: habría que congelar la lectura (dejar de avanzar la fase bajo un stop suave, o guardar aparte la ventana congelada). Toca el paso abstracto, `advance_fin` y las leyes de respuesta acotada; se re-prueba todo, horas de gate.
- La fase actual del programa: nada; es lo que el modelo hace hoy, y A-24 pasa a estar respaldado.
- Ninguna de las dos (una configuración secundaria aparte): ya está cubierto por `sec_table`; sólo cambia el contenido (Q2, Q4).

**Q2.** "For a divertor hot-spot (DHS) alarm arriving during an RTPS stop in the main heating phase, what secondary stop was typically configured: PTN slow, PTN fast, a PIW stop, or none (let the primary run to completion)?"

- PTN: la instancia 4 queda respaldada para ese caso.
- Ninguno: las instancias 1 a 3 quedan respaldadas.
- Un stop suave: hace falta una secundaria suave, que la instancia 4 no puede expresar; sería otra instancia con otra tabla. En todos los casos el costo es sólo la capa concreta y las leyes de conformidad; el certificado abstracto no cambia.

**Q3.** "After two PIW stops in sequence, is a third PIW request refused, or converted to a PTN?"

- Rechazado: nada; el modelo ya no admite un tercero.
- Convertido en PTN: sólo importa si se agrega una instancia con secundarias suaves, y se escribe en la tabla de esa instancia.

**Q4 (la decisiva).** "Does a re-assertion of the same alarm that triggered the primary count as 'the primary stop fails to mitigate the event' and start the secondary, or is the secondary triggered only by a different or higher-priority event?"

- Cuenta: la regla de la instancia 4 (repetir la alarma lleva a PTN) queda respaldada.
- Sólo cuenta otro evento, o uno más prioritario: el modelo tendría que recordar qué disparador inició el stop primario. Eso es un campo nuevo en el estado de control, que multiplica las celdas del certificado por la cantidad de valores que tome, y obliga a re-probar todo. Además, sin tiempo, el modelo no distingue una alarma nueva de una que sigue activa.

**Q5.** "When local protection takes a PINI (or an ICRF antenna) out after a hot-spot alarm, does that PINI stay excluded for the rest of the pulse even if the whole NB (or RF) system is switched off and on again, and does a second hot-spot alarm on another footprint take out a second PINI?"

- Queda afuera, y cada alarma saca otro: contar las reducciones y recordarlas a través de `Off` (A-33, A-34); del orden de 1,56 veces más celdas y una ley de trazas nueva.
- Vuelve al prender la unidad: A-34 queda respaldado; sólo cambia el texto.

**Q6.** "Did the PTN stops triggered by the RTPS–shape-controller communication loss or by the RTPS watchdog also trigger the Disruption Mitigation valve, or only the heating/power shutdown?"

- Sí: cambiar dos constantes (`dms_on_commfault`, `dms_on_watchdog`) y sus leyes de conformidad. Barato: sólo la capa concreta.
- No: nada; A-12 queda respaldado.

**Q7.** "Was the DMV enable window typically kept open through the termination (ramp-down) phase, and was it evaluated on the programmed time or on the actual termination waveform after a jump to termination?"

- Abierta en la terminación y evaluada en la forma de onda: nada.
- Cerrada antes, o evaluada en el tiempo programado: pasar la ventana a la instancia y decidir en qué fase se lee. Capa concreta y leyes de conformidad.

**Q8 (opcional).** "Were the PEWS heating time windows programmed per heating system (NB, ICRF, LH) and per pulse, and was early heating in the current ramp-up protected by the same permissive logic?"

- Sí: ventanas por unidad y por instancia. Cambia el alfabeto (de 43 a 48 columnas) y el invariante I1; recertificación completa.

**Q9 (opcional).** "Before PETRA, when the plasma current was below the DMV threshold, did the RTPS still issue the PTN stop for a Fast/locked-mode alarm, with only the valve injection suppressed?"

- Sí: nada; es lo que el modelo hace.
- No: cambia la regla del stop en la capa concreta (el veredicto `ip` también filtraría el stop).

**Regla con fecha.** Si no hay respuesta para cuando se reescriba el preprint, la tabla secundaria parametrizada queda como está, con su etiqueta de ilustrativa, y congelar la tabla sola no se publica nunca. La misma regla está en `TODO.md`.
