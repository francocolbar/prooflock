# Modelos de referencia verificados para lógica de protección de máquina: un caso de estudio sobre la cadena de protección de la pared de JET

**Borrador de preprint, revisión 1 (2026-09-19).** Idioma de trabajo castellano; la versión para arXiv (cs.SE / cs.LO,
con cross-list a physics.plasm-ph) se traduce al inglés al cierre. Los números de esta versión salen de
`v3/results.json` y `v3/recheck.json`; las citas [S1]–[S7] son las de `v3/docs/fase3-fuente.md`.

## Resumen

Presentamos un método para escribir la lógica discreta de un sistema de protección de máquina como un modelo total y
ejecutable cuyas propiedades se prueban con un verificador de pruebas para toda secuencia de eventos y para toda
configuración, y para usar ese modelo como oráculo de referencia contra la implementación real. La idea técnica es
partir el estado en un control finito y contadores gobernados por comandos, decidir toda propiedad del control por
cómputo sobre el dominio completo —un certificado de 104 832 celdas por orden de urgencia que el verificador evalúa en
segundos— y elevar el resultado a leyes universales por reflexión, de modo que el esfuerzo de prueba no crece con el
tamaño del control. Lo aplicamos a una reconstrucción, desde publicaciones abiertas, del *Stop Selector* del Real-Time
Protection Sequencer de JET, su interfaz con el Pulse Termination Network y el armado del sistema de mitigación de
disrupciones: 2 688 estados de control, 24 variantes de evento, 64 leyes probadas —incluido el teorema de que ninguna
traza sale del conjunto seguro, para cualquier matriz de configuración y para los dos órdenes de urgencia posibles—
más 117 leyes de conformidad con la configuración publicada.

El resultado que consideramos más transferible no es el caso de estudio sino un hallazgo metodológico negativo. Un
conjunto de leyes de seguridad —propiedades de la forma "nada malo pasa"— **lo satisface el modelo que no hace nada**,
y ninguna cantidad de leyes ni de celdas certificadas revela eso. Una revisión adversarial construyó ese modelo
degenerado contra nuestra primera versión y lo hizo pasar, junto con el gate de vacuidad que habíamos escrito
justamente para detectarlo. La respuesta fueron 29 leyes de demanda y de marco, y dos medidas que sí ven la
diferencia: el **ajuste** del conjunto de leyes (cuántos de los 2 688 estados siguientes admiten, en promedio: 15 antes,
1,1 después) y un **banco de mutantes adversarial** escrito por revisores cuyo encargo era romperlo (21 de 37 defectos
detectados antes, 61 de 62 después; el único sobreviviente es demostrablemente equivalente). Un puntaje de mutación
contra un banco escrito junto con las leyes daba 17 de 17 desde el principio y no distinguía nada.

La evidencia se completa con diez tests negativos que el verificador rechaza con contraejemplo —incluido uno que
afirma el certificado falso, para mostrar que se computa y no se saltea—, un re-chequeo independiente celda por celda
del certificado desde otro lenguaje, y testing diferencial contra una implementación con seis defectos plantados. La
función modelada es protección de inversión, no una función de seguridad nuclear; la evidencia es sobre una
especificación, no sobre un sistema, y no sostiene ningún reclamo de SIL. Discutimos qué establece y qué no el teorema
de trazas en términos de IEC 61508. Las especificaciones, los modelos y las pruebas fueron escritos por un sistema de
IA dirigido y auditado por un autor humano, con el verificador como juez de toda afirmación bajo ley; las cinco rondas
de revisión adversarial fueron también automatizadas y **no** constituyen evaluación independiente.

## 1. Introducción

