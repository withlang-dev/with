# Phase 0 ownership verification

The complexity build action exposed #1122: a `Vec[str]` literal containing
`compiler.clone()` freed the compiler path at the end of the literal's
statement. A subsequent allocation reused that buffer for `compile.stdout`,
and process creation returned 127. `WITH_ALLOC_NO_REUSE=1` preserved the
compiler path and made the action pass.

## Literal transfer

Native allocator proof on the retained `vec-clone-literal` executable:

```
debug-alloc: trap-free hit=1 addr=4295393328 origin=drop#struct __drop_struct_16
panic: debug-alloc: trapped free of watched address
```

The first-free backtrace points to the collection-literal statement through
`with_str_free_drop_origin`. MIR contains `__collection_literal(move _7, …)`
followed by `drop(_7)`. LLDB stopped in
`MirBuilder.lower_collection_literal_call+124` at `MirBody.new_call_args`:
the helper records the moved operands without `consume_moved_operand`.
That omitted the cancellation of their statement-temporary drops. Literal
arguments now use the same transfer bookkeeping as consuming calls.

## Duplicate keys

The expanded fixture then reported two leaks, even with reuse disabled.
Allocator traps resolved one to the third `"red".clone()` in a HashSet
literal. LLDB stopped at
`Codegen.mir_emit_collection_literal_intrinsic_call+1840` with intrinsic 27
and three entries. `LLVMDumpValue` on its callee printed:

```
declare void @with_hashmap_insert(ptr, ptr, ptr, i64)
```

That literal path directly called the raw insertion helper. Ordinary
`MAP_INSERT` already cleaned up unused incoming keys and replaced values;
literals bypassed it. Both paths now call `mir_emit_owned_map_insert`, which
shares the typed duplicate cleanup. The regression includes duplicate owned
set keys and replacement of a map value with a destructor.

## Observing a string field

The other allocator trap stopped in `str_concat_n_copy`, called by
`vector` at the comparison `items[1].text == "second"`. The emitted IR
copies the field with `with_str_concat_n` and never drops the result.
LLDB observed `MirBuilder.lower_bin_op+1208` passing expected type 16
(`str`) to `lower_expr` for a comparison (`w25=1`). The field-read path
mistook comparison type context for an owned demand, creating the copy.

Built-in string comparisons now use the existing observer-operand lowering,
which reads a place and tracks an actual temporary if one is necessary.
Synthetic field copies that are needed for owned demands also register their
statement temporary. Tests exercise equality and ordering on both sides,
including an indexed field in a short-circuit expression.

## Audit coverage

Before these repairs, `audit:all` accepted the use-after-free repro with
11,452 facts and zero violations. The stage1 core-prelude audit also accepted
the two-leak fixture with 2,621 facts and zero violations. Native allocator
and runtime assertions remain required evidence: those audit results did not
establish correct ownership. #1122 records the missing literal-transfer audit
coverage; #1123 tracks the broader missing allocation and cleanup checks.

Local transcripts are under `out/fnabi-validation/`: `vec-clone-address-trap.txt`,
`vec-clone-free-site.txt`, `vec-literal-lowering-proof.txt`,
`collection-literal-leak-first-site.txt`, `collection-literal-leak-second-site.txt`,
`literal-insert-exact.txt`, and `field-comparison-exact.txt`.
