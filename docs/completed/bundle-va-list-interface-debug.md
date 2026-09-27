# c_va_list bundle interface spelling

The zlib bundle failed while exporting `gzvprintf`: the interface emitter
rejected type kind 21. A minimal public function taking `&c_va_list` failed
with the same diagnostic under `build --emit-obj --bundle-corpus std/wi_va
--emit-bundle-interface ...`.

The route was a minimal interface reproduction followed by LLDB on
`BundleEmitter.refuse`. The backtrace reached `BundleEmitter.spell` at
PC `0x1002350a4`, through its reference-type recursion at `0x100234874`.
`src/compiler/BundleInterfaceEmit.w` fell through to its unsupported-kind
branch because it had no `TypeKind.TY_VA_LIST` case. The emitter correctly
failed loudly; its spelling table was incomplete.

Spell that builtin as `c_va_list`, preserving target-dependent layout and
reference shape through the ordinary interface parser. No ABI rules change.
The existing interface fixture now includes a public alias and a borrowed
parameter, so exact interface output and semantic fingerprints cover both.

Validation: the minimal interface builds and has identical source/readback
fingerprints; `wi_demo` matches its expected interface byte for byte and has
identical source/readback fingerprints. Stage1, both PCRE2 and zlib bundles,
stage2, and the stage2 compiler source check pass. Complete final-head tests
remain part of the branch battery. Debugger transcript:
`/tmp/with-bundle-va-lldb.log`.
