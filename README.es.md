# prooflock — modelos de referencia verificados para lógica de protección de máquina

*Caso de estudio sobre la cadena de protección de la pared de JET (Stop Selector del RTPS + PTN + armado del DMS), construido con Bend 2.*
Versión en inglés: [README.md](README.md).

## 1. Qué es, en un párrafo

Un método para escribir la lógica discreta de un sistema de protección (enclavamientos, secuenciadores de parada,
permisivos) como un **modelo total y ejecutable** cuyas propiedades de seguridad se **prueban para toda traza y toda
configuración** con un verificador de pruebas, y usar después ese modelo como **oráculo de referencia** contra la
implementación real. Las pruebas son baratas porque el estado se parte en un control finito y unos pocos contadores
gobernados por comandos: toda propiedad del control la decide el verificador por cómputo sobre el dominio completo (un
*certificado*) y se eleva a ley universal por reflexión, así que el esfuerzo de prueba no crece con el tamaño del
control. El repositorio contiene la base del método (base numérica probada, IR lineal probado), dos ejercicios
internos y un caso de estudio público: la reconstrucción, desde publicaciones abiertas, de la lógica de paradas del
Real-Time Protection Sequencer de JET y su interfaz con el Pulse Termination Network y el Disruption Mitigation System.

**Qué no es.** La función modelada es *protección de máquina* (protección de inversión), no una función de seguridad
nuclear; la evidencia es sobre una *especificación*, no sobre un sistema; aporta a un argumento de capacidad
sistemática (IEC 61508-3, tablas A.1/A.2/A.9) y no sostiene ningún reclamo de SIL por sí sola; 21 de las 49 celdas de
la matriz de configuración certificada son hipótesis nuestras porque la tabla publicada muestra 28. Todo esto está
escrito antes que los resultados, en `v3/docs/phase3-safety.md`.

## 2. Estructura

| Ruta | Qué | Cómo se corre |
|---|---|---|
| `env/` | el runner de Bend pinneado a un commit (`env/bend.sh`, rechaza cualquier otro checkout), 13 chequeos de toolchain y hello-world | `bash env/check_env.sh` |
| `v3/` | **el caso de estudio**: modelo, certificado, leyes, pruebas, tests negativos, puente, implementación de producción con bugs plantados, re-chequeo Python independiente, gate | `py -3.14 v3/run.py` |
| `v3/docs/` | fuentes y citas (`phase3-sources.md`), diseño y leyes (`phase3-design.md`), peligros / requisitos de seguridad / límites de la evidencia (`phase3-safety.md`), trazabilidad (`phase3-traceability.md`), copias CC BY de los papers (`sources/`) | castellano |
| `v2/num/` | base numérica probada: enteros canónicos con el anillo conmutativo completo (22 leyes), naturales grandes como listas de bits con sumador probado, enteros grandes | reutilizable |
| `v2/heat/` | IR lineal probado + oráculo exacto para un stencil de calor 1D (primer ejercicio) | `py -3.14 v2/heat/run.py` |
| `v2/seq/`, `v2/seq3/` | secuenciador de descarga de tokamak con 6 invariantes de protección probados para toda traza; `seq3` es el rediseño que abarató las pruebas (1593 → 323 líneas) | `py -3.14 v2/seq3/run.py` |
| `docs/`, `heat/` | la primera vuelta (histórica) del spike, su informe de cierre (`docs/spike-2026-09-18.md`) y el borrador del preprint (`docs/preprint-draft.md`) | historia |

## 3. El caso de estudio (v3) en números

Revisado el 2026-09-21 (fidelidad a [S1]/[S2]/[S6], `docs/STATUS_2026-09-21.md` bloqueante 4): la fase de programa y
la forma de onda de terminación son dos vistas del tiempo, una alarma local reduce la unidad en vez de inhibirla, el
umbral de corriente del DMV gatea el armado del DMS, y los dos chequeos de fiabilidad pasan por máscaras por instancia.

- **Modelo**: 10 752 estados de control (fase de programa × flag de onda × respuesta × DMS × plasma × umbral de
  corriente × dos unidades en Off / Ramping / Reduced / On) × 28 variantes de evento abstracto (la configuración
  viaja como carga del evento) + 2 contadores. Un alfabeto concreto de 22 eventos de planta llega a él por tres
  instancias de configuración: la Tabla 1 de Stephen et al. 2011 tal como se publicó, la misma con el mode lock
  cableado al PTN (el camino que describen [S6]/[S7]), y la tabla publicada con los dos chequeos de fiabilidad
  deshabilitados.
