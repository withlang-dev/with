# #1102 — declaration provenance in C migration

The migrator exported host SDK macros and its own generated preamble into
shared definitions. The macro values are needed to translate expressions;
their availability for expansion does not make them corpus declarations.

The debugging route was migration output → the shared-declaration emitter in
LLDB → the bridge's recorded source location and system flag. A minimal input
included `SDKs/Fake.sdk/usr/include/system.h`, which defined
`HOST_SDK_CONSTANT 43`, and defined `CORPUS_CONSTANT 7` itself. Its function
returned their sum. The unpatched migrator emitted both public constants,
`HAVE_UNISTD_H` from the preamble, and the host's SDK availability constants.

## Exact branch evidence

The symbol-bearing stage2 compiler at `2d683678` was run under LLDB:

```
breakpoint set -n ci_migrate_shared_decl_add -c "*(unsigned int *) *(unsigned long long *) $x1 == 0x54534f48"
run
bt 4
frame select 1
register read w24 x22 pc
memory read -s4 -fd -c1 `*(unsigned long long *)($x22+32)+$w24*4`
memory read -s1 -fc -c110 `*(unsigned long long *)(*(unsigned long long *)($x22+16)+$w24*8)`
```

The breakpoint condition selects the `HOST` prefix of the name passed in
`x1`. At the stop, the caller was `ci_translate_macros+2328`, PC
`0x1008984f4`, and macro index `w24` was `0x75f`. The session's system flag
was **1**, and its location named the fixture's SDK header at `1:9`.
`ci_translate_macros` had read that flag but reached the integer-macro
`ci_migrate_shared_decl_add` call without excluding system declarations.

Selecting the `HAVE` prefix (`0x45564148`) stopped at macro index 2 with
location `/tmp/with_cimport_macro_tEKdH9:27:9`. This macro came from the
generated preprocessing driver, not a system header or the migrated source.
A system-header filter alone therefore leaves the preamble leak intact.

The capture-table hypothesis in the earlier handoff was false:
`ci_capture_macro_values` and `ci_collect_object_macro_values` retain values
for expansion; `ci_translate_macros` emits declarations by walking the bridge
session directly. Filtering the capture tables would leave the emission bug
and remove values that source expressions need.

The regression matrix also exposed a dependency of project macro declarations
on emitted system macros. `PROJECT_WRAP(x)` calling `HOST_SDK_ADD(x)` was
omitted after filtering. LLDB stopped in `with_cimport_is_name_emitted` with
the name `HOST_SDK_ADD`; stepping out returned `w0 = 0` to
`ci_parse_postfix_expr+1400` (`0x1006ce254`). Its `cbz w21` at `+1424`
selected the empty-expression return. That parser accepted a function-like
macro reference only when its name had already been emitted. The corpus
comparison also exposed `S32OVERFLOW` losing its compound `INT32_MIN`
dependency.

Expanding that dependency exposed the expression parser's grouping bug.
LLDB stopped in `ci_parse_postfix_expr` with the exact input
`(-2147483647 - 1)`; stepping out returned a zero-length string (`x1 = 0`)
to `ci_parse_unary_expr+2632` (`0x100411fb4`). The first line of the postfix
parser stripped the group but then treated its binary expression as a
primary token. A group now restarts expression parsing at the lowest
precedence. Before this correction, the direct `c_import` regressions
`3 * ((x) + 1)` and `(x) + (-2147483647 - 1)` both produced explicit
untranslated-macro diagnostics.

The same-header `c_import` check then exposed callable object aliases:
`#define HOST_ALIAS HOST_SDK_ADD` became a global initialized with a generic
function. Codegen rejected it even when unused. LLDB showed
`ci_object_macro_is_function_alias` returning false for `HOST_SDK_ADD` to
`ci_translate_macros+1320` (`0x1007569b8`): that predicate only queried C
function declarations, while the target was a function-like macro. Callable
macro aliases now resolve to their target macro's replacement list and formal
parameters and use normal function-like emission under their own name. The
test calls these aliases through both migration and `c_import`.

## Fix

The bridge records two origin bits in its existing per-macro flag slot:
system header and preprocessing input. The latter comes from libclang's
`clang_Location_isFromMainFile`, so it does not depend on temporary filenames.
The session layout is unchanged.

`ci_translate_macros` skips either origin **only in migration mode**. Macros
from the included corpus file and project headers still emit declarations.
The capture tables retain all macro values, and ordinary `c_import` continues
to expose macros from its requested headers and inline input. A project may
define a name such as `HAVE_UNISTD_H`; its spelling is not a blacklist entry.

Project function-like macro bodies expand private dependencies before
expression parsing. Replacement uses token boundaries, preserves literals
and preprocessing numbers, substitutes formal arguments, and rescans object
aliases followed by calls. Expansion precedes parsing because a private macro
whose replacement is `x + 1` must retain C's precedence when used in
`3 * MACRO(x)`. Unsupported paste/stringification dependencies retain the
existing untranslated-macro handling rather than emitting a missing call.

`behav_migrate_macro_origins.w` covers system object/function macros,
preprocessing-driver macros, corpus and project-header macros, a project
alias of a system constant, nested function-like dependencies, object aliases
of callable macros, unparenthesized replacement precedence, compound integer
constants, a local redefinition of a preamble macro, execution of migrated
code, and ordinary `c_import` of the same header.

## Iterate verification

The three targeted behavior files pass with the rebuilt stage2 compiler:
`behav_migrate_macro_origins.w`, `behav_c_import_macros_no_cc.w`, and
`behav_c_import_compound_literal_macro.w`. Compiler source checks pass.

PCRE2 and zlib were regenerated through their build actions using this
compiler. PCRE2 translated all 33 source files; zlib translated its 15 library
files and both harnesses. Every generated implementation file remains
byte-identical to the committed corpus. Only `defs.w` changes: private host
macros disappear, and project macro declarations retain or regain their
translated bodies, including PCRE2's `S32OVERFLOW`. The complete PCRE2 bundle
source set and the zlib facade pass source checks after promotion. Full batch
verification is recorded separately by the build's evidence targets.
