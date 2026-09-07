# Audit 002 Reproduction Evidence

All commands below were run from `/home/shawn/workspace2/with` at
`31f77937abad3bc6573df3b71a0c99b605d6ea8e` with
`out/bootstrap/bin/with-stage1`. The stage1 provenance is current-source-bound
as described in [`../009-build-platform-harness-spec/audit.md`](../009-build-platform-harness-spec/audit.md).
No production source, specification, repository test, or build artifact was
modified by this audit.

## Source-call inventory

The inventory helper is itself With source:

```text
rtk out/bootstrap/bin/with-stage1 run docs/audit/results/002-call-return-abi/probes/source_call_inventory.w -O1
```

It reads `src/MirLower.w`, records the enclosing function for every
`TermKind.TK_CALL` occurrence, and distinguishes constructors from readers.
Final output:

```text
sites=85 functions=60 producer_sites=78 producer_functions=53 reader_sites=7 reader_functions=7
```

The command prints all 85 exact `path:line<TAB>function` rows before that
summary. Producer rows are prefixed `P`; reader rows are prefixed `R`.

The corresponding architecture searches were:

```text
rtk tilth '/FnAbi|ArgAbi|compute_fn_abi|push_call_arg|PM_FAT|PM_IGNORE/' --scope src --expand=10 --budget 18000
rtk tilth '/PassMode|PM_DIRECT|PM_INDIRECT/' --scope src --expand=20 --budget 20000
rtk tilth '/internal_abi_needs_sret|internal_abi_needs_indirect_param|target.*windows|is_windows|aarch64|x86_64/' --scope src/Codegen.w --full --budget 24000
```

The first search found only a `FnAbi` word in a `CiMigrate.w` comment. The
second found only `PM_DIRECT`, `PM_INDIRECT`, `PM_INDIRECT_PLACE`,
`arg_pass_mode`, and its declaration-path consumers in `Codegen.w`.

## Native positive matrix

Probe: [`probes/native_matrix.w`](probes/native_matrix.w)

```text
rtk out/bootstrap/bin/with-stage1 check docs/audit/results/002-call-return-abi/probes/native_matrix.w --validate-all -O1
```

```text
validate-all: ok
```

```text
rtk out/bootstrap/bin/with-stage1 run docs/audit/results/002-call-return-abi/probes/native_matrix.w -O1 --debug-alloc --debug-alloc-filter=non-root
```

```text
abi-matrix-ok
```

This covers direct scalar/small/large calls; ignored scalar and large results;
Unit result and Unit parameter; generic free function and generic inherent
method; canonical read/mut/move receivers; named and capturing fat callables;
raw function pointer; dynamic trait call; extern C scalar; explicit early
return; inferred/default return; and a compiled `Never` branch.

Every advertised audit mode was run with:

```text
rtk bash -lc 'for audit_name in calls effects storage pool methods phase mir returns receivers receiver-surface codegen trait-tables all; do echo "AUDIT=$audit_name"; out/bootstrap/bin/with-stage1 analyze docs/audit/results/002-call-return-abi/probes/native_matrix.w "audit:$audit_name" -O1 || exit $?; done'
```

All exited zero. The final outputs included:

```text
call-contract-audit: facts=9595 violations=0 ok
return-consistency-audit: facts=9595 violations=0 ok
codegen-contract-audit: facts=10341 violations=0 ok
compiler-analysis-audit: facts=10344 violations=0 ok
```

Host IR was inspected with `with-stage1 ir ... -O1`. Representative
declarations were:

```text
define internal i32 @scalar(i32 %0)
define internal %Small @small(%Small %0)
define internal %Big @big(%Big %0)
define internal i64 @Counter.read(ptr %0)
define internal void @Counter.add(ptr %0, i64 %1)
define internal i64 @Counter.take(ptr %0)
define internal i32 @apply_scalar({ ptr, ptr } %0, i32 %1)
define internal %Big @apply_big({ ptr, ptr } %0, %Big %1)
define internal %Big @apply_raw(ptr %0, %Big %1)
define internal %Big @Shift.transform(ptr %0, %Big %1)
define internal %Big @apply_dyn({ ptr, ptr } %0, %Big %1)
declare i32 @abs(i32)
```

Unit is not ignored by the LLVM internal ABI:

```text
define internal i32 @unit_value()
define internal void @accepts_unit(i32 %0)
```

That is positive caller/callee agreement, but it confirms the absence of D6's
`Ignore` result/parameter projection.

## Target IR projections

Windows x86_64 projection:

