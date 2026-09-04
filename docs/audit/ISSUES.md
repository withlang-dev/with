# Audit-filed issues — consolidated index

Scope: every issue filed by the read-only audit at baseline `450733e5`
(50 total: 47 OPEN, 3 CLOSED). Titles/states pulled live via `gh`.
Policy (owner-directed): a filing is closed only after its repro is
re-executed green at the current HEAD; nothing new is filed without
explicit per-issue approval. Close-sweep of `19290044`: zero closures.

Severities: CRIT = silent wrong result / memory unsafety in a shipped
path. HIGH = crash, panic, miscompile, or safety-hole with a loud
symptom. MED = wrong diagnostic, unusable documented API, testing gap.
LOW = stale dev tooling/tests/docs/comments.

## Read first (CRIT, cross-module)

- #1009 OPEN [stdlib/regex] `std.regex` matching universally false (even
  literal) + `replace` panics heap-limit. Stdlib confidently wrong.
- #1061 OPEN [crypto/tls] TLS client authenticates nothing: no cert/SKE
  signature checks, server Finished accepted blind.
- #1051 OPEN [crypto/bigint] `i31_from_monty` silently wrong for moduli
  >= 590 bits (temp only 20 words zeroed).
- #1052 OPEN [crypto/bigint] same fn: fixed temps overflow above 2449
  bits (RSA-3072/4096 admitted by callers).
- #1056 OPEN [crypto/x509] `x509_parse` missing content-bounds validation:
  truncated cert yields escaping offsets, OOB reads downstream.
- #1062 OPEN [crypto/tls] handshake parses wire lengths unclamped
  (cert/hs_len vs record bounds).
- #1049 OPEN [codegen] repeat-init `[v; N>64]` initializes only
  N/sizeof(T) elements; tail left uninitialized.
- #1050 OPEN [codegen] array copy of `[T; N>64]` copies element-count
  bytes, truncating to N/sizeof(T).
- #1064 OPEN [codegen] struct literal stores field value at wrong index
  when a field has generic-struct type (silent clobber).
- #1006 OPEN [codegen/emit-c] hardcoded 32-bit bit-intrinsics: 64-bit
  rotate/byteswap/popcount/clz/ctz/bitreverse miscompile.
- #1003 OPEN [types] out-of-range enum discriminants accepted for
  non-i8/i16 reprs: silent truncation + segfault / silent no-match.
- #1008 OPEN [runtime/process] Linux spawn smashes 124B of stack (4B mask
  vs 128B sigset_t) + 16B sigaction buf vs 152B struct.
- #1000 OPEN [runtime/channel] sync-context send-to-full bounded channel
  silently drops; recv-None conflates open-empty with closed-drained.

## Runtime (fiber/channel/process)

- #1000 OPEN CRIT — see above.
- #1008 OPEN CRIT — see above.
- #995 OPEN HIGH — spawning >1024 live fibers silently yields Tasks that
  await to zero (unchecked -1 fiber_id).
- #999 OPEN HIGH — E0701 suspend-guard false negative: borrow routed
  through an aggregate loses its guard origin (safety hole).

## Compiler frontend (parser/sema/diagnostics)

- #1004 OPEN HIGH — parser contradicts spec §9.9: `|`/`^`/`&` precedence
  inverted; `??` binds looser than `+`/`-` (silent misparse).
- #1010 OPEN HIGH — documented `str.is_empty()` has no intrinsic:
  compiler aborts with internal BUG (core dump).
- #1005 OPEN MED — unterminated string literal at EOF silently accepted
  (`check` rc=0).
- #1019 OPEN MED — generic inference fails for array literal args:
  `iter.count([1,2,3])` uncallable.

## Types, vtables, safety checks

- #1003 OPEN CRIT — see above.
- #999 OPEN HIGH — see above (suspend guard).
- #1002 OPEN HIGH — omitted impl method becomes null vtable slot: dyn
  call traps (rc=133) with zero diagnostic.
- #1007 CLOSED — `Vec.set_i32/set_i64` intrinsics bypassed the
  receiver-mutability check. Fixed by `b9e0e652` (intrinsic retired).

## Codegen (incl. emit-C)

- #1049, #1050, #1064 OPEN CRIT — see above.
- #1006 OPEN CRIT — see above.
- #1059 OPEN HIGH — FixedString `s[i]` silently lowers to undef/trap;
  then-branch falls into else (SIGTRAP/SIGSEGV). Candidate fix
  `af7db8ce` (str element is `u8`) exists but is UNVERIFIED — no
  buildable fresh seed; needs a new-binary repro before close.

