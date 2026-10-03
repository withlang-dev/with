# D83 — In an instance method declared in its type's own module, receiver fields are in scope by bare name; every collision is a shadowing error

**Date:** 2026-10-03. **Status:** BDFL ruling (Eric: direction "C" scoped
to the type's own module, then "blessed" on the words). Spec v7.17:
functions.md §9.5. Extends D7. Issue #1930. **The compiler is
NON-COMPLIANT** until bare field names resolve in own-module instance
methods and every collision is refused.

**Context.** D7 retired the declared receiver, but bodies still wrote
`self.` before every field: 56 of 1,334 o200k tokens in nbody, all in the
field-heavy `mut fn`s that §3.1's no-`&mut` rule pushes code into. With no
local of that name, `self.bodies` has one meaning, so the prefix is a
character the program already determined.

**Decision.** A receiver field is in scope by bare name in an instance
method declared in its type's own module; `self.field` stays valid. A
parameter or local named like a field is a shadowing error (§29.8). A bare
name that names both a field and a global or module-level function is a
shadowing error; `self.field` and the qualified name stay valid. A method
declared in another module reaches fields only through `self.`.

**Census** (Lexer scan of 2,113 files): 18,253 `self.` prefixes removed in
own-module methods; 131 renames (64 parameters, 67 locals) and 16
field/function clashes. 90 of the parameter collisions are one pattern, an
`AstPool` named `pool` beside an `InternPool` field `pool`: same name,
different meaning, the case the error exists for.

**Alternatives rejected.** (A) keep `self.` everywhere: safe, but ceremony
in exactly the code With pushes users into. (B) Swift's rule, local wins
and `self.x` reaches the field: a silent precedence, where adding a
parameter later changes what an existing bare name means. §29.8 already
refuses the collision that makes Swift need a precedence, so no default is
hidden. Extension methods in other modules keep `self.` so a field name
never enters scope across a module boundary the reader cannot see.

**Reopen if** the own-module boundary proves to split real types (the
compiler's own Sema/Codegen are spread across files and keep half their
prefixes), or escaping closures need Swift's explicit-`self` rule.