```text
rtk bash -lc 'out/bootstrap/bin/with-stage1 ir docs/audit/results/002-call-return-abi/probes/native_matrix.w --target x86_64-pc-windows-msvc -O1 | out/bootstrap/bin/with-stage1 -n '\''if line.starts_with("define") and (line.contains("@scalar") or line.contains("@small") or line.contains("@big") or line.contains("@Counter") or line.contains("@apply_") or line.contains("@Shift") or line.contains("identity__sema")): print(line)'\'''
```

Representative output:

```text
define internal i32 @scalar(i32 %0)
define internal %Small @small(%Small %0)
define internal void @big(ptr sret(%Big) %0, ptr %1)
define internal i32 @apply_scalar(ptr %0, i32 %1)
define internal void @apply_big(ptr sret(%Big) %0, ptr %1, ptr %2)
define internal void @apply_raw(ptr sret(%Big) %0, ptr %1, ptr %2)
define internal void @Shift.transform(ptr sret(%Big) %0, ptr %1, ptr %2)
define internal void @apply_dyn(ptr sret(%Big) %0, ptr %1, ptr %2)
define void @"identity__sema__673:6659:151=108"(ptr sret(%Big) %0, ptr %1)
```

The corresponding call instructions use the same visible shapes, including
`call void @big(ptr sret(%Big) ..., ptr ...)` and
`call void @apply_raw(ptr sret(%Big) ..., ptr ..., ptr ...)`.

Darwin arm64 projection:

```text
rtk bash -lc 'out/bootstrap/bin/with-stage1 ir docs/audit/results/002-call-return-abi/probes/native_matrix.w --target aarch64-apple-darwin -O1 | out/bootstrap/bin/with-stage1 -n '\''if line.starts_with("define internal") and (line.contains("@scalar") or line.contains("@small") or line.contains("@big") or line.contains("@Counter") or line.contains("@apply_") or line.contains("@Shift")): print(line)'\'''
```

Representative output keeps internal `Big` direct and fat callables as pairs:

```text
define internal %Big @big(%Big %0)
define internal i32 @apply_scalar({ ptr, ptr } %0, i32 %1)
define internal %Big @apply_big({ ptr, ptr } %0, %Big %1)
define internal %Big @apply_raw(ptr %0, %Big %1)
define internal %Big @apply_dyn({ ptr, ptr } %0, %Big %1)
```

These are compile-time target projections, not target execution. This checkout
has no Windows or Darwin runner/runtime environment, so cross-target runtime
behavior remains an irreducible external-host gap.

## Foreign sret positive control

Probe: [`probes/c_export_sret.w`](probes/c_export_sret.w)

Native `check --validate-all` and debug-allocator execution exited zero with
`c-export-sret-ok`. Host, Windows x86_64, and Darwin arm64 IR all contained:

```text
define dso_local void @audit_make_c_big(ptr sret(%CBig) %0, i64 %1)
call void @audit_make_c_big(ptr sret(%CBig) %2, i64 20)
```

The emit-C pipeline also exited zero and printed `c-export-sret-ok`.

## Emit-C supported matrix

Probe: [`probes/emit_c_matrix.w`](probes/emit_c_matrix.w)

```text
rtk out/bootstrap/bin/with-stage1 check docs/audit/results/002-call-return-abi/probes/emit_c_matrix.w --validate-all -O1
rtk out/bootstrap/bin/with-stage1 build docs/audit/results/002-call-return-abi/probes/emit_c_matrix.w --emit-c -O1 -o /tmp/audit002_emit_c_matrix.c
rtk cc -O1 -no-pie -fuse-ld=lld -I runtime /tmp/audit002_emit_c_matrix.c out/bootstrap-lib/rt_core.o out/bootstrap-lib/rt_linux_x86_64.o out/bootstrap-lib/compat_runtime.o out/bootstrap-lib/panic_runtime.o out/bootstrap-lib/regex_runtime.o out/bootstrap-lib/fiber_stubs.o out/bootstrap-lib/cimport_stubs.o -lc -lm -o /tmp/audit002_emit_c_matrix
rtk /tmp/audit002_emit_c_matrix
```

Exit sequence: `0, 0, 0, 0`; final output:

```text
emit-c-matrix-ok
```

The generated C maps `unit_value` to `void`, but still declares
`accepts_unit(int32_t)` and passes a zero-initialized MIR temporary. LLVM maps
the same Unit-returning function to `i32`. Both execute, but their physical Unit
projections are not the same.

## Emit-C negative controls

All negative-control programs succeed natively.

### Raw function pointers

Probes:
[`probes/emit_c_raw_fn_scalar_expected_fail.w`](probes/emit_c_raw_fn_scalar_expected_fail.w)
and [`probes/emit_c_raw_fn_expected_fail.w`](probes/emit_c_raw_fn_expected_fail.w).

