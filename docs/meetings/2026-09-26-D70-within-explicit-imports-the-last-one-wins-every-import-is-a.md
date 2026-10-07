# D70 — Within explicit imports, the last one wins; every import is a namespace

**Laws:** 1, 9 (docs/mission.md).

**Date:** 2026-09-26. **Status:** BDFL ruling (Eric: "Easy. which comes
last shadows the others." — "BUT there still should be *some* way to get
to the shadowed one, through namespaces." — "default namespace for that,
would be the name of the .h (minus the .h)").

#1221: `use c_import("raylib.h")` and `use std.math` both provide `PI`,
and §18.2's precedence tiers did not order two explicit imports. The
compiler reported "shadowing is not allowed for 'PI'" even when the
program never used `PI`, and a raylib program had no way to reach
std.math's `PI`. Rust lets an explicit `use m::X` shadow a glob; Swift
lets a scoped import beat a module import. The ruling is simpler than
either: order decides, as it does for any later binding. The import
written last shadows the earlier ones; there is no ambiguity error among
explicit imports. A `c_import` is an import. The tiers are unchanged, and
D29's std-fallback ambiguity rule (tier 5) is unaffected. Supersedes the
"a use of an ambiguous name is an error" behavior #1221's first fix took.

The shadowed name stays reachable through the import's namespace, named
by what the compiler already knows: a module import by its last path
segment (`math.PI`, or the full path `std.math.PI`), as Go and Python
name packages; a `c_import` by its header's file name without `.h`
(`raylib.PI`). `use m as n` renames a namespace and is needed only when
two would share a name. Before this ruling no qualified value access
existed at all (`math.PI`, `std.math.PI` and `as` were all rejected);
the compiler is NON-COMPLIANT until it implements the namespaces. #751's
canonical module identity is the foundation this lookup should use.

---
