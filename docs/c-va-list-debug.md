# Target va_list verification (#1104)

The handoff's first implementation repaired the SysV storage size but had
additional integration defects. This work uses the ABI/codegen route from
`deep-debugging-tools.md`: minimal programs, target IR, analysis matrices,
and LLDB on the compiler branch. Final battery evidence is pending.

## Type identity

The minimal C input `typedef int my_va_list_counter;` followed by a function
returning that typedef migrated its result to `c_va_list`. LLDB stopped in
`translate_type_recursive_mode`: its `c_strstr(raw_cstr, "va_list")` found
the substring at offset three. The nonzero result reached the early
`c_va_list` return (`translate_type_recursive_mode+144`, PC 0x1006d1ba0 in
the original va-list stage2). `/tmp/with-va-name-lldb.txt` records the input
and branch.

The bridge now follows typedef declarations, elaborated types, and aliases,
using exact builtin declaration names. Pointer and array traversal retain
the original type before canonicalization. Parameter translation handles
the SysV array-decayed tag pointer separately from an explicit `va_list *`.
Structural CiType construction uses the bridge's same identity query.

Full corpus regeneration caught a decomposition regression that the first
alias fixture missed: PCRE2 string-array macros disappeared and project
`NULL` changed to an i8 pointer. A reduced macro pair (`FIRST "hi"`,
`TEXT FIRST "\0"`) reaches libclang's `typeof` probe wrapper.
LLDB observed `clang_getArrayElementType` receive CXType kind 1 (Unexposed)
and return kind 0 (Invalid) to `translate_type_recursive_mode+1184`,
PC 0x10014a2a8 (`/tmp/with-va-macro-array-wrapped-lldb.txt`). The code had
dispatched on the canonical kind but decomposed the original wrapper.
Decomposition now uses the original type when it exposes the selected kind,
and the canonical shape for wrappers. Ordinary nested typedefs retain their
identity. The migration regression also checks array and void-pointer macros.
Regeneration with the corrected stage2 restores every shared definition and
every library implementation byte for byte; the only PCRE2 change is
`pcre2test.w`'s `cfprintf` local becoming `c_va_list`. That generated harness
has been promoted (`/tmp/with-va-shape-pcre2-migrate.log`).
The promoted harness passes `check` (generated-code style warnings remain).
Zlib regeneration is byte-identical to the branch's already promoted corpus,
including its two va_list changes (`/tmp/with-va-shape-zlib-migrate.log`).

## Passing and alignment

The old Sema helper treated every Linux va_list parameter as the caller's
place. LLDB observed `w20=1` after the helper in `Sema.collect_extern_fn`
on `--target=linux_aarch64`; the branch proceeded to
`set_sig_param_value_ref_abi` (PC 0x1002df6b8, then +1712).
`/tmp/with-va-place-branch-lldb.txt` records this. The unmodified IR forwarded
`ptr %0` directly to a C callee, without a copy.

