# Audit — `src/Archive.w`

Status: **COMPLETE** (no findings)
Source revision: `450733e5`
Source SHA-256: `53fb2a1a4b2f57005ee899cdb18a50cbde186fa3d8ce9b64b3cad8225d4ae885`
Lines: 379 (full module read in-session via shell `cat`)

## Scope examined

Pure-With static archive writer: BSD AR with `__.SYMDEF SORTED` (macOS path)
plus GNU indexed variant (`/` symtab + `//` long names) selected when any
member contains ELF symbols. Helpers: LE/BE u32, LE u16/u32/u64 readers with
bounds guards, basename, pad-right, decimal format, BSD name-pad-len,
BSD/GNU member headers, symbol compare + insertion sort, Mach-O (LC_SYMTAB
cmd==2, extern + defined-only) and ELF64-LE (symtab SHT 2/11, GLOBAL/WEAK,
non-UNDEF, non-section/object-symbol) extractors, two archive assemblers,
and pub `create_static_archive` (src/Archive.w:300).

Applicable targets: T13 (ownership/drop), T15 (migration fidelity — N/A, no
migrate logic in module), T22 (spec conformance — AR format invariants).

## Verdict: no finding

- T13 ownership/drop — CLEAN. No `drop`, `move` misuse, or manual free.
  `with_str_clone_ref` used for retained copies at lines 40, 43, 92, 324;
  `move item` at sort-push (src/Archive.w:~134) transfers into result vec
  with tail spill/restore — pattern matches sibling `Vec` move discipline.
  `sorted`, `member_names`, `member_data` passed by `&` ref, never consumed.
  Callers (`src/BuildGraphOps.w:228`, `src/compiler/Link.w:1196`,
  `src/compiler/ConanClient.w:1112`) hold return-code discipline.
- T15 migration fidelity — N/A. No migrate/compat shims in this module
  (grep for migrat|compat|legacy: no hits); nothing to verify.
- T22 spec conformance — CONFORMS on probed invariants: magic `!<arch>\n`,
  `__.SYMDEF SORTED` first member on BSD path, member payloads embedded,
  total size 8-byte padded (probe: 288 bytes, pad8=0). GNU path offsets
  computed from `ar_gnu_member_size` with 2-byte parity padding before
  layout (src/Archive.w:242-292); BSD path pads name field
  (`ar_bsd_name_pad_len`) and body to 8 (src/Archive.w:357-373). ELF/Mach-O
  parsers are bounds-checked (`ar_read_*` return 0 on OOB; every
  section/symtab/strtab walk re-checks `<= data.len()`), unknown/empty
  objects yield zero symbols rather than misindexing.
- Residual note (not a finding): `create_static_archive` treats empty file
  content as unreadable (`data.len() == 0` → error return 1,
  src/Archive.w:306), so a legitimately empty `.o` is rejected; upstream
  `build_graph_create_archive` pre-checks existence and BuildGraph/Link
  never feed empty objects — accepted behavior, no probe pursued.

## Probes (seed compiler `out/bootstrap/bin/with-stage1`)

- P1 `check src/Archive.w` — EXECUTED, `ok`, exit 0.
- P2 archive round-trip (`use Archive`, two text members with `.o` names,
  `create_static_archive("/tmp/ar_probe_out.a", members)`, `run`) —
  EXECUTED, exit 0; output 288 bytes, magic `b'!<arch>\n'`, contains
  `__.SYMDEF` and member payload `hello member one`, size % 8 == 0.
- P3 negative control (member `/tmp/does_not_exist_xyz.o`) — EXECUTED:
  stderr `error: archive: cannot read member: ...`, no output file created,
  `run` exit 0 (top-level `rc` unused so process exit stays 0; failure is
  conveyed via return value, which `BuildGraphOps.w:228-231` checks).
  Two earlier probe drafts with `import Archive` / `Archive::` syntax were
  HELD (parse errors: `expected expression`, `fn main` + top-level conflict);
  corrected to `use Archive` + bare `create_static_archive` per
  `src/BuildGraphOps.w:3,228` and re-ran as P2/P3 above.

READ ONLY: no compiler sources modified. No upstream issues filed.
