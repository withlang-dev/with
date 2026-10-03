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

**Amendment (2026-10-03, spec v7.18; Eric's answers on #1930).**
Governing rule, Eric verbatim: "the rule is nothing is uncallable - if it
is shadowed, there must be a namespace way to reach it". (1) Module
self-name, option A (§18.1): a module names itself by the last segment of
its module path, the `module` header's last segment, else the file's
stem; the self-name is a qualifier only (`name.decl`), and the bare
self-name names nothing. A stem that is not an identifier names itself by
the stem with each non-identifier character replaced by `_` and a leading
digit prefixed with `_` (Eric: "we can default name it according to its
filename"). (2) One clash rule, at the use (§9.5): a bare name that
resolves to a receiver field and to any other name in scope is an error
at that use; `self.field` and the other name's qualified form stay valid.
This replaces the narrower "global or module-level function" sentence.
(3) A destructuring binding is a local binding, so a field-named
destructuring binding is the §29.8 shadowing error. (4) Prelude functions
and bare-callable intrinsics clash like any other name, and each is
reachable as `builtins.name` without a `use` (§18.2), so the clash always
has a qualified way out. A new prelude function or intrinsic can therefore
break a bare use in a user type with a same-named field; the release
runbook carries that note (the fix is `self.` or `builtins.name`). **The
compiler is NON-COMPLIANT** until impl-1930 (PR #2034) lands these rules.
