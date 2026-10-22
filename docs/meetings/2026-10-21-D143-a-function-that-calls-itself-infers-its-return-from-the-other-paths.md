# D143 — A function that calls itself infers its return type from the paths that do not (the ML rule)

**Laws:** 1, 6 (docs/mission.md).

**Date:** 2026-10-21. **Status:** ruled by Eric. **Issue:** #2535 (surfaced
by the quicksort of 2026-10-21). Amends D43; the second half of D141's
scope.

**Ruling (Eric's words).** Infer, by the ML rule. Three things to state
with it: Law 6 still applies — a `pub fn` declares its return type,
recursive or not; the inference is for package-local functions, the same
scope as D141. The re-check must agree — after the independent arms solve
the type and the body is re-checked with it as the demand, the self-call
arms must produce that same type; if they don't, the error should name the
arm that disagrees, not just say "write `->`". Mutual recursion stays
"write `->`" for now, with a message that names the cycle, so the user
sees why.

**Why.** D43 says the reaching arms must have one type and that the
compiler never chooses `Unit` for an arm; a self-call arm has no type yet,
and today's "returns Unit" was the compiler choosing one — a bug under D43
as written. The program has determined the type (`[pivot]` through `++`
forces both self-calls to `List[isize]`), so writing it is Law 1's
failure. Scala 3 refuses ("recursive or overloaded method needs result
type"); C# 7 dropped local-function return inference; Rust, Go, Swift and
Mojo's `fn` write every result type. OCaml, F# and Haskell infer recursion
by unification. With already infers non-recursive returns, so the ML rule
is the with-y option, and Eric asked for it in his own words.

**Consequence.** A package-local function without a return type whose body
calls itself is checked twice: a first, silent pass with its own calls open
(`Never`, which every join and operator takes the other side's type
from) lets the other paths decide the type; the second pass checks the
body under that type as its demand (`[] => []` takes it) and a self-call
path that produces another type is named with the decided type. A body
whose every path calls the function has no type ("write `->`"). A `pub fn`
that calls itself is refused with Law 6's words. Two unannotated functions
that call each other are refused naming the cycle. `++` with a `Never`
operand takes the other side's type, as `+` did. Fixtures
`behav_d143_recursive_inferred_return.w` (the quicksort with no return
type), `err_d143_every_path_recursive.w`, `err_d143_pub_recursive_declares.w`,
`err_d143_mutual_recursion.w`, `err_d143_self_call_path_disagrees.w`.

## Implementation note (2026-10-22)

`with migrate` applies the rule to migrated output: a `pub` C function that
calls itself keeps `-> Unit` whatever its tail reads (STC's quicksort,
`_sort_lowhigh`). Fixture: the `recvoid` case of
`bs_check_migrate_stc_expression_forms` (build/selfhost.w, the migrator
basic tests). Implementation: `ci_migrate_body_calls` (src/CiMigrate.w).
