# D184 — A script's top-level binding is a local of the implicit main; a helper that names it captures it

**Laws:** 1, 5, 6 (docs/mission.md); D173.

**Date:** 2026-11-02. **Status:** ruled by Eric, twice: first on the brief
for #2951 (globals assigned in statement order), then amended the same day
when implementing that exposed three consequences (a script binding that
holds a view, a helper shadowing a script binding, by-use typing of script
bindings). The amendment replaces the first ruling; the title keeps the
number. The file name is the first ruling's.

**Ruling (Eric's words, the amendment).** "All three are the same
question: what is a script's top-level binding? Today it's a global that
happens to be written at the top of a file, and all three breaks follow
from that. The alternative is that it's a local of the implicit `main`,
visible to helpers by a rule that says how. The second model is the right
one. A script's top-level binding is initialised in order by running code,
it can hold a view, it's typed by use: every property it has is a local's,
and none is a global's. Python's module scope works this way too, and the
scripts are Python-shaped by design.
- Views: stays a local, no demotion needed. The parser knows what a script
  is, and the binding's class is decided there, once.
- Shadowing: D173's rule, with a line on helper access. A helper's
  parameters and locals shadow script bindings, local winning. A helper
  that names a script binding captures it, so law 5's observe-vs-own rules
  apply; a helper that captures an ephemeral binding is itself
  non-escaping.
- By-use typing: keep it, but bound where the uses come from. Settle each
  script binding from the uses in main up to its last top-level use, then
  check helpers against the settled type. A helper whose use would widen it
  gets an error naming both sites.
- A script binding mutated by a helper is a mutable capture; With does not
  allow that for an escaping closure, and here it is fine because helpers
  do not escape, but it needs saying."

**What it means.** In a file with top-level statements and no `fn main`,
every top-level `let`/`var` is a local of the implicit main: assigned where
its statement stands, able to hold a view, typed by its uses in main up to
its last top-level use (§4.3c, D93, D128). A `fn` in the file that names
one captures it, as a closure captures a binding of its enclosing function:
it observes or mutates the binding and never consumes it (Law 5; mutation is
allowed because a helper does not escape main's frame); a helper that
captures an ephemeral binding is non-escaping, so it cannot be spawned,
stored or returned. A helper's parameters and locals shadow script bindings,
the local winning for every use (D173). A helper is checked against the
settled type; a use in a helper that would widen the type is an error
naming both sites. A read in a helper that runs before the binding's
statement has run is the uninitialized-access error, at compile time where
the call graph shows it. A file with `fn main` has no top-level statements,
and nothing here applies to it.

**Why.** One model instead of three rules. Law 6: a binding's type is
settled where a reader can see it (main), never changed by a helper's body
at a distance. Law 5: a helper's access is a capture, so observe-vs-own
needs no second mechanism. Law 3: the parser decides the class once; no
stage demotes a global to a local by its type.

**Implementation.** Script bindings stay the implicit main's locals (the
pre-2026-11-02 lowering); a helper naming one records a capture in Sema;
captured bindings get storage a helper can reach (hidden to the program),
assigned in statement order; non-captured ones stay plain locals. Typing of
a captured binding is settled from main's uses before any helper body that
reads it is checked. Fixtures: a helper bumping a counter and reading a
`str`; a helper called before the binding's line (compile error); a
parameter shadowing a script binding; a script binding holding a view; a
helper that would widen a binding's type (error naming both sites); a
spawned helper capturing a view (error).

**What would reopen it.** A script that needs a helper to escape main's
frame while holding a script binding (a long-lived task started by a
script); the answer then is the closure rules, not a new class of binding.
