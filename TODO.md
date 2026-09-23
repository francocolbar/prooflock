# Pending before announcing the repository

The repository is public on GitHub. The commit of 2026-09-23 replaced the earlier `main` (`c1a94db`, whose own
`SHA256SUMS` failed on 8 of its 39 lines) with the reference run of 2026-09-23 and everything it hashes.

- [x] ~~**Copyright holder.**~~ Decided 2026-09-22: Franco Colombo Barceló, in `LICENSE`, `NOTICE`,
      `CITATION.cff` and README §10. Project name: **prooflock** (README §9).
- [ ] **Review with Fable 5.1** of the demand laws (credits exhausted as of 2026-09-23).
- [x] ~~`CITATION.cff`: `repository-code`~~ github.com/francocolbar/prooflock (2026-09-22).
- [ ] On publication: DOI (Zenodo) and ORCID in `CITATION.cff`.
- [ ] Factual-accuracy read by the authors of [S1]/[S2] before the preprint
      (see README §7 and `v3/docs/phase3-safety.md` §0). With it, send questions Q1-Q9 of
      `v3/docs/SUPUESTOS_EVALUACION.md` (section "Preguntas abiertas para JET/UKAEA") to De Tommasi/Neto
      (the RTPS-SC interface, [N1]/[N2]) and to Stephen (the Stop Selector, [S1]). Q4 decides the content
      of the secondary table.
      Rule (2026-09-22): if there is no answer by the preprint rewrite, the parametrised secondary table
      stays as it is, labelled "illustrative" (A-35), and freezing the table at the primary stop (M1) is
      never shipped alone.
- [x] ~~**Commit the reference run of 2026-09-23 with everything it hashes.**~~ Done on 2026-09-23: the untracked
      files the hashes and documents need (`v3/compare_runs.py`, the two new negative tests, the four new documents), a
      root `.gitattributes` with `* -text` (so a clone made with `core.autocrlf=true` keeps the hashed bytes), the removal
      of the stale tracked log `v3/PROOF_JETPROT_LIVE.log`, the regenerated `SHA256SUMS` (42 lines), `v3/results.json`
      and `v3/recheck.json`, and every modified tracked file. Check after cloning: `sha256sum -c SHA256SUMS` gives 42 OK.
      Editor configuration (`.obsidian/`) stays out through this clone's `.git/info/exclude`; on any other clone check
      `git status` before a `git add -A`.
- [x] ~~**Re-run the gate after the code-comment and equivalence fixes of 2026-09-23.**~~ Done on 2026-09-23,
      09:26-09:46 (-03:00); an earlier attempt, started at 06:17, broke off at about 06:23 when the machine restarted
      (`BrokenProcessPool`) and wrote no outputs. `py -3.14 v3/run.py all --full` (default `--jobs`, 12): ok in
      1 199.8 s, every gate check passed (3 PROOF files, the smoke, 12/12 negatives, C5, C2, C3, C6, the 88
      differential runs); `sha256sum -c SHA256SUMS` 42 OK; `bash env/check_env.sh` 13 PASS;
      `py -3.14 v3/compare_runs.py v3 <serial run of 2026-09-22> --list`: the same verdicts, counts, census and
      differential traces over 6 433 leaves, INTEGRITY OK, and differences only in the Bend version and commit, the
      hashes of 17 inputs edited on purpose and of the two gate scripts, the hash of the new `v3/compare_runs.py`, the
      new `C6.equivalence` field (M06: 0 of 924 672, 0 of 12 042 240 and 0 of 1 032 192 cells), the descriptions of
      five mutants (M63, M64, M65, M67, M68) and wall times and run metadata. The committed-run figures and the
      `concretize` comparison of C6 `equivalence` were then carried into the READMEs, `env/SETUP.md`,
      `v3/docs/phase3-*.md`, `LEYES_CATALOGO.md` and `SUPUESTOS_EVALUACION.md`. Rule that stays: never name a run "the
      committed reference run" inside a hashed file, since the run that hashes it is always a later one (the
      `v3/run.py` docstring therefore lists earlier runs only).