That is correct for SysV x86_64's array typedef but wrong for AAPCS64's
32-byte struct. [AAPCS64 B.4 and §10.1.5](https://github.com/ARM-software/abi-aa/blob/main/aapcs64/aapcs64.rst)
require a caller-allocated copy for a composite larger than 16 bytes.
The local Rust reference corroborates the distinction in
`library/core/src/ffi/va_list.rs`: its SysV array form has the indirect-place
attribute; its AArch64 struct does not.

`FnAbi.fn_abi_c_va_list_uses_caller_place` now classifies only Linux x86_64
as a caller place. Other targets preserve value semantics. Ordinary With
calls use their existing aggregate ABI; foreign AArch64 calls use the
existing C aggregate-copy marshaller. There is no new per-call va_list
marshalling path.

A pointer-projection probe exposed another defect in the shared marshaller:
`va_probe(*args)` on AArch64 emitted `call @va_probe(ptr %0)` directly.
LLDB observed `mir_try_place_ptr_for_ref` return a nonzero operand address
to `mir_emit_call_term+5044` (PC 0x1005a290c); the branch skipped creating
a copy (`/tmp/with-va-copy-branch-lldb.txt`). PM_INDIRECT now creates the
copy explicitly on targets without LLVM's byval attribute. The AST-call
path already allocated a copy; this repairs the MIR path to match it.

`record_codegen_call_argument` previously excluded foreign calls from its
failure verdicts. It now reads the recorded C byval mask, exposes
`needs-copy` in the matrix, and rejects a missing explicit temporary on
targets where LLVM does not supply the copy. The target regression checks
the requirement and the temporary together on AArch64.

The old LLVM representation also used an i8 array. LLDB stopped at
`Codegen.sema_type_to_llvm+960` with `x20=32`, returning from `wl_i8_type`
before the tail call to `wl_array_type` (+992).
`/tmp/with-va-layout-branch-lldb.txt` records that exact path. Its IR loaded
the aggregate with `align 1`, conflicting with TypeLayout's alignment 8.
The shared `c_va_list_llvm_type` helper now uses three or four i64 fields
for Linux, preserving size and alignment in locals and enclosing structs.
Darwin and Windows retain a pointer value.

## Named layout expressions and analysis

`sizeof[c_va_list]()` reached `Codegen.gen_sizeof_alignof` with a zero LLVM
type even though a signature could resolve it. LLDB observed node 23 and
`x0=0` at its conditional branch (+152, PC 0x100729138 in the first dev
compiler). `/tmp/with-va-sizeof-branch-lldb.txt` records this. The named
primitive resolver lacked the newly registered builtin and its frozen
fallback did not supply it. The named resolver now calls the same LLVM
layout helper as a resolved Sema type; it does not duplicate the layout.

The analysis tool initially reported a green host audit when passed a
foreign `--target`. Filed as #1105. LLDB stopped at the call to
`Compilation.analyze_file` from `run_cli+60776` (PC 0x1007efebc): the analyze
branch never parsed or set a target, unlike the adjacent IR branch.
`/tmp/with-va-analyze-target-lldb.txt` records the call path. The driver now
uses the normal target parser and setter. Invalid targets fail explicitly.
The fixed x86_64 matrix reports `value-ref=1` and `place-address`; AArch64
reports `value-ref=0` and value marshalling.

The foreign-export validator also lacked TY_VA_LIST. LLDB observed
`type_is_c_abi_expressible(20, 0)` return zero at
`validate_c_export_signature+160`, PC 0x1009596cc
(`/tmp/with-va-c-export-lldb.txt`). Validation and C header rendering now
recognize va_list, include stdarg.h, and report `c_va_list` in diagnostics.
The SysV array form remains invalid as a C return type, as C arrays cannot
be returned by value; the other target representations can return.

## Explicit remaining limitation: callable-type ABI (#1106)

The MIR snapshot converter was also missing TY_VA_LIST. LLDB observed
`mir_sema_type_to_llvm(20)` return zero to `mir_build_raw_fn_type+692`,
PC 0x10097d750; its fallback substituted i32 for a callback parameter.
`/tmp/with-va-indirect-type-lldb.txt` records that branch. The snapshot
converter now uses the shared layout helper.

Linux va_list calls through a C function pointer need a broader foundation:
`mir_build_raw_fn_type` has only the internal aggregate convention, while
`mir_emit_call_term` reads foreign ABI transforms only for named callees.
A callable-type ABI descriptor must be shared by type construction and
indirect marshalling, including SysV place semantics and C return lowering.
That work is filed as #1106. These calls fail with an explicit diagnostic
until it exists; substituting a correctly sized aggregate alone would
silently use the wrong ABI. Pointer-sized Darwin/Windows callbacks use their
existing direct pointer ABI. This branch does not claim Linux C callback
support for va_list.

Ordinary With function values have the same missing place descriptor on
SysV. The reduced `caller -> indirect(probe, args)` case emitted a call
with `{ i64, i64, i64 }` to a thunk expecting `ptr`. LLDB observed
`internal_abi_needs_indirect_param` return zero at
`mir_build_closure_fn_type+556`, PC 0x10043077c, taking the direct-aggregate
branch at +580 (`/tmp/with-va-with-callback-branch-lldb.txt`). The existing
audit incorrectly accepted it: 124 facts, zero violations
(`/tmp/with-va-with-callback-audit.txt`). #1106 now includes closure types,
named-function thunks, and their audit coverage. This branch rejects SysV
va_list parameters through function values until that descriptor exists;
the other targets retain ordinary With value semantics. The regression
requires both IR generation and the audit to reject the SysV case.

## Regression coverage

### Raw declarations retain signature identity

CI at c8f70c19 failed `behav_c_import_overlay_memchr` with an index panic.
The native compiler reproduces it; `with reduce` preserves four lines:
the c_import declaration, main, a byte array, and the curated memchr call.
LLDB stops in `Sema.sig_param_type+208`, reached through
`Codegen.arg_pass_mode` from `Codegen.declare_extern_fn+372`
(PC 0x1004ae5d8). The caller registers show raw parameter count 3,
signature 244, and parameter index 2. The after-MIR semantic facts identify
signature 244 as the two-parameter curated `memchr`; the original raw
declaration has signature 200, and `__wc_buf_memchr` has signature 243.
The name lookup had selected the later wrapper's signature for the earlier
raw declaration. Evidence: `/tmp/with-memchr-panic-slots.log`,
`/tmp/with-memchr-sema.log`, and `/tmp/with-memchr-reduce.log`.

Sema now records each extern declaration's signature by AST node, and
extern codegen reads that identity before consulting FnAbi. It does not
truncate the parameter loop or infer a replacement calling convention.
The existing memchr and memcmp execution regressions pass; memchr's full
analysis audit reports 11,617 facts and zero violations. Both va_list
regressions also pass with the rebuilt stage2, including all five target
ABI cases. These are local iteration checks, not a complete battery.

### va_list cases

`behav_migrate_va_list.w` generates C fixtures under out/, verifies an
unrelated typedef, a va_list alias and an explicit pointer alias, then
executes mixed integer/floating-point variadic formatting through both
pointer and value calls. Its argument count crosses register capacity.

`behav_c_va_list_target_abi.w` covers all five supported targets: storage
size, enclosing-struct size, alignment, physical field offset, foreign-call
copy versus place behavior, analysis matrices and audits, and rejection of
an invalid analysis target. The compiler's own code does not gain a foreign
export; the generated test program's export tests the foreign ABI.

The updated stage2 passed both regressions, including the AArch64 matrix's
`needs-copy=true` assertion (`/tmp/with-va-audit-target-test.log` and
`/tmp/with-va-audit-migrate-test.log`). Its compiler-wide audit checked
2,509,581 facts with zero violations (`/tmp/with-va-dev-compiler-audit.log`).
The recorded ABI hashes also match `FnAbi.w` and `TypeLayout.w`. These are
iteration results; the committed batch still requires the full stage-chain,
test, seed-compatibility, and move/drop verification.