*(Por escribir en la versión final; aquí el argumento.)* Los sistemas de protección de máquina de los grandes
experimentos de fusión (JET, ASDEX Upgrade, KSTAR, ITER) combinan una capa cableada de secuencia fija con una capa
programable cuya lógica de respuesta se configura por pulso. La evidencia publicada de su validación son pruebas de
comportamiento por casos: [S3] describe 71 *pulse schedules* como pruebas del RTPS de JET, y [S6] documenta 5 + 4 + 7
disrupciones perdidas en 2011–2012 por inhibiciones, ventanas mal configuradas y umbrales de corriente. La combinatoria
de fases, disparadores, orden de llegada, fallas de comunicación, watchdog y contadores supera por órdenes de magnitud a
cualquier conjunto de pruebas por casos, y la matriz cambia por pulso. Las plantas de fusión de potencia y la industria
nuclear en general van a tener que presentar evidencia de la capacidad sistemática de este software a un regulador; la
pregunta es qué forma puede tomar esa evidencia para que sea exhaustiva sobre la lógica, barata de rehacer por
configuración, y honesta sobre lo que no cubre.

## 2. Método

### 2.1 Control finito y comandos a contadores

El estado es `St = Fin × ℕ × ℕ`, con `Fin` un producto de enumeraciones (fase, respuesta en curso, secuencia del DMS,
condiciones de plasma, dos unidades de calentamiento) y dos contadores (ciclos sin heartbeat, ciclos esperando el
acuse del DMS). Los contadores nunca entran al control: entran sus *veredictos* (`1 + n < límite`, dos booleanos) y el
control responde con comandos `Keep | Reset | Inc`. Toda decisión es entonces finita.

### 2.2 Certificado por cómputo y reflexión

Para cada celda (orden de urgencia, estado de control, evento abstracto, veredictos) se computa el estado siguiente una
vez y se evalúan sobre él la preservación del invariante, las "formas" de los comandos a los contadores y las 48 leyes
de paso. La conjunción sobre el dominio —2 688 estados × 39 columnas = 104 832 celdas por orden— es una sola igualdad
`check_fin(o) == True` que el verificador decide por normalización. Una escalera de lemas, uno por nivel de
cuantificación, extrae de ese booleano la celda arbitraria; las proyecciones dan cada ley; un lema genérico de
contadores da los invariantes de los contadores para todo valor; la inducción en la traza da el teorema. El costo de
prueba es casi constante en el tamaño del control: agregar un evento o un estado agrega un brazo a un lema de nivel.

Dos detalles de implementación que no son detalles. **Primero**, los veredictos de los contadores se enumeran solo en
las cinco columnas donde el verificador no puede descartarlos simbólicamente; que las otras diecinueve no los lean era
una suposición verificada una vez a mano, y ahora es una ley probada. **Segundo**, la escalera no proyecta desde el
certificado entero sino desde 56 rebanadas decididas por cómputo, porque el verificador compara formas normales
completas: nombrar el certificado en un tipo cuesta evaluarlo de los dos lados de la comparación (§4).

### 2.3 Configuración como carga del evento

La matriz fase × disparador → respuesta y la conexión del DMS no están dentro del paso: el alfabeto abstracto lleva la
respuesta pedida y el bit de DMS en el evento, y una capa concreta mapea el alfabeto de la planta a través de una
instancia de configuración. Las leyes valen entonces para toda configuración; la instancia publicada entra por 117
leyes de conformidad —una por celda, separadas en publicadas (28, de las que 15 impresas y 13 leídas de marcas "ídem")
y supuestas (21)—, más dos leyes sobre la capa concreta: que `concretize` es la configuración valor por valor, contra
una transcripción literal de la matriz, y que `step_c` la usa con la instancia, el orden y la fase correctos.

### 2.4 Lo que juzga el verificador y lo que juzga otra implementación

Todo lo que está bajo ley lo decide el verificador. Lo que no puede estar bajo ley —que las leyes no sean vacuas, que
el certificado se compute, que el modelo coincida con la prosa, que la implementación real coincida con el modelo— lo
decide una segunda implementación en otro lenguaje: re-chequeo celda por celda de las 209 664 celdas del certificado,
re-evaluación de cada ley sobre los estados siguientes que produce el modelo verificado, alcanzabilidad abstracta y
concreta, conteo de celdas donde la hipótesis de cada ley vale, la métrica de ajuste, el banco de mutantes, y testing
diferencial contra una implementación de producción con defectos plantados.

