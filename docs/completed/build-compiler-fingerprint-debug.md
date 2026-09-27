# Compiler identity must survive cache lookups

The Phase 0 complexity action still launched an older native build runner
after the literal ownership repair. Its key contained an empty compiler
component (`<sources>::<config>:0:0`), so changing compilers did not invalidate
that runner.

`build_cache_current_compiler_fingerprint` initialized a global owned string
and returned it by value. Returning that owner reset the global, while leaving
`build_cache_compiler_fingerprint_ready` set. Every subsequent lookup returned
the empty value.

LLDB stopped at `build_cache_current_compiler_fingerprint+200`
(`0x1002e4164` in the retained `c91abf7c` release compiler):

```
stp xzr, xzr, [x19]
before: 0x1054de300: 0x00000001069b4e20 0x0000000000000040
after:  0x1054de300: 0x0000000000000000 0x0000000000000000
```

The caller was `build_cache_graph_key` through
`load_build_graph_from_build_w`. This is normal ownership transfer applied
to a cache that needed to retain its value, not a reason to weaken moves.

The helper now retains its cached string and explicitly clones the value it
returns. The unresolved-executable sentinel is cached too, so both resolution
outcomes have stable keys. The regression checks repeated keys against the
actual executable's fingerprint and checks that a different target keeps that
identity while changing the full key.

The minimal repeated-key program fails before the repair and passes after it.
The permanent regression is
`test/behavior/behav_build_cache_compiler_identity.w`. Local LLDB evidence is
`out/fnabi-validation/compiler-fingerprint-reset-proof.txt`.
