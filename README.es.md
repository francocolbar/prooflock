# prooflock — modelos de referencia verificados para lógica de protección de máquina

*Caso de estudio sobre la cadena de protección de la pared de JET (Stop Selector del RTPS + PTN + armado del DMS), construido con Bend 2.*
Versión en inglés: [README.md](README.md).

## 1. Qué es, en un párrafo

Un método para escribir la lógica discreta de un sistema de protección (enclavamientos, secuenciadores de parada,
permisivos) como un **modelo total y ejecutable** cuyas propiedades de seguridad se **prueban para toda traza y toda
configuración** con un verificador de pruebas, y usar después ese modelo como **oráculo de referencia** contra la
implementación real. Las pruebas son baratas de escribir porque el estado se parte en un control finito y unos pocos
contadores gobernados por comandos: toda propiedad del control la decide el verificador por cómputo sobre el dominio
completo (un *certificado*) y se eleva a ley universal por reflexión, así que el texto de la prueba no crece con el
tamaño del control. El tiempo de chequeo sí crece: el verificador evalúa cada celda del certificado (924 672 para los
dos órdenes de urgencia de acá), y `PROOF_JETPROT_LIVE.bend`, que importa los certificados, tardó 795,8 s por el
camino serial y 1 221,9 s al lado de las etapas de Python (§3). El repositorio contiene la base del método (base
numérica probada, IR lineal probado), dos ejercicios internos y un caso de estudio público: la reconstrucción, desde
publicaciones abiertas, de la lógica de paradas del Real-Time Protection Sequencer de JET y su interfaz con el Pulse
Termination Network y el Disruption Mitigation System.

**Qué no es.** La función modelada es *protección de máquina* (protección de inversión), no una función de seguridad
nuclear; la evidencia es sobre una *especificación*, no sobre un sistema; aporta a un argumento de capacidad
sistemática (IEC 61508-3, tablas A.1/A.2/A.9) y no sostiene ningún reclamo de SIL por sí sola; 28 de las 56 celdas de
la matriz de configuración certificada (21 en columnas que el paper no muestra, más la fila de 7 celdas de la alarma
ciega) son hipótesis nuestras porque la tabla publicada muestra 28, y la tabla secundaria de la cuarta instancia es
ilustrativa. Todo esto está escrito antes que los resultados, en `v3/docs/phase3-safety.md`.

**¿Recién llegás?** [`v3/docs/LEYES_CATALOGO_ACCESIBLE.md`](v3/docs/LEYES_CATALOGO_ACCESIBLE.md) (en inglés,
[`v3/docs/JET_LAWS_EXPLAINED.md`](v3/docs/JET_LAWS_EXPLAINED.md)) recorre desde cero, en lenguaje llano, todo el caso
de estudio: por qué demostrar en vez de sólo testear, qué hace de verdad la cadena de protección de JET, cómo se lee
una ley de Bend y qué dice cada una de las 234 leyes y de dónde sale (hecho publicado o supuesto nuestro declarado).
No supone más que una formación general: leelo antes que los archivos de leyes.

## 2. Estructura

| Ruta | Qué | Cómo se corre |
|---|---|---|
| `env/` | el runner de Bend pinneado a un commit (`env/bend.sh`, rechaza cualquier otro checkout), 13 chequeos de toolchain y hello-world | `bash env/check_env.sh` |
| `v3/` | **el caso de estudio**: modelo, certificado, leyes, pruebas, tests negativos, puente, implementación de producción con bugs plantados, re-ejecución del certificado en Python (C5), gate, comparador de corridas (`compare_runs.py`) | `py -3.14 v3/run.py` |
| `v3/docs/` | fuentes y citas (`phase3-sources.md`), diseño y leyes (`phase3-design.md`), peligros / requisitos de seguridad / límites de la evidencia (`phase3-safety.md`), trazabilidad (`phase3-traceability.md`), copias CC BY de los papers (`sources/`); evaluación de los supuestos contra el código, las fuentes de JET y la física (`SUPUESTOS_EVALUACION.md`); catálogo de leyes, a nivel código (`LEYES_CATALOGO.md`) y en lenguaje llano (`LEYES_CATALOGO_ACCESIBLE.md`, y `JET_LAWS_EXPLAINED.md` en inglés) | inglés: `phase3-*.md`, `JET_LAWS_EXPLAINED.md`; castellano: `SUPUESTOS_EVALUACION.md`, `LEYES_CATALOGO.md`, `LEYES_CATALOGO_ACCESIBLE.md` (recorrido en lenguaje llano de las 234 leyes) |
| `v2/num/` | base numérica probada: enteros canónicos con el anillo conmutativo completo (22 leyes), naturales grandes como listas de bits con sumador probado, enteros grandes | reutilizable |
| `v2/heat/` | IR lineal probado + oráculo exacto para un stencil de calor 1D (primer ejercicio) | `py -3.14 v2/heat/run.py` |
| `v2/seq/`, `v2/seq3/` | secuenciador de descarga de tokamak con 6 invariantes de protección probados para toda traza; `seq3` es el rediseño que abarató las pruebas (1593 → 323 líneas) | `py -3.14 v2/seq3/run.py` |
| `docs/`, `heat/` | la primera vuelta (histórica) del spike, su informe de cierre (`docs/spike-2026-09-18.md`) y el borrador del preprint (`docs/preprint-draft.md`) | historia |

