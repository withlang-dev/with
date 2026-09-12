# c-algorithms migration findings

The corpus is pinned to upstream commit
`23d453792ed89a28ed7d2c8d4311a4d9f7822edd`. No upstream function body is
changed to accommodate the migrator.

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