- **Certificado**: 43 columnas × 10 752 estados = **462 336 celdas por orden de urgencia**, los dos órdenes,
  decididas por el verificador (1098 s para `PROOF_JETPROT_LIVE.bend`, que importa la prueba por reflexión y los certificados, en el checker JS); más un certificado de
  10 752 estados para los corolarios y uno de 924 celdas para la capa concreta.
- **Leyes**: **75** (`LAWS_JETPROT.bend`) + **137** de conformidad + 8 lemas de soundness + 2 teoremas de respuesta
  acotada, todas con `All terms check.` Seis cláusulas de invariante, las leyes de paso (qué no puede pasar), las de
  demanda y marco (qué tiene que pasar), trece leyes de fidelidad (dos vistas del tiempo, potencia parcial, máscaras,
  umbral de corriente, y los dos marcos que pidió la métrica de ajuste), el teorema de trazas para los alfabetos abstracto y concreto, la configuración celda por celda
  (28 publicadas + 21 supuestas + la fila ciega, separadas), y dos teoremas de respuesta sobre trazas: `hb_max` ticks
  sin heartbeat enclavan el PTN, un DMS armado dispara en a lo sumo `ack_max` ticks; universales en los dos límites.
- **Tests negativos**: **10**, cada uno rechazado por el verificador con un contraejemplo explícito; el gate acepta
  un rechazo solo si el verificador refutó un *Bool* y nombró la ley (un error de tipos de Bend imprime las mismas
  palabras).
- **Re-chequeo independiente**: **924,672 celdas** del certificado Bend comparadas contra el modelo
  Python de referencia, toda ley re-evaluada sobre los estados que produjo Bend, 0 discrepancias;
  alcanzabilidad concreta 804 estados por instancia, todos dentro del invariante.
- **Mutación adversarial**: **72 de 73** defectos muertos, juzgados contra las constantes de la
  especificación (`pymodel/spec_consts.py`), no las del modelo. 62 los escribieron dos revisiones independientes con
  el encargo de romper las leyes, 11 apuntan a las constantes y al propio oráculo; el único sobreviviente es un
  mutante *equivalente*, cuya relación de transición difiere de la del modelo en 0 de 924 672 celdas. `run.py all --full` registra además cuántas leyes atrapan cada mutante; en la última corrida completa 37 cayeron por una
  sola ley (10 de ellos solo por las dos leyes de la capa concreta): puntos débiles declarados.
- **Ajuste**: sobre una muestra fija y reproducible de 400 celdas alcanzables, el conjunto de leyes fija el estado
  siguiente de forma única en el **99.3 %** (1.01 admisibles de 10 752).
- **Testing diferencial**: 8 defectos plantados × 3 instancias × 2 generadores, seed fija; 26 de
  27 configuraciones con defecto encontradas, ningún falso positivo en las limpias; la 27.ª (el bug de falla de comunicación
  en la instancia que enmascara ese chequeo) es inobservable por construcción y el gate lo declara.
- **Sensibilidad**: el orden de urgencia entre las dos respuestas blandas (la única elección libre del modelo) es un
  parámetro; toda ley se prueba para los dos órdenes.
- **Reproducibilidad**: `py -3.14 v3/run.py quick` en unos 30 s, `all --full` en unos 94 min (una hora es el censo de leyes por mutante de `--full`); `results.json`,
  `recheck.json` y `SHA256SUMS` son la corrida de referencia commiteada, con bloque de procedencia (versiones, el
  commit pinneado de Bend, la seed, el SHA-256 de cada input).

## 4. Reproducir

```bash
bash env/check_env.sh          # entorno + 13 chequeos, pin de Bend 2.0.24 (bun, node, Python 3.14, JAX f64)
py -3.14 v3/run.py quick       # el caso de estudio en < 1 min (gate de CI); `--help` lista las etapas y sus tiempos
py -3.14 v3/run.py all         # todo (~7 min): pruebas, humo, 10 negativos, re-chequeo, 73 mutantes, testing diferencial -> v3/results.json + SHA256SUMS
py -3.14 v3/recheck.py         # solo los gates del lado Python (C2 vacuidad, C3 sensibilidad, C5 re-chequeo, C6 mutantes)
py -3.14 v2/seq3/run.py        # el ejercicio del secuenciador
py -3.14 v2/heat/run.py        # el ejercicio del calor
```
Todo corre en Windows sin toolchain nativo (Bend sobre el backend JS a través de `env/bend.sh`); Linux/macOS igual.
Versiones pinneadas: `env/SETUP.md`. Python: `py -3.14 -m pip install -r requirements.txt`. El compilador Bend no está vendorizado: `env/bend.sh` baja el commit pinneado (2.0.24), rechaza cualquier otro checkout, y `env/SETUP.md` registra el commit, el hash del árbol y qué hacer ahora que el repo de GitHub responde 404 (`BEND_SRC` a un checkout de ese commit, o `BEND_BIN` al binario del instalador oficial).

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
   modelo que no hace nada. La mitad de las leyes de este repositorio existen porque una revisión adversarial
   construyó ese modelo y lo hizo pasar.
