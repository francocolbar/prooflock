# Entorno del spike (versiones pinneadas, 2026-09-18)

| Componente | Versión | Cómo se obtuvo |
|---|---|---|
| Windows | 11 Pro 10.0.26200, sin WSL, sin clang | — |
| Bend 2 | `bend 2.0.6`, fuente `github.com/HigherOrderCO/Bend` (alias `bendlang/bend`) commit `67692d7f2774262461d8a0fda7742d924f307b1d` (2026-09-18) en `~/.bend-src` | `bash env/bend.sh --version` (clona solo si falta) |
| bun | 1.3.11 (`~/.bun/bin/bun`) | ya instalado |
| node | 22.22.2 | ya instalado |
| Python | 3.14.3 (`py -3.14`) | ya instalado |
| jax / numpy | 0.11.2 / 2.4.3 (CPU) | `py -3.14 -m pip install jax` (instalado en este spike) |
| sympy | 1.14.0 | ya instalado (referencia para comparar tamaño de código) |

## Cómo correr Bend acá
No hay `bend` nativo en Windows. Todo pasa por el runner portable, que ejecuta el compilador con bun desde el checkout:

```bash
export BEND_NO_TELEMETRY=1
alias bend='bash env/bend.sh'   # the runner lives in the repo
bend archivo.bend            # chequea tipos/terminación/pruebas y corre main (backend JS)
bend PROOF.bend              # gate: debe imprimir la línea literal "All terms check."
bend archivo.bend -o out.js  # emite JS (corre con node o bun)
```

Limitaciones de esta máquina (documentadas en la skill, verificadas hoy):
- No hay binarios nativos ni GPU (necesita clang ≥ 14 y POSIX; el runtime C no compila en Windows). Todo corre en el backend JS, secuencial.
- Efectos que funcionan: `IO.print/write`, `IO.get_env` (variable existente), `File.open/write/close`, canales. No funcionan: `IO.sleep`, `File.read`, sockets, y cualquier resultado `Fail` (llaman a libc vía `bun:ffi`).
- Rutas siempre con barras `/`.

## Verificación
```bash
bash bend-spike/env/check_env.sh     # imprime versiones y PASS/FAIL por cada hello-world
```
El log de la corrida de referencia está en `env/check_env.log`.