For each, `with-stage1 build ... --emit-c` exits zero, but `cc` exits one. The
scalar diagnostic is:

```text
error: incompatible types when assigning to type ‘with_fn_332’ from type ‘int32_t (*)(int32_t)’
error: invalid type argument of unary ‘*’ (have ‘with_fn_332’)
```

The generated body contains:

```text
typedef struct { int32_t (*fn_ptr)(void*, int32_t); void* ctx; } with_fn_154;
int32_t apply_raw__659(with_fn_154 _1, int32_t _2) {
    _3 = _1.fn_ptr(_1.ctx, _2);
}
...
_1 = bump__658;
_2 = ((with_fn_154)((*_1)));
_3 = apply_raw__659(_2, 1);
```

The large-result probe fails the same way with `Big (*)(Big)`.

### Generic inherent method

Probe:
[`probes/emit_c_generic_method_expected_fail.w`](probes/emit_c_generic_method_expected_fail.w).

Native execution exits zero. `--emit-c` exits zero, then `cc` exits one:

```text
error: unknown type name ‘GBox_i32_’
```

The C backend emits declarations, locals, and a method body using `GBox_i32_`
without emitting its type definition.

### Loud unsupported surfaces

- [`probes/emit_c_closure_expected_fail.w`](probes/emit_c_closure_expected_fail.w):
  native exits zero; `--emit-c` exits one with
  `C emission failed: unsupported const kind 7` (`CK_CLOSURE`).
- `test/behavior/sealed_trait_match.w`: native exits zero; `--emit-c` exits one
  with `emit-c does not support dynamic trait downcast`.
- [`probes/cancellation_completion_matrix.w`](probes/cancellation_completion_matrix.w):
  `--emit-c` exits one with `C backend cannot resolve call callee`.

These fail loudly rather than emitting an apparently runnable artifact.

### Known adjacent emit-C drop failure

[`probes/emit_c_drop_known_fail.w`](probes/emit_c_drop_known_fail.w) succeeds
natively. Emit-C and `cc` exit zero, but the binary exits 134 at its assertion.
That is the Drop omission owned by audit 004 and cross-linked by audit 008; it
is not assigned a duplicate Audit 002 finding.

## High-arity boundary

Probes: [`probes/high_arity_127.w`](probes/high_arity_127.w),
[`probes/high_arity_128.w`](probes/high_arity_128.w), and
[`probes/high_arity_129.w`](probes/high_arity_129.w).

Native execution:

```text
127: exit 0, arity-127-ok
128: exit 0, arity-128-ok
129: exit 134, panic: index out of bounds
```

For 129 parameters, `check --validate-all` and `analyze ... audit:calls` exit
zero; `audit:codegen` and `audit:all` hit the panic. Emit-C, `cc`, and execution
all exit zero for 127, 128, and 129. This is MCO-001 in
[`../008-mir-codegen-optimization/audit.md`](../008-mir-codegen-optimization/audit.md),
whose exact bridge root is `src/compiler/LlvmBridge.w:1178-1181`.

## Cancellation/non-value completion

Probe:
[`probes/cancellation_completion_matrix.w`](probes/cancellation_completion_matrix.w).

```text
rtk out/bootstrap/bin/with-stage1 check docs/audit/results/002-call-return-abi/probes/cancellation_completion_matrix.w --validate-all -O1
rtk timeout 10 out/bootstrap/bin/with-stage1 run docs/audit/results/002-call-return-abi/probes/cancellation_completion_matrix.w -O1 --debug-alloc --debug-alloc-filter=non-root
```

Both exit zero. Runtime output:

```text
continued-direct
continued-unit
continued-big
continued-generic
continued-method
continued-closure
continued-raw
continued-dyn
completion-matrix-done
debug-alloc: leak count=0
```

Every continuation line is incorrect: cancellation should not become an
ordinary value-returning completion. The lack of an allocator error for these
trivial result types isolates the control-flow defect from #916's Box invalid
free.

Every advertised audit mode was run with the same loop shown for the native
positive matrix. All exited zero, including:

```text
call-contract-audit: facts=9487 violations=0 ok
return-consistency-audit: facts=9487 violations=0 ok
codegen-contract-audit: facts=10181 violations=0 ok
compiler-analysis-audit: facts=10184 violations=0 ok
```

The existing `test/spec/spec_ss14_11_await_combinator_cancel_joins.w` was also
run through all advertised audits plus `--validate-all`; all exited zero. Its
debug-allocator run exited one with `invalid free`, as independently documented
by audits 001 and 003.