## 3. El caso de estudio (v3) en números

Revisado el 2026-09-21 (fidelidad a [S1]/[S2]/[S6], `docs/STATUS_2026-09-21.md` bloqueante 4): la fase de programa y
la forma de onda de terminación son dos vistas del tiempo, una alarma local reduce la unidad en vez de inhibirla, el
veredicto de habilitación del DMV (entonces leído como corriente del plasma sola) gatea el armado del DMS, y los dos
chequeos de fiabilidad pasan por máscaras por instancia. Revisado otra vez el 2026-09-22 (revisión 4 del registro de
supuestos, `v3/docs/phase3-sources.md` §4; evaluación en `v3/docs/SUPUESTOS_EVALUACION.md`): lo que P1 y D1 dicen
sobre el PTN y el stop primario queda en cinco leyes con nombre, separadas de nuestra política entre los dos stops
suaves (dos reformulan fuentes de JET, sobre todo De Tommasi et al. 2013, [N1]; tres juntan un enunciado de JET con
una formalización nuestra, declarada), el veredicto de habilitación del DMV se lee como corriente del plasma o energía
almacenada por encima del umbral (A-22; el código y las leyes no cambiaron), y una alarma que llega durante un stop
lee una tabla secundaria propia de cada instancia (se agregó una cuarta instancia, ilustrativa). El 2026-09-23 el pin
de Bend pasó a 2.0.25, el gate aprendió a correr sus etapas en paralelo (`--jobs`, §4) y el gate de mutación calcula
la equivalencia de su único mutante sobreviviente en vez de aceptarlo por su nombre; todos los recuentos de abajo son
los mismos que en la corrida del 2026-09-22.

- **Modelo**: 10 752 estados de control (fase de programa × flag de onda × respuesta × DMS × plasma × veredicto de
  habilitación del DMV × dos unidades en Off / Ramping / Reduced / On) × 28 variantes de evento abstracto (la
  configuración viaja como carga del evento) + 2 contadores. Un alfabeto concreto de 24 eventos de planta llega a él
  por cuatro instancias de configuración: la Tabla 1 de Stephen et al. 2011 tal como se publicó, la misma con el mode
  lock cableado al PTN (nuestra lectura del camino que describen [S6]/[S7]), la tabla publicada con los dos chequeos
  de fiabilidad deshabilitados, y la tabla publicada con una tabla secundaria **ilustrativa** (durante un stop, PTN
  donde la tabla primaria pide alguna respuesta y nada donde no pide nada: una alarma de modo bloqueado, que la tabla
  publicada deja sin respuesta, sigue sin respuesta; la tabla secundaria de JET no está publicada, A-35).
- **Certificado**: 43 columnas × 10 752 estados = **462 336 celdas por orden de urgencia**, los dos órdenes, decididas
  por el verificador (`PROOF_JETPROT_LIVE.bend`, que importa la prueba por reflexión y los certificados, tardó 795,8 s
  en el checker JS en la corrida serial del 2026-09-22 y 1 221,9 s al lado de las etapas de Python en la corrida de
  referencia, en paralelo, del 2026-09-23); más un certificado de 10 752 estados para los corolarios y uno de 5 376
  celdas para la capa concreta (4 instancias × 7 fases × 2 × 4 niveles en vigor × 24 eventos: el nivel elige entre la
  tabla primaria y la secundaria).
