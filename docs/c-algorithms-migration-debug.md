# c-algorithms migration findings

The corpus is pinned to upstream commit
`23d453792ed89a28ed7d2c8d4311a4d9f7822edd`. No upstream function body is
changed to accommodate the migrator.

## Assertion macros are expressions, not stringification macros

The allocation-testing framework stopped at its two `assert` expressions.
LLDB on the release compiler observed `ci_is_stringify_macro("assert")`
returning `1`; the caller was `ci_try_expand_stringify_call + 240`.
The incorrect branch was `CImport.w`'s `return true` on any isolated `#`
inside the macro body. Darwin's assertion macro includes `#e` only as an
argument to its failure reporter. It is not a string-valued expression.

The later failure in `CiStmtPool.lower_value_expr_ir + 10824` rejected an
argument because this same classification had converted its enclosing
`assert(...)` source range to text. The debugger showed the alleged callee
as `"result->magic_number == 0x72ec82d2"`. Local transcripts:
`out/phase1-drafts/assert-stringify-proof.txt` and
`out/phase1-drafts/assert-ternary-proof.txt`.

Classification now requires the whole replacement to be `#param`, or one
forwarding call to such a macro. The regression exercises successful and
failing assertions, single evaluation, a diagnostic macro containing `#e`,
and a genuine two-level stringification wrapper. Native verification is
pending the rebuilt compiler; this change alone does not claim the full
upstream test pipeline passes.