## Crypto (bigint/RSA/AEAD/ec/x509/TLS)

- #1051, #1052, #1056, #1061, #1062 OPEN CRIT — see above.
- #1057 OPEN HIGH — `ecdsa_verify_der_sig` panics (DoS) on over-long DER
  signature INTEGERs instead of rejecting.
- #1054 OPEN HIGH — AEAD path dead: `chacha20_poly1305` entry not pub
  and `poly1305_finish` rejected by checker (advertised API unusable).
- #1055 OPEN MED — ec/ecdsa suites stale (unexecutable) and P-256 public
  API header contradicts private visibility.
- #1053 OPEN MED — crypto suites (bigint/rsa/crypto) not executable:
  stale `unsafe:`/`->` void syntax (blocks verification of the CRITs
  above).

## Stdlib (regex/json/random/net/time/iter)

- #1009 OPEN CRIT — see above. Verified NOT fixed at `19290044`
  (match-engine cells byte-identical; facade diffs mechanical only).
- #1060 OPEN HIGH — json writer emits raw control characters;
  conforming parsers reject the output.
- #1058 OPEN MED — `random.range_i32`/`chance` panic on INT32_MIN draw
  (checked `0 - v` overflow); loud edge panic.
- #1018 OPEN MED — `std.time` Duration private but in pub signatures;
  constructors uncallable.
- #1065 OPEN MED — same root, user-facing: documented
  `sleep(Duration.millis(..))` path and example red.
- #1011 OPEN LOW — `std.net` docs contradict implementation (send
  returns -errno not -1; close/v4-only undocumented).

## cimport / LLVM bridge

- #1024 OPEN HIGH — `translate_fn_type` silently substitutes i32 for
  unsupported arg/return types (silent FFI mistype).
- #1025 OPEN HIGH — `wl_cc_x86_thiscall` returns 33, LLVM X86_ThisCall
  is 70 (wrong ABI code).
- #1026 OPEN HIGH — `wl_get_fn_param_type` overflows 128-slot stack
  buffer when count > 128.
- #1023 OPEN LOW — union type decl renders as `<unknown type decl>`
  (no Union branch).
- #1028 OPEN MED — `embed_file` with empty/directory path silently
  embeds empty string.
- #1030 OPEN MED — embedded clang resource set omits `__float_*.h`
  deps of embedded `float.h`.

## Build / SDK / release

- #1031 OPEN MED — `sdk_host_tag_for_platform` missing
  windows-aarch64 branch (paths degrade to `-unsupported`).
- #1032 OPEN MED — SDK packaging splits exclude windows-aarch64
  (unix-branch `.a`/extensionless assumptions fail).
- #1033 CLOSED — `build/zlib_gzip.w` bad `with_str_from_vec_u8` decl
  broke check.
- #1034 CLOSED — release_uat `zlib_main.w` bare `write` without import
  failed check.

## Tests & harnesses

- #1071 OPEN MED — PCRE2 test path broken on Linux: `pcre2test.w`
  unlinkable (`__stdinp/__stdoutp/__stderrp` Darwin-only),
  `test/pcre2_*.w` stale. No runnable regex test on Linux.
- #1063 OPEN MED — `test_tls.w` stale (`unsafe:` syntax); PRF/conn
  checks never run (blocks TLS CRIT verification).
- #1066 OPEN LOW — `lib/test` harness (bench/runner/testing) stale
  and unreferenced.

## Tools (dev-only, all LOW except noted)

All re-verified still broken at `19290044` (identical seed output):

- #1067 OPEN — `rt_in_unit_sweep.w`: top-level `ROOT` invisible in `fn`.
- #1068 OPEN — `sweep_gate_corpus.w`: bare externs, `str`-Copy if.
- #1069 OPEN — four tools stale after the `&str` ABI flip
  (`migrate_d22_copy_views`, `annotate_receivers`, `insert_std_uses`,
  `materialize_predicate`).
- #1070 OPEN — `gen_init_templates.w` documented invocation broken
  (fix: two `unsafe` wraps; blocks template regeneration).
- #1073 OPEN — two more drift-stale tools (`migrate_method_arg_moves`,
  `migrate_seams`).
- #1022 OPEN LOW — two stale `CIS_*` layout comments in `CiIR.w`.
- #1027 OPEN LOW — per-compile DIBuilder finalized, never disposed
  (leak).
