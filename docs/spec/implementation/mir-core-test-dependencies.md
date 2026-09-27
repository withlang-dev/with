# Keep direct MIR validation independent of the compiler driver

The direct malformed-MIR regression initially imported `Mir` and
`Compilation`. Windows x86 run 34552488715 reached all 995 behavior passes,
then failed linking `mir_uninitialized_drop_test.w`:

```
lld-link: error: duplicate symbol: _invalid_parameter_noinfo
>>> defined at libucrt.lib(invalid_parameter.obj)
>>> defined at ucrt.lib(api-ms-win-crt-runtime-l1-1-0.dll)
lld-link: error: duplicate symbol: _wctype
```

`Compilation` imports `compiler.Backend` and its LLVM bridge. Linking the
test as an ordinary program then combines that static SDK's CRT with the
program's DLL CRT. The local full battery also caught this test crossing
the 1 GiB per-target memory gate (macro 1644 MiB, ABI 1390 MiB). Removing
only `Compilation` produces unresolved Sema extension methods: `Mir`'s
diagnostic and snapshot helpers imported the semantic driver too.

`MirCore` now owns the unchanged MIR representation, builders, dataflow,
and validators. `Mir` reexports it and keeps the 23 Sema-dependent adapters.
`SemaTypes` owns the unchanged shared type and borrow tags. The regression
imports `MirCore` and constructs its constant with the core builders,
instead of importing lowering for `gen_zero_operand`. All assertions remain.

The compiler lexer selected the relocated function spans; their bodies were
copied unchanged. The full compiler source passes `check`. The direct test
passes in 1.41 seconds with `/usr/bin/time -l` reporting 242,466,816 bytes
maximum RSS. `nm` on the retained test binary finds
`_validate_ownership_body` and no LLVM/Clang bridge symbols. Native platform
CI and the full stage/fixpoint battery remain required verification.