6. **Medir el conjunto de leyes, no la cantidad de leyes.** La medida honesta es cuán estrechamente fijan el estado
   siguiente, y un puntaje de mutación vale lo que valga de adversarial el banco. Las dos son gates acá.
7. **Todo lo que está bajo ley lo juzga el verificador; todo lo que está afuera lo juzga una segunda
   implementación**: re-chequeo celda por celda, gates de vacuidad y de ajuste, el banco de mutantes, y testing
   diferencial contra una implementación escrita desde la prosa.

## 6. Límites (la lista corta; la larga está en `v3/docs/phase3-safety.md` §4)

Sin tiempo, sin vivacidad no acotada (la respuesta acotada sí está probada: `hb_max` ticks sin heartbeat enclavan el
PTN y un DMS armado dispara en `ack_max` ticks, en ticks abstractos, no en milisegundos), sin fallas de hardware, sin mensajes perdidos o malformados, sin modelo de planta detrás
de los acuses, sin reclamo de independencia entre las capas software y cableada, sin matriz secundaria (no publicada),
umbral de corriente del DMV fuera de alcance.

Y el límite que a este proyecto le costó dos rondas de trabajo, dicho sin vueltas porque generaliza: **un modelo que
ignora todo evento satisface un teorema de seguridad.** Una versión anterior de este repositorio afirmaba que el gate
de vacuidad y las leyes de conformidad lo distinguían de semejante modelo. No lo hacían: una revisión adversarial
construyó el modelo degenerado —ignorar toda parada no cableada al DMS, cortar en vez de rampar, no contar nunca el
watchdog, no aceptar nunca el fin de pulso— y pasó las leyes **y** el gate de vacuidad juntos. Lo que de verdad lo
distingue son las 29 leyes de demanda y de marco que se escribieron en respuesta, y las dos medidas capaces de ver la
diferencia: el ajuste del conjunto de leyes y un banco de mutantes escrito por revisores cuyo encargo era romperlo.

## 7. Cómo se hizo (autoría)

Las especificaciones, los modelos, las leyes y las pruebas fueron escritos por un sistema de IA (Claude, Anthropic)
dirigido y auditado por un autor humano; el verificador de pruebas (Bend 2) es el juez de toda afirmación bajo ley;
las revisiones adversariales fueron pasadas automatizadas de otras instancias de la misma familia de modelos: **no son
evaluación independiente en ningún sentido regulatorio, y no hubo evaluación humana independiente**. El humano decidió
el alcance, las fuentes, las hipótesis y qué cuenta como cerrado. Los hallazgos de las cinco rondas adversariales están registrados en `v3/docs/phase3-design.md` §9, incluidos los
tres que cambiaron el propio conjunto de leyes (§9b) y las lecciones sobre el método (§9c).

## 8. Fuentes

Stephen et al., ICALEPCS 2011, FRAAULT04 (CC BY 3.0) · Waterhouse et al., Fusion Eng. Des. 210 (2025) 114737 (CC BY 4.0) ·
Edwards et al., Fusion Eng. Des. 146 (2019) 277 · Alves et al., ICALEPCS 2011, WEPMN014 (CC BY 3.0) · Reux et al.,
Fusion Eng. Des. 88 (2013) 1101 · Stuart et al., Fusion Eng. Des. 168 (2021) 112412. Registros completos y licencias:
`v3/docs/phase3-sources.md` §2 y `v3/docs/sources/NOTICE`.

## 9. Nombre

**prooflock** (interlock + proof), decidido el 2026-09-22. El repositorio se desarrolló bajo el nombre de trabajo
*bend-spike*, que los documentos fechados de `docs/` conservan; "veredicto con su evidencia" sigue siendo el idioma de las pruebas.

## 10. Licencia

Apache License 2.0, copyright 2026 Franco Colombo Barceló (`LICENSE`, `NOTICE`; citar con `CITATION.cff`). Los papers de terceros bajo sus propias licencias CC BY (`v3/docs/sources/NOTICE`).