- [x] ~~**Re-run the gate after the closing fixes of 2026-09-23.**~~ Done on 2026-09-23, 11:12-11:34 (-03:00). After
      the reference run of 09:26-09:46, seven hashed inputs had changed: `env/check_env.sh` (the Bend version check
      is exact: `bash env/bend.sh version` must exit 0 and print exactly `BEND_VERSION`; the substring match over
      stdout and stderr it replaces passed exactly when `bend.sh` refused), `env/bend.sh` (`--update <commit>` takes
      only a full SHA and rewrites the pin only after the fetch succeeded), `v3/run.py` (refuses to start with
      `BEND_BIN` set; docstring), `v3/compare_runs.py` (exit 2, not 1, on an unreadable input), `v3/recheck.py`
      (docstring), `v3/pymodel/mutants.py` (the description of M65, which lands in the results files) and
      `v3/pymodel/spec_consts.py` (a comment). `py -3.14 v3/run.py all --full` (default `--jobs`, 12): ok in
      1 306.1 s; `sha256sum -c SHA256SUMS` 42 OK; `bash env/check_env.sh` 13 PASS, 0 FAIL;
      `py -3.14 v3/compare_runs.py v3 <copy of the 09:46 run> --list`: 6 445 leaves, INTEGRITY OK, and apart from
      wall times and run metadata differences only in the hashes of `v3/pymodel/mutants.py`,
      `v3/pymodel/spec_consts.py`, `env/bend.sh` and `env/check_env.sh` and in the description of M65 (the hashes of
      the three gate scripts are ignored by design); against the serial run of 2026-09-22, the same 50 difference
      paths as the 09:46 run. Its outputs replaced those of the 09:46 run in item (2) of the commit above, and its
      times were carried into the READMEs, `env/SETUP.md`, `v3/docs/phase3-design.md`,
      `v3/docs/phase3-traceability.md` and `SUPUESTOS_EVALUACION.md`. Checked after the edits, before the run:
      `bash env/check_env.sh` 13 PASS; the same script gives `FAIL bend version` with `BEND_SRC` at a wrong checkout
      (`bend.sh` exit 2) and with a `BEND_BIN` that reports another version (exit 4); `py -3.14 v3/run.py quick` ok
      in 34.0 s.
- [x] ~~**Re-run the gate after the last change to `env/bend.sh`.**~~ Done on 2026-09-23, 12:01-12:22 (-03:00).
      After the run of 11:12-11:34, `env/bend.sh` had changed again (11:59: it no longer fetches into a non-empty
      directory that holds no Bend checkout, exit 2) and so had a comment of `v3/run.py` (11:58).
      `py -3.14 v3/run.py all --full` (default `--jobs`, 12): ok in 1 226.0 s (provenance timestamp
      `2026-09-23T15:01:50Z`); `sha256sum -c SHA256SUMS` 42 OK; `bash env/check_env.sh` 13 PASS, 0 FAIL;
      `py -3.14 v3/compare_runs.py v3 <copy of the 11:34 run> --list`: 6 433 leaves, and apart from wall times and
      run metadata the only differences are the two hashes of `env/bend.sh` (the hash of `v3/run.py` is ignored by
      design); against the serial run of 2026-09-22, INTEGRITY OK and the same 50 difference paths as before. Its
      outputs replaced those of the 11:34 run in item (2) of the commit above, and its times were carried into the
      READMEs, `env/SETUP.md`, `v3/docs/phase3-design.md`, `v3/docs/phase3-traceability.md` and
      `SUPUESTOS_EVALUACION.md`.
- [ ] **`fast_ptn` (P13) in the Python oracle.** The oracle (`v3/pymodel/jetprot_laws.py`) has no copy of this Bend
      law, which would catch directly the first `concretize` probe mutant of C6 `equivalence` (an alarm dropped while
      NB is on; the gate rejects it today only through the `concretize` comparison, on 18 144 differing cells). Adding
      it changes the census (`caught_by_all`, `laws_per_kill`) and the law counts the documents quote, so it needs a
      new `all --full` run.
- [x] ~~**Header of `v3/LAWS_JETPROT_LIVE.bend` (2026-09-23, 12:50).**~~ Lines 3-7 said the two response theorems are
      universal in `hb_max` / `ack_max`; they now say what the READMEs say (checked for 3 and 2 only). A comment, but
      the file is hashed, so the gate was re-run the same day, 12:52-13:13 (-03:00): `py -3.14 v3/run.py all --full`
      (default `--jobs`, 12): ok in 1 222.4 s (provenance timestamp `2026-09-23T15:52:44Z`); `sha256sum -c SHA256SUMS`
      42 OK; `py -3.14 v3/compare_runs.py v3 <copy of the 12:22 run> --list`: 6 445 leaves, INTEGRITY OK, and apart
      from wall times and run metadata the only difference is the hash of `v3/LAWS_JETPROT_LIVE.bend`; against the
      serial run of 2026-09-22, INTEGRITY OK and the same 50 difference paths as before. Its outputs replaced those of
      the 12:22 run in item (2) of the commit above, and its times were carried into the READMEs, `env/SETUP.md`,
      `v3/docs/phase3-design.md`, `v3/docs/phase3-traceability.md` and `SUPUESTOS_EVALUACION.md`.
- [x] ~~Initial commit of the repository.~~ Done 2026-09-19.