- **Leyes**: **81** (`LAWS_JETPROT.bend`) + **143** de conformidad + 8 lemas de soundness + 2 teoremas de respuesta
  acotada = 234, todas con `All terms check.` Seis cláusulas de invariante, las leyes de paso (qué no puede pasar),
  las de demanda y marco (qué tiene que pasar), trece leyes de fidelidad (dos vistas del tiempo, potencia parcial,
  máscaras, el veredicto de habilitación del DMV —corriente o energía almacenada por encima del umbral, A-22— y los
  dos marcos que pidió la métrica de ajuste), cinco leyes que nombran lo que P1 y D1 dicen sobre el PTN y el stop
  primario, separadas de nuestra política entre stops suaves (`p1a_ptn_latched` y `d1b_primary_honoured` reformulan
  fuentes de JET; `d1a_ptn_honoured`, `p1b_stop_never_cleared` y `piw_after_ptn_is_noop` juntan un enunciado de JET
  con una formalización nuestra), el teorema de trazas para los alfabetos abstracto y concreto, la configuración celda
  por celda (28 publicadas + 21 supuestas + la fila ciega, separadas), las tablas secundarias y la cuarta instancia
  (siete leyes), y dos teoremas de respuesta sobre trazas: `hb_max` ticks sin heartbeat enclavan el PTN, un DMS armado
  dispara en a lo sumo `ack_max` ticks; comprobados para los límites del modelo (`hb_max` = 3, `ack_max` = 2): la
  inducción sólo los compara con cuentas de ticks y con los contadores, así que el argumento debería valer para otros
  límites, pero sólo esos dos valores están verificados. Doce de ellas se derivan de las otras (`DERIVED` en
  `v3/pymodel/jetprot_laws.py`): se conservan como enunciados con nombre y no cuentan como evidencia independiente.
- **Tests negativos**: **12** enunciados falsos que el verificador tiene que rechazar. Once evalúan un predicado en
  una celda testigo escrita en el test (diez sobre una variante del paso con el bug, uno una ley falsa sobre el modelo
  correcto); uno (el negativo 8) afirma que el certificado es `False`. El verificador responde con el *Bool* refutado
  y el nombre de la ley (`expected`/`observed` `True{}`/`False{}`): un caso que falla, dado por el test, no un
  contraejemplo que el verificador haya buscado. El gate acepta un rechazo solo si el verificador refutó un *Bool* y
  nombró la ley (un error de tipos de Bend imprime las mismas palabras).
- **Re-chequeo en Python** (una re-ejecución en otro lenguaje, no una implementación independiente:
  `v3/docs/phase3-design.md` §9a H23): **924 672 celdas** del certificado Bend comparadas contra el modelo Python de
  referencia, los 62 chequeos de celda del oráculo en Python (`LAWS` en `v3/pymodel/jetprot_laws.py`) re-evaluados
  sobre los estados que produjo Bend, 0 discrepancias; alcanzabilidad concreta 804 estados en cada una de las tres
  instancias base y 744 en la cuarta, todos dentro del invariante.
- **Mutación adversarial**: **75 de 76** defectos del modelo de referencia en Python muertos, juzgados por las leyes
  reescritas como predicados de Python (`v3/pymodel/jetprot_laws.py`), que leen las constantes de la especificación
  (`pymodel/spec_consts.py`), no las del modelo, más un control de que el invariante del modelo es el de la
  especificación. El verificador de Bend no participa: el puntaje mide las copias en Python de las leyes, y una ley de
  Bend más débil que su copia, o una sin copia (`TODO.md`), no se notaría acá. 62 de los defectos los escribieron dos
  revisiones automatizadas separadas (§7) con el encargo de romper las leyes, 11 apuntan a las constantes y al propio
  oráculo, 3 a la tabla secundaria; el único sobreviviente es un mutante *equivalente*, cuya relación de transición
  difiere de la del modelo en 0 de 924 672 celdas, cuyo paso con los contadores difiere en 0 de 12 042 240 celdas con
  valores concretos de los contadores y cuyo `concretize` difiere en 0 de 1 032 192 celdas (instancia, estado de
  control, evento de planta) (lo calcula el gate, C6 `equivalence`, que acepta a un sobreviviente solo si no difiere
  en ninguna celda). `run.py all --full` registra además cuántas leyes atrapan cada mutante; en la corrida commiteada
  31 cayeron por una sola ley o control (11 de ellos solo por las dos leyes de la capa concreta, y M72 solo por el
  control del invariante): puntos débiles declarados.