**Una advertencia sobre esa segunda implementación, porque nos equivocamos al describirla.** La nuestra se escribió
después del modelo verificado y con él a la vista: es una **re-ejecución en otro lenguaje**, no una implementación
N-versión independiente, y así hay que leer lo que su coincidencia demuestra (protege contra errores del evaluador,
no contra un malentendido compartido de la especificación). Una auditoría lo detectó por evidencia textual —nuestro
modelo "independiente" contenía una ley que el documento de diseño no menciona— y produjo, esa sí, una transcripción
independiente desde el documento, que coincide en toda celda alcanzable.

## 3. Caso de estudio: la cadena de protección de la pared de JET

### 3.1 Fuente y alcance

[S1] publica el *Stop Selector* del RTPS: siete fases, siete disparadores, tres respuestas (PTN, RTPS stop, JTT), la
Tabla 1 (una configuración de ejemplo, "the primary stops table"), respuesta primaria/secundaria, protección local,
alarmas ciegas y watchdog. [S2] agrega el enclavamiento de la salida del PTN, la secuencia del DMS (apagar calentamiento
→ acuse o timeout → inyectar), la jerarquía de escalada y las ventanas de habilitación. [S6] agrega la regla "el DMV se
puede conectar a cualquier parada enviada al PTN", la ventana y los umbrales del DMV, los tiempos (NBI 2 ms, RF 38 ms,
50 ms en total, sin acuse de RF) y el registro de disrupciones perdidas. Se modela el Stop Selector con su interfaz al
PTN y el armado del DMS; **no** el Stop Manager (las formas de onda de sobreescritura a los cinco actuadores), ni las
capas de seguridad CISS/PSACS. Dieciséis requisitos textuales (R-0…R-15) y veintitrés hipótesis declaradas (A-1…A-23) con
su dirección de conservadurismo están en el material suplementario.

### 3.2 Modelo y leyes

*(Detalle en `v3/docs/fase3-diseno.md` §2.)* El invariante tiene seis cláusulas: una unidad a potencia plena está en la
ventana de habilitación, con condiciones de plasma y sin parada en curso; una unidad en rampa está bajo una parada
blanda o en la terminación y nunca bajo PTN; un JTT en curso implica fase de terminación; el DMS solo se arma o dispara
bajo PTN; la espera del acuse y los ciclos sin heartbeat están acotados. Veintiuna leyes de paso dicen qué no puede
pasar —las paradas no se degradan, el paso que llega al PTN des-energiza, ninguna orden enciende nada con una parada en
curso, el DMS se arma solo ante una demanda, bajo PTN el programa no avanza— y veintinueve leyes de demanda y de marco
dicen qué tiene que pasar: una petición de parada se honra, una parada blanda rampa el calentamiento, el watchdog
enclava independientemente de cómo esté cableado el DMS, un heartbeat siempre reinicia su contador, el fin de pulso se
acepta cuando corresponde, y cada comando toca lo suyo y nada más. El teorema `traces_safe` cubre toda traza sobre el
alfabeto abstracto —es decir, para cualquier configuración— y su corolario concreto, las dos instancias certificadas.

### 3.3 Resultados

