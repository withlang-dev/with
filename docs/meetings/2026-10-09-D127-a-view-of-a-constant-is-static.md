# D127 — A view of a constant is a view of an immutable static; a mutable view of a constant is an error

**Date:** 2026-10-09. **Status:** ruled (Eric Hartford). **The compiler is
NON-COMPLIANT** until implemented.

**Context.** `opt ?? &-1` (in the compiler's own `SemaCheck.w`) views a
literal. The spec did not say what such a view points at or how long it
lives; under "access observes" every view needs a defined origin. Briefed
with D125 (prediction: a view of a static constant of the demanded type,
80%); a review agreed and added that C compilers do the same with string and
constant pools, so migrated code behaves the same.

**Ruling (Eric, verbatim).** "& of a constant - View of an immutable static,
materialized once at the demanded type, static lifetime, mutable view an
error"

**Spec projection (§3.1).** A view of a constant (`&-1`, `&CONST`) is a view
of an immutable static, materialized once at the demanded type, with static
lifetime; it is never a temporary, so `opt ?? &-1` cannot dangle. A mutable
view of a constant is an error.