- **Ajuste**: sobre una muestra fija y reproducible de 400 celdas alcanzables, el conjunto de leyes fija el estado
  siguiente de forma única en el **99,3 %** (1,01 admisibles de 10 752), y los comandos a los contadores en 243 de
  ellas (212 antes de la revisión 4: la ley `piw_after_ptn_is_noop` es evidencia nueva para los contadores).
- **Testing diferencial**: 9 defectos plantados × 4 instancias × 2 generadores, seed fija (88 corridas contando las
  configuraciones limpias y la que tiene todos los defectos); 35 de 40 configuraciones con defecto encontradas, ningún
  falso positivo en las limpias; las otras 5 son inobservables por construcción y el gate las declara: el defecto de
  falla de comunicación en la instancia que enmascara ese chequeo, el de secundaria ignorada en las tres instancias
  cuya secundaria es la primaria, y una des-escalada en la cuarta instancia, donde toda alarma durante un stop pide
  PTN o nada.
- **Sensibilidad**: el orden de urgencia entre las dos respuestas blandas (la única elección libre del modelo) es un
  parámetro; toda ley abstracta se prueba para los dos órdenes; la capa concreta y la configuración se certifican con
  el orden elegido (`Ord1`, A-1).
- **Reproducibilidad**: `py -3.14 v3/run.py quick` en alrededor de un minuto (34–87 s en las corridas del 2026-09-23);
  `all --full` en 1 222,4 s (unos 20 min) con el `--jobs` por defecto en la máquina de referencia (2026-09-23, Bend
  2.0.25) y en 7 305,5 s (unos 122 min) por el camino serial, `--jobs 1` (2026-09-22, Bend 2.0.24); los tiempos por
  etapa están en §4. `results.json`, `recheck.json` y `SHA256SUMS` son la corrida de referencia commiteada, la del
  2026-09-23, con bloque de procedencia (versiones, el commit pinneado de Bend, la seed, la cantidad de jobs en
  paralelo, el SHA-256 de cada input); `v3/compare_runs.py` compara dos corridas hoja por hoja.

## 4. Reproducir

```bash
bash env/check_env.sh          # entorno + 13 chequeos, pin de Bend 2.0.25 (bun, node, Python 3.14, JAX f64)
py -3.14 v3/run.py quick       # una prueba de humo del caso de estudio en alrededor de un minuto (pensada para CI; todavía no hay ninguna configurada)
py -3.14 v3/run.py all --full  # todo, como en la corrida commiteada: pruebas, humo, 12 negativos, re-chequeo, 76 mutantes y las leyes que atrapan a cada uno, testing diferencial -> reescribe v3/results.json, v3/recheck.json + SHA256SUMS
py -3.14 v3/compare_runs.py v3 OTRA   # esta corrida contra otra (un directorio de resultados o la raíz de un repo), hoja por hoja
py -3.14 v3/recheck.py         # solo los gates del lado Python (C2 vacuidad, C3 sensibilidad, C5 re-chequeo, C6 mutantes); reescribe v3/recheck.json sin bloque de procedencia
py -3.14 v2/seq3/run.py        # el ejercicio del secuenciador
py -3.14 v2/heat/run.py        # el ejercicio del calor
```
`quick` chequea `PROOF_JETPROT_CONF.bend` y `PROOF_JETPROT_SOUND.bend` (las 143 + 8 leyes), un test negativo, la
prueba de humo en tiempo de ejecución y 2 corridas diferenciales; las 81 + 2 leyes de `LAWS_JETPROT.bend` y
`LAWS_JETPROT_LIVE.bend` y los certificados sólo los chequean `proofs` y `all`, a través de `PROOF_JETPROT_LIVE.bend`
(§3). `run.py --help` lista las etapas. `all` reescribe en el lugar `v3/results.json`, `v3/recheck.json` y
`SHA256SUMS` (el `SHA256SUMS` nuevo coincide con los archivos nuevos); `recheck.py` reescribe sólo `v3/recheck.json`,
sin el bloque de procedencia (y, sin `--full`, sin el censo de leyes por mutante), así que después
`sha256sum -c SHA256SUMS` falla en ese archivo. Para comparar una corrida nueva con la commiteada, guardá antes una
copia de los archivos commiteados (`mkdir ../prooflock-ref && cp v3/results.json v3/recheck.json ../prooflock-ref/`) y
corré `py -3.14 v3/compare_runs.py v3 ../prooflock-ref --list`;
`git restore v3/results.json v3/recheck.json SHA256SUMS` vuelve a la corrida commiteada.