The next native stop, on the rebuilt development compiler, was
`CiExprPool.reject_builtin_call`: its arguments were `__builtin_expect` and
`no structural lowering`. The caller was `build_libc_call_value_expr`, whose
final builtin branch rejected a hint supported only by the legacy text path.
The structural path now returns the first operand at the Clang result type.
The hint contract is documented in
[Clang's language extensions](https://clang.llvm.org/docs/LanguageExtensions.html#builtin-expect).

A second stop in `ci_migrate_set_error`, called from
`ci_note_filtered_system_symbol_ref_at` and `lower_literal_or_ref`, named
Darwin's `__assert_rtn` declaration in `_assert.h:63`. The libc surface and
allowlist now include Darwin's reporter and glibc's `__assert_fail`, both
non-returning foreign functions. Discarded conditionals lower to effect
branches, so their void arms never initialize a synthetic value local.
An untranslatable effectful arm propagates failure rather than becoming an
empty block. Native transcripts are `assert-builtin-proof.txt` and
`assert-binding-proof.txt` under `out/phase1-drafts/`; the compiler source
check passes, with rebuilt migration/runtime verification still pending.

After those repairs, the first invalid value IR returned at
`lower_value_expr_ir + 6988` was cursor 897, kind 109 (StringLiteral), with
both result registers zero. Its token text was the enclosing
`assert ( allocated_bytes >= block_size )`; evaluation returned an empty
string. Calling the existing `with_ci_cursor_spelling` in LLDB returned
`"alloc_test_free"`, the real `__func__` literal. Clang 22.1.6's
`clang/tools/libclang/CIndex.cpp:5407` uses `StringLiteral::outputString`
for this query. Literal lowering now reads that authoritative escaped
spelling before attempting source-range recovery. This also preserves
embedded NULs that a null-terminated evaluation result cannot represent.
Transcript: `out/phase1-drafts/assert-literal-proof.txt`.

## Closure bodies must retain concrete specialization types

The retained `behav_generic_closure_reference` test binary crashed at
`rt_memcmp` (`rt_core.w:315`, `ldrb w14, [x11, x10]`, `x11=7`). Its first
integer comparator had reached `with_str_cmp_ref`: the later string
specialization had supplied the types for the earlier integer closure.
The debug allocator reported no invalid free before this wrong-pointer read.

LLDB while compiling the fixture stopped at `MirBuilder.binding_type` for
node 889 and observed reference-to-string type 17. The call chain reached
it from `Codegen.gen_closure + 9456`, which constructs a fresh MirBuilder
during codegen. `lower_concrete_specialization` restores generic AST type
sidecars only while lowering the enclosing function; `lower_closure`
currently retains just an AST marker. This is an unfinished architecture
fix: retain the closure's MIR while that concrete context is active, then
read it in codegen. Proof: `generic-closure-crash-lldb.txt` and
`closure-context-proof.txt` under `out/phase1-drafts/`.

## Reference types at repeated checks and pointer comparisons

The generic comparator closure is checked during specialization discovery and
again before MIR lowering. `check_unary` used `add_type` for `&place`, allocating
new IDs for the same reference type on each pass. LLDB observed `TY_REF(14),
d0=3, d1=0, d2=0` from `check_unary` into `Sema.add_type`; the repeated pass
reached `record_contextual_copy_adjustment+420` with context 73, source node
899, old exact type 137 and new exact type 144. Both types were `&i32`, with
the same pointee, target and post-copy adjustment. Address-taking now uses
`ensure_exact_type`, preserving the existing exact-demand conflict check.

Array pointer elements have exact type `&*mut Node` under D27. `check_binary`
passed that reference type directly as the expected type for the peer `null`.
LLDB in `check_expr+668` observed expected type 140 (`TY_REF`, pointee 53);
type 53 was `TY_PTR`. At +728 the null target was zero, entering the diagnostic
branch. Comparison now uses a shared Copy pointer view's pointee as the null
expectation. The existing builtin operator demand materializes the pointer;
ordinary reference bindings still cannot be initialized with null. The matrix
covers array, Vec and map views and both comparison operand orders.

## Restoring C scopes

`sortedarray_insert` shadows its `data` parameter in an inner block. The
migrated assignment after that block contained `data` followed by eight NUL
bytes. `ci_scope_restore` borrowed the previous name and type from its log,
popped and dropped those entries, then cloned the expired views.

Native debug allocation and `WITH_ALLOC_NO_REUSE=1` isolated the payload.
LLDB stopped at `ci_scope_restore+356`, immediately before the value's
`with_str_free_drop_origin`. The address trap reported
`trap-free hit=1 addr=4797918656 origin=drop#enum __drop_enum_8344`.
At `ci_scope_restore+424`, `with_str_clone_ref` received that same address
and length 12 (`__local_data`). The caller was `CiStmtPool.lower_stmt_ir`
restoring a nested block. Both name and type logs now transfer their popped
entries into the maps. The regression executes nested shadowing with two
different inputs and rejects NUL bytes in the generated source.

## Discarded generic call results

The stable-entry storage prototype removed three owned records. The explicit
transfer dropped once; the two results discarded in `clear()` leaked their
16-byte string allocations. The allocator reported `leak count=2` with
`drops=1`. This was a compiler cleanup defect, not an arena algorithm defect.

LLDB on the compiler stopped at `MirBuilder.lower_method_call+5488` with
result local 3, then at +5568 with operand kind zero (`OK_COPY`). Its stack
ran through `lower_expr_discard`, `lower_while`, and
`lower_concrete_specialization`. Unlike ordinary calls, this branch neither
registered cleanup nor classified the result's ownership. Generic methods,
free functions and builtins now use `call_result_operand` to register the
temporary and produce a move for an owned result. The allocator regression
covers discarded, loop, transferred and retained generic results.

## Generic record layout

The facade's stable-entry prototype exposed `sizeof[StableEntry[T]]()`
failing inside a concrete method, although `sizeof[T]()` worked. LLDB on
the Phase 0 release stopped in `Codegen.resolve_type+948`: node 7425,
kind 29 (`NK_INDEX`), and frozen Sema result zero. The branch at +952
returned zero to `gen_sizeof_alignof+176`. This path never used the active
type bindings that the ordinary `NK_TYPE_GENERIC` path reads.

Both syntax forms now share `resolve_generic_type_nodes`, and struct
instantiation accepts their explicit argument-node list. The native matrix
checks scalar and string payloads, two-parameter records, nested records,
Option, and alignment. It requires the existing resolved type layout;
the facade does not calculate a struct layout itself.

## Named record tags (#1124)

`hash_table_iter_next` initializes a `HashTablePair`. Its underlying tag is
`_HashTablePair`, a named two-field record. `translate_type_recursive_mode`
in `src/compiler/ClangBridge.w` tested `*bare == 95` and returned `c_void`
for all underscore-prefixed tags. LLDB on the retained FnAbi compiler
observed `w8=95`, `x23="_HashTablePair"`, then the branch at
`translate_type_recursive_mode+3008` into the `c_void` return. The caller's
record-initializer lowering had two fields but the translated type `c_void`.

The importer now uses Clang's declaration-anonymity query. A native fixture
exercises underscore-prefixed structs, a nested typedef, a union, and an
aggregate return. The cold whole-corpus migration passes hash-table.c with
this change.

The native fixture then exposed a second filter: `ci_is_system_decl`
classified `_Pair` as system-owned solely because its second character was
uppercase. LLDB observed `_Pair` and `w0=1` at +108, branching to the true
return from `ci_migrate_decl_is_filtered`. The same spelling filter in
`ci_translate_struct` would also discard it. These filters are removed;
the existing source-location filter establishes system provenance.

## Empty statements

Upstream `list.c:120` has the empty body of a traversal loop:
`for (rover = *list; rover->next != NULL; rover = rover->next) ;`.
`CiStmtPool.lower_stmt_ir` returned zero for `CXK_NULL_STMT`, conflating a
valid empty statement with failure. LLDB on the development compiler
observed kind 230 at `lower_stmt_ir+60`, then return `w0=0` into
`lower_for_stmt_ir+428` (`cbz w0` into the bailout).

Empty statements now produce the existing empty block IR. The native
regression covers for, while, do-while and if/else empty bodies, checking
the effects of conditions and increments rather than merely compilation.

## Module paths

Migrating `a-b.c` plus a caller emitted `use probe.a-b`. The parser rejected
the hyphen at column 12. `ci_migrate_source_module_suffix` copied filename
bytes directly, independently of `ci_migrate_directory_output_path`.

Both paths now read one module-name normalization helper. Punctuation
becomes underscores, leading digits gain an underscore, and reserved names
use the existing identifier escape. The directory preflight rejects
collisions, including the generated shared-definitions module, before
translating any file. The regression runs a cross-module call through a
hyphenated filename and a keyword filename, then proves a colliding source
fails without overwriting a destination.