| Artefacto | Resultado |
|---|---|
| Certificados (`finite_check`, `finite_check_alt`, `corollaries_check`) | 104 832 celdas por orden + 2 688 estados; 14–19 s y 0,3 s en el verificador |
| Leyes por reflexión e inducción | 64 en `PROOF_JETPROT.bend` (1 034 líneas de código), 143 s |
| Conformidad de la configuración | 117 leyes, `{==}` por celda, 0,3 s |
| Tests negativos | 10/10 rechazados con contraejemplo; el gate exige que el verificador refute un `Bool` **y** nombre la ley |
| Re-chequeo independiente | 209 664 celdas Bend = Python; 0 discrepancias; alcanzabilidad concreta 921 estados, todos en el invariante |
| Vacuidad y **ajuste** | ninguna ley vacua; 374/400 celdas alcanzables con sucesor único (93,5 %), 1,1 admisibles de 2 688 |
| Sensibilidad | 2 688 celdas difieren entre los dos órdenes de urgencia, 168 alcanzables; todas las leyes valen en ambos |
| **Mutación adversarial** | **61/62**; el único sobreviviente difiere del modelo en 0 celdas (equivalente). El banco escrito junto con las leyes: 17/17, reportado como la medida débil |
| Testing diferencial | 6 defectos × 2 instancias × 2 generadores: 14/16 configuraciones con defecto detectadas, 0 falsos positivos; el generador guiado los encuentra todos con trazas de 2–10 eventos, el aleatorio pierde varios en 3 000 |
| Gate completo | `py -3.14 v3/run.py` → `all gates and checks ok: True`, ≈ 5–6 min |

### 3.4 Lo que encontraron las revisiones

Cinco rondas adversariales, tres sobre el diseño antes de escribir código y dos sobre el conjunto de leyes ya probado.
Las primeras encontraron un campo de estado inalcanzable con su ley vacua, un invariante no inductivo por tres caminos,
una ley de paso falsa en celdas inalcanzables (dos veces, porque es natural escribir "X(s′) implica Y(s′)" donde lo
correcto es "no X(s) y X(s′) implica Y(s′)"), un subsistema restringido solo negativamente, el peligro principal de la
fuente sin ninguna ley, y una infidelidad a la fuente: el JTT *rampa* el calentamiento, no lo corta.

Las dos últimas son las que importan para el método, y ninguna es un error de transcripción.

**El conjunto de leyes era todo negativo.** Una revisión construyó un modelo degenerado —ignorar toda parada no
cableada al DMS, cortar en vez de rampar, no contar nunca el watchdog, no aceptar nunca el fin de pulso— y lo hizo
pasar: las leyes **y** el gate de vacuidad que habíamos escrito para detectar exactamente eso. De 37 mutantes
plausibles, 16 sobrevivían. La respuesta fueron 18 leyes de demanda y de marco.

**Las leyes de demanda dejaban ocho agujeros**, y una segunda pasada con 25 mutantes nuevos volvió a romperlas: 11
sobrevivían. Los tres peores: nada exigía que un heartbeat reiniciara el contador del watchdog (una ley enmarcaba el
control y el otro contador y se olvidaba de ese); el contador podía pasar de largo su límite sin que ninguna ley lo
viera, porque el paso que lo habría expuesto enclava el PTN y vacía todas las hipótesis; y nada restringía la capa
concreta, de modo que leer siempre la matriz de la primera instancia desactivaba en silencio la razón de existir de la
segunda **sin cambiar el conjunto alcanzable**, con lo cual el teorema de trazas era ciego. Once leyes más.

También aparecieron dos leyes **auto-referenciales** —una escribía la guarda del fin de pulso llamando a la guarda del
propio modelo, y por lo tanto la satisfacía cualquier guarda; otra comparaba la capa concreta contra una expectativa
construida con la misma tabla— y una métrica de cobertura que era **cero por construcción**.

## 4. Costos medidos

| | Fase 2 (`seq`) | Fase 2b (`seq3`) | Fase 3 (`v3`) |
|---|---|---|---|
| Modelo (líneas de código) | 323 | 425 | 1 116 |
| Enumerador / certificados | 106 | 223 | 446 |
| Leyes | 12 | 9 + 1 | 64 + 117 |
| Pruebas (líneas de código) | 1 593 | 323 | 1 034 + 330 |
| Celdas del certificado | 1 792 × 18 | 448 × 18 × 4 | 2 688 × 39 × 2 |
| Tiempo de verificador por certificado | 5,5 s | 34 s | 14–19 s |
| Iteraciones del probador | 2 + 4 + 2 | 5 | 6 (leyes de demanda) + 18 (ronda 3), ninguna de lógica |
| Errores al escribir el modelo | — | — | 9, todos de sintaxis o de linealidad; 0 celdas falsas en la instanciación previa |