Todo corre en Windows sin toolchain nativo (Bend corre desde su checkout de código fuente con bun a través de
`env/bend.sh`, y el puente carga el modelo en node con el backend JS de Bend). Los scripts están escritos también para
Linux y macOS, pero todavía no hay ninguna corrida registrada ahí: usá `python3.14` donde este README dice `py -3.14`,
y `PY=python3.14 bash env/check_env.sh`. Versiones pinneadas: `env/SETUP.md`. Python:
`py -3.14 -m pip install -r requirements.txt`. El compilador Bend no está vendorizado: `env/bend.sh` baja el commit
pinneado (2.0.25, tag `v2.0.25`) de github.com/bendlang/bend (github.com/HigherOrderCO/Bend redirige ahí), rechaza
cualquier otro checkout, y `env/SETUP.md` registra el commit, el hash del árbol y qué hacer si el repo de GitHub
vuelve a no estar disponible (respondió 404 el 2026-09-21 y desde el 2026-09-22 es público otra vez): `BEND_SRC` a un
checkout de ese commit, que el gate completo necesita (el puente del re-chequeo y del testing diferencial carga
`bend2/main.ts` desde ahí, y el bloque de procedencia registra su commit); `BEND_BIN`, un binario del instalador
oficial (que a su vez lo baja de las releases de GitHub de bendlang/bend), sirve para `bash env/bend.sh` usado por su
cuenta: `v3/run.py` se niega a arrancar si está definido, porque sus chequeos de Bend correrían sobre ese binario
mientras el puente y el bloque de procedencia usan `BEND_SRC`.

`--jobs N` (`run.py`; `recheck.py` también lo acepta, para las etapas de Python; por defecto, la cantidad de CPU
lógicos menos 4: 12 en la máquina de referencia) corre las etapas en paralelo: hasta 8 chequeos de Bend a la vez,
primero `PROOF_JETPROT_LIVE.bend`, al lado de un pool de procesos Python con prioridad por debajo de lo normal (7 en
la corrida commiteada) para C5, C2, C3, los mutantes y los flags del modelo de C6 y las 88 corridas diferenciales.
Cada resultado se arma en el orden serial, y `--jobs 1` es exactamente el camino serial, que queda como referencia
serial. Con el mismo modelo, las mismas leyes y el mismo compilador que la corrida serial del 2026-09-22, una corrida
`all --full --jobs 12` (1 535,5 s, Bend 2.0.24) dio los mismos `results.json` y `recheck.json`, hoja por hoja (6 433
hojas), salvo los tiempos, los metadatos de la corrida y los hashes de los dos scripts del gate. La corrida commiteada
contra la serial: los mismos veredictos, recuentos, censo y trazas diferenciales en las mismas 6 433 hojas; aparte de
los tiempos y los metadatos de la corrida, difieren sólo en la versión y el commit de Bend, los hashes de los 17
inputs editados entre una y otra y de los dos scripts del gate, el hash del nuevo `v3/compare_runs.py`, el campo nuevo
`equivalence` de C6 y las descripciones de cinco mutantes a los que se les corrigió el número de supuesto.
`v3/compare_runs.py` hace esa comparación para dos corridas cualesquiera y verifica los hashes de la nueva contra los
archivos en disco. `all` sin `--full` se saltea el censo de leyes por mutante. Tiempos medidos, en segundos (máquina
de referencia: Windows 11, 8 núcleos / 16 hilos, 32 GB):

