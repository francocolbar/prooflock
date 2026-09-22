# Entorno del spike (versiones pinneadas, 2026-09-18)

| Componente | Versión | Cómo se obtuvo |
|---|---|---|
| Windows | 11 Pro 10.0.26200, sin WSL, sin clang | — |
| Bend 2 | `bend 2.0.24`, fuente `github.com/HigherOrderCO/Bend` (alias `bendlang/bend`) commit `e52cda47a58967aa65d1eb26efe8f42a0b0407df` (2026-09-21) en `~/.bend-src`; el pin vive en `env/bend.sh` (`BEND_COMMIT`) y el runner se niega a correr con otro commit | `bash env/bend.sh version` (clona el commit pinneado si falta; `--update` lo re-chequea, `--update <commit>` mueve el pin) |
| bun | 1.3.11 (`~/.bun/bin/bun`) | ya instalado |
| node | 22.22.2 | ya instalado |
| Python | 3.14.3 (`py -3.14`) | ya instalado |
| jax / numpy | 0.11.2 / 2.4.3 (CPU) | `py -3.14 -m pip install jax` (instalado en este spike) |
| sympy | 1.14.0 | ya instalado (referencia para comparar tamaño de código) |

## Pin y procedencia del compilador (2026-09-21)

- Commit `e52cda47a58967aa65d1eb26efe8f42a0b0407df` = `bend 2.0.24`; hash del árbol fuente (`git rev-parse HEAD^{tree}`):
  `f741f100c37b268628f4490fd1135a957869e0aa`. Fuente Apache 2.0, 76 MB sin `.git`. El checkout de trabajo es `~/.bend-src`
  (`BEND_SRC`); `env/bend.sh` se niega a correr con cualquier otro commit (exit 2).
- **Upstream**: el 2026-09-21 (~19:40 UTC) `github.com/HigherOrderCO/Bend` pasó a redirigir a `github.com/bendlang/bend`,
  que responde 404 anónimo (privado o borrado). El fetch por SHA que `bend.sh` hace sobre un checkout vacío (verificado a
  las 15:30 del mismo día: 107 MB, 4,3 s) deja de funcionar: el script falla con exit 3 sin abrir diálogos de
  credenciales. Rutas alternativas, en orden: (1) `BEND_SRC` apuntando a un checkout del commit obtenido por otra vía,
  verificable con `git rev-parse HEAD HEAD^{tree}`; (2) `BEND_BIN=/ruta/a/bend` con el binario del instalador oficial
  (`curl -fsSL https://bend-lang.com/install.sh | sh`, Linux/macOS; el sitio sigue en línea), que debe reportar
  exactamente `bend 2.0.24`; (3) vendorizar el árbol fuente en el repo (decisión pendiente del autor: el README declara
  que el compilador no está vendorizado).

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
bash prooflock/env/check_env.sh      # imprime versiones y PASS/FAIL por cada hello-world
```
El log de la corrida de referencia está en `env/check_env.log`.
