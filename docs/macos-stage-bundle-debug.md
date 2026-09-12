# Cold stage2 loses the embedded bundle (2026-09-09)

The macOS failures in PR #1101, run 34368362224, reproduce locally from
`wo-c4` commit `7910cf98` with a fresh output directory and the pinned
v0.15.2.0 Darwin seed. A VM is unnecessary for this reproduction. Both
the CI runner and the local machine run macOS 26.6.2 (25G83).

## Reproduction and preserved evidence

Worktree: `/Users/eric/.local/with-staging/macos-bundle-stage`.
The seed's SHA-256 is
`79a63ff91d5d9260463adf3e08ff43bdd5446d070eac2ca56ef543ae05484075`.
The cold build used the project's static LLVM 22.1.6 SDK, an empty
`out/`, and these environment settings, with paths rooted in that worktree:

```
WITH=<root>/src/main
WITH_OUT_DIR=<root>/out
LLVM_PREFIX=<root>/.deps/llvm-22.1.6-darwin-arm64
src/main build :stage2
```

The unchanged build reports success. Its stage2 was preserved as
`out/cold-stage2` with its dSYM before rebuilding. It fails both:

- `out/cold-stage2 check src/main.w`: the same `stderr` shadowing and
  argument-type errors as CI, with 78,792 stderr lines.
- Running that compiler's `test tests/one.w tests/two.w` in the existing
  `c4r/out/tmp/pre-d-p7/cli_test_command_args` scratch project: the same ten
  missing `std.re.*` imports as CI.

`nm -n out/cold-stage2` locates all four pcre2 manifest/interface start/end
symbols at `0x1043aa4a0`: both blobs have length zero. The warm c4r stage2
instead has a populated manifest and interface.

## Exact branch

LLDB against the preserved cold stage2, checking scratch `tests/one.w`:

```
breakpoint set -n embedded_bundle_present
run
thread step-out
register read w0 w20 w21
disassemble --start-address $pc --count 3
bt 6
```

At `Compilation.register_embedded_bundle_interfaces`, LLDB reports:

```
w0  = 0x00000000   # embedded_bundle_present(0) returned false
w20 = 0x00000001   # one bundle slot
w21 = 0x00000000   # slot zero
0x100628cf8 <+136>: tbz w0, #0x0, 0x100628ce0
```

That instruction takes the `continue` in `src/compiler/Compilation.w:574`.
The backtrace is `register_embedded_bundle_interfaces` →
`load_link_bundles` → `compile_file` → `run_cli` → `main`.
The generated compiler's DWARF attributes these frames to `main.w:1`;
use function names and disassembly, not its displayed source lines.

A separate LLDB stop in `link_stage_resolve_runtime_root`, while the
bootstrap compiler builds a minimal LLVM caller with the cold output
root, returns `<root>/out/bootstrap-lib` (`x1 = 68`, with the returned
path read from `x0`). The compiler link branch reads
`variant ++ "/embedded_objects.o"` from this root.

Local capture files:

```
/tmp/with-cold-stage2-build.log
/tmp/with-cold-stage2-selfcheck.stderr
/tmp/with-cold-stage2-p7.stderr
/tmp/with-cold-stage2-proof-lldb.txt
/tmp/with-cold-link-root-lldb.txt
```

## Cause

1. Imports fail because no bundle interface was registered.
2. Registration skips the slot because its manifest is empty.
3. Stage2 links the bootstrap embedding object with empty bundle blobs.
4. The cold runtime-root lookup selects `out/bootstrap-lib`; stage2's
   build graph never supplies a populated embedding object of its own.
5. The graph treated `--link-bundle` as sufficient. That option supplies
   declarations and executable code to the current compilation; it does
   not supply embedded data for the resulting compiler's next compilation.

ABI rejection in `link_stage_select_embedded_bundles` cannot explain the
frontend-only `check` failure: that rejection happens later, during linking.
The populated warm compiler was insufficient evidence for a cold build.

## Repair and verification

The stage embedding target reuses the bootstrap runtime blob inputs and
embeds the actual tree bundle. Stage2 and stage3 declare this object as an
input and select it explicitly at link time. Stage1's empty object remains
a separate output, avoiding a dependency cycle or two writers to one file.

The existing selfcheck and scratch-directory CLI test are the regressions.
Verification must run them with a stage2 built from the pinned seed and
empty bootstrap slots. Also check that stage2's manifest/interface lengths
are nonzero, and that an explicitly selected missing embedding object fails
loudly. Full build, fixpoint, and battery evidence is recorded separately;
the repair is not considered verified merely because `:stage2` builds.

The focused verification passed after the repair:

| Check | Cold baseline | Patched stage2 |
|---|---|---|
| Manifest/interface payloads | Both empty | Both nonempty |
| `check src/main.w` | Exit 1, `stderr` collisions | Exit 0, `ok` |
| Scratch-directory CLI test | Exit 1, missing `std.re.*` | One test passed |
| Explicit missing embedding object | No override support | Exit 1 with the missing path |

The patched `:stage2` build used the same pinned seed and bootstrap objects.
Its `out/command/stage2/worker.effects` records the explicit
`WITH_COMPILER_EMBEDDED_OBJECT` environment entry. Captures are
`/tmp/with-fixed-stage2-{build.log,selfcheck.stdout,selfcheck.stderr,p7.stdout,p7.stderr}`
and `/tmp/with-missing-embedding.stderr`.