| Etapa (segundos) | corrida commiteada: `all --full`, `--jobs 12`, 2026-09-23, Bend 2.0.25 | serial: `all --full --jobs 1`, 2026-09-22, Bend 2.0.24 |
|---|---|---|
| `PROOF_JETPROT_LIVE.bend` | 1 221,9 | 795,8 |
| `PROOF_JETPROT_CONF.bend` / `PROOF_JETPROT_SOUND.bend` | 1,6 / 0,8 | 0,7 / 0,3 |
| C5, re-chequeo del certificado | 32,5 | 20,3 |
| C2, vacuidad y ajuste | 111,0 | 66,4 |
| C6, mutantes con el censo de `--full` | 1 193,0 | 5 884,4 |
| las 88 corridas diferenciales, sumadas | 243,0 | 161,9 |
| **gate completo** | **1 222,4** | **7 305,5** |

En la corrida en paralelo las etapas se superponen: la cifra de C6 es el tiempo desde el comienzo de las etapas, todas
las etapas de Python habían terminado a los 1 200,6 s, y el gate terminó con `PROOF_JETPROT_LIVE.bend`.

## 5. El método en siete movimientos

1. **Control finito + comandos a contadores.** El estado de control es un producto de enumeraciones chicas; los
   contadores nunca entran al control, solo sus *veredictos* (booleanos), y el control responde con comandos
   (`Keep/Reset/Inc`).
2. **Certificado por cómputo.** Toda propiedad de una celda (orden, estado, evento, veredictos) es un booleano; la
   conjunción sobre el dominio entero es un `{==}` para el verificador.
3. **Reflexión.** Un lema chico por nivel de cuantificación convierte `check == True` en enunciados universales; las
   únicas inducciones que quedan son un lema genérico de contadores y la inducción en la traza.
4. **La configuración como carga del evento.** Las leyes se prueban para toda configuración; la instancia publicada
   entra por leyes de conformidad, una por celda, separadas en publicadas y supuestas.
5. **Leyes que exigen, no solo leyes que prohíben.** Un conjunto que solo dice qué no puede pasar lo satisface el
   modelo que no hace nada. Una revisión adversarial construyó ese modelo y lo hizo pasar; las 18 leyes de demanda y
   de marco D1–D18 le responden, y una segunda pasada adversarial, apuntada a sus costuras, agregó 8 más (E2–E8, E11)
   y las tres leyes V1, que hacen del dominio reducido de veredictos del certificado un teorema: 29 leyes, 26 de ellas
   de demanda y de marco (§6).
6. **Medir el conjunto de leyes, no la cantidad de leyes.** La medida honesta es cuán estrechamente fijan el estado
   siguiente, y un puntaje de mutación vale lo que valga de adversarial el banco. El gate falla si sobrevive un
   mutante que no se calcula equivalente; el ajuste se mide en cada corrida y queda registrado en `recheck.json`,
   donde `compare_runs.py` muestra cualquier cambio, pero ningún umbral hace fallar el gate.
7. **Todo lo que está bajo ley lo juzga el verificador; todo lo que está afuera lo juzga una segunda
   implementación**: re-chequeo celda por celda, el gate de vacuidad y la medida de ajuste, el banco de mutantes,
   y testing diferencial contra una implementación escrita desde la prosa.

## 6. Límites (la lista corta; la larga está en `v3/docs/phase3-safety.md` §4)

Sin tiempo, sin vivacidad no acotada (la respuesta acotada sí está probada: `hb_max` ticks sin heartbeat enclavan el
PTN y un DMS armado dispara en `ack_max` ticks, en ticks abstractos, no en milisegundos), sin fallas de hardware, sin
mensajes perdidos o malformados, sin modelo de planta detrás de los acuses, sin reclamo de independencia entre las
capas software y cableada. Una alarma nueva durante un stop en curso lee una tabla secundaria propia de cada
instancia: las tres instancias base vuelven a leer la tabla primaria, en la fase de programa (que sigue avanzando
durante un stop suave), y se quedan con la más urgente entre el pedido nuevo y la respuesta vigente (el máximo, A-2);
una cuarta instancia, ilustrativa, usa el PTN como secundaria donde la tabla primaria pide alguna respuesta (inspirada
en la figura 7 de [N1], "The preferred secondary plasma stop is the PTN slow stop", traducción nuestra: el stop
secundario preferido es el PTN lento; es una estadística de uso, no la tabla de JET, que no está publicada; A-35). El
congelamiento de la configuración del stop en el stop primario, que De Tommasi et al. 2013 describen para el
controlador de forma, no está modelado (A-24, A-30). La ventana de calentamiento y la de la válvula están fijas en el
modelo, iguales para toda instancia, mientras que JET las programa por pulso (A-10, A-27); una reducción local se
olvida si la unidad se apaga y se vuelve a prender (A-34); la condición de habilitación del DMV entra sólo como un
veredicto booleano (corriente **o** energía almacenada por encima del umbral, A-22; los números quedan fuera del
modelo). Lo que JET publica sobre el PTN (un stop PIW, que identificamos con los stops suaves del modelo, nunca le
gana a un PTN; un pedido PIW después de un PTN es una "invalid task", tarea inválida, para el controlador de forma,
que formalizamos como un paso que no cambia nada) está en leyes con nombre, demostradas.