Dos observaciones de costo que valen para quien repita el método. **Primera**: el patrón de la fase anterior no escala
tal cual. Bend compara formas normales completas, sin atajo sintáctico, así que proyectar desde el certificado entero
con argumentos simbólicos obliga al verificador a normalizarlo de los dos lados de cada comparación; medido, un solo
paso delta a un término sintácticamente idéntico costaba 8,6 s, y la escalera literal de la fase anterior habría
costado entre 15 y 30 minutos. Rebanar el certificado en 56 piezas decididas por cómputo lo baja a minutos y no
debilita nada: las 56 rebanadas *son* el certificado, celda por celda. **Segunda**: agregar leyes al certificado cuesta
tiempo de verificador, no líneas de prueba. Las 18 leyes de demanda llevaron la prueba de 83–113 s a 140–160 s; las 9
de la ronda 3 no la movieron de forma medible. La escalera de reflexión no cambió en ninguna de las dos rondas.

## 5. Límites de la evidencia

Ver `v3/docs/fase3-seguridad.md` §4: sin tiempo real, sin vivacidad, sin fallas de hardware, sin mensajes
perdidos ni malformados, sin modelo de planta detrás del acuse, sin independencia entre capas, sin matriz secundaria,
sin umbral de corriente del DMV, sin bypass de entradas del PTN. **Un modelo que ignora todo evento también satisface el teorema de trazas.**
Una versión anterior de este trabajo sostenía que el gate de vacuidad y las leyes de conformidad ya lo distinguían de
semejante modelo; era falso, y es el hallazgo del §3.4. Lo que lo distingue son las 29 leyes de demanda y de marco, la
métrica de ajuste y el banco de mutantes adversarial. Comparación con la práctica publicada ([S3]: 71 pruebas de comportamiento
+ comisionado + experiencia operativa): las pruebas dan evidencia sobre el sistema real; el modelo da cobertura sobre la
lógica, por configuración, en minutos. No reemplaza al comisionado, a FAT/SAT, al análisis de tiempos ni a la
evaluación independiente.

## 6. Autoría y cómo se hizo

Las especificaciones, los modelos, las leyes, las pruebas y las revisiones adversariales fueron producidas por un
sistema de IA (Claude, Anthropic; instancias Opus 5 y Fable 5.1) dirigido por un autor humano que decidió el alcance,
las fuentes, las hipótesis y qué cuenta como cerrado, y que auditó los resultados. El verificador de pruebas (Bend 2.0.6,
backend JS) es el juez de toda afirmación bajo ley: la IA puede equivocarse al escribir, y se equivocó (véase §3.4); lo
que el método garantiza es que ninguna equivocación en la capa bajo leyes pasa en silencio. Las revisiones
automatizadas **no** constituyen evaluación independiente en sentido regulatorio y no hubo evaluación humana
independiente; antes de la versión final se enviará la reconstrucción a los autores de [S1]/[S2] para una lectura de
exactitud fáctica. Todo el material es reproducible desde el repositorio (Apache 2.0) en una máquina Windows sin
toolchain nativo.

## 7. Trabajo futuro

Estado comandado vs. reportado de las unidades (para verificar el acuse de R-11 como secuencia); leyes de buena
formación de configuraciones y certificación de la regla en vez de la instancia; el umbral de corriente del DMV como
veredicto; cross-check del certificado en nuXmv o TLA+/Apalache (vivacidad "no reclamada" en vez de "no intentada");
un segundo caso de estudio fuera de fusión (reactor de investigación o planta de detritiación) con el mismo método.

## Referencias

[S1]–[S7] como en `v3/docs/fase3-fuente.md` §2; IEC 61508-3:2010; IEC 61513:2011; Alpern & Schneider, *Defining
liveness* (1985); el repositorio de este trabajo.