Y el límite que a este proyecto le costó dos rondas de trabajo, dicho sin vueltas porque generaliza: **un modelo que
ignora todo evento satisface un teorema de seguridad.** Una versión anterior de este repositorio afirmaba que el gate
de vacuidad y las leyes de conformidad lo distinguían de semejante modelo. No lo hacían: una revisión adversarial
construyó el modelo degenerado —ignorar toda parada no cableada al DMS, cortar en vez de rampar, no contar nunca el
watchdog, no aceptar nunca el fin de pulso— y pasó las leyes **y** el gate de vacuidad juntos. Lo que de verdad lo
distingue son las 26 leyes de demanda y de marco (29 con las tres V1) que se escribieron en respuesta a ella y a una
segunda pasada adversarial (§5, movimiento 5), y las dos medidas capaces de ver la diferencia: el ajuste del conjunto
de leyes y un banco de mutantes escrito por revisores cuyo encargo era romperlo.

## 7. Cómo se hizo (autoría)

Las especificaciones, los modelos, las leyes y las pruebas fueron escritos por un sistema de IA (Claude, Anthropic)
dirigido y auditado por un autor humano; el verificador de pruebas (Bend 2) es el juez de toda afirmación bajo ley;
las revisiones adversariales fueron pasadas automatizadas de otras instancias de la misma familia de modelos: **no son
evaluación independiente en ningún sentido regulatorio, y no hubo evaluación humana independiente**. El humano decidió
el alcance, las fuentes, las hipótesis y qué cuenta como cerrado. Los hallazgos de las rondas adversariales (cinco
sobre el diseño y el código, una sexta de fidelidad y la revisión de supuestos de la revisión 4) están registrados en
`v3/docs/phase3-design.md` §9, incluidos los tres que cambiaron el propio conjunto de leyes (§9b) y las lecciones
sobre el método (§9c).

## 8. Fuentes

Stephen et al., ICALEPCS 2011, FRAAULT04 (CC BY 3.0) · Waterhouse et al., Fusion Eng. Des. 210 (2025) 114737 (CC BY 4.0) ·
Edwards et al., Fusion Eng. Des. 146 (2019) 277 · Alves et al., ICALEPCS 2011, WEPMN014 (CC BY 3.0) · Reux et al.,
Fusion Eng. Des. 88 (2013) 1101 · Stuart et al., Fusion Eng. Des. 168 (2021) 112412 · De Tommasi et al., preprint
EFDA-JET-PR(13)06 (se cita, no se copia) · Neto et al., ICALEPCS 2011, MOPMU035 (CC BY 3.0) · Kruezi et al., preprint
CCFE-PR(17)36 · Mayoral et al., arXiv:1309.0948. Registros completos y licencias:
`v3/docs/phase3-sources.md` §2 y `v3/docs/sources/NOTICE`.

## 9. Nombre

**prooflock** (interlock + proof), decidido el 2026-09-22. El repositorio se desarrolló bajo el nombre de trabajo
*bend-spike*, que los documentos fechados de `docs/` conservan; "veredicto con su evidencia" sigue siendo el idioma de
las pruebas.

## 10. Licencia

Apache License 2.0, copyright 2026 Franco Colombo Barceló (`LICENSE`, `NOTICE`; citar con `CITATION.cff`). Los papers
de terceros bajo sus propias licencias CC BY (`v3/docs/sources/NOTICE`).
