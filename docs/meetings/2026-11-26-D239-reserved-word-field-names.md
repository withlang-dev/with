# D239 — A reserved word may name a record field; imported C fields keep their names (delegated)

**Laws:** 1 (what the program has already determined is not written again: `:` in field position and member position after `.` / in `offsetof` determine that a reserved word is a field name).

**Date:** 2026-11-26. **Status:** delegated (D237/D98): D235 (#3132) directed checking whether `type` can be imported under its own name in field position, and Law 1 settles both the parser rule and the §29.11 sentence. Eric vetoes by revert.

**Context.** C headers routinely name struct fields `type`, `in`, `match`, `select` (for example `SDL_Event.type`). Even though member access after `.` already allowed keywords, field declarations, struct literals, struct patterns and `offsetof` did not, forcing `c_import` to rename C fields with a trailing underscore (`type_`).

**Decision.** A reserved word may name a record field wherever position decides it:
- in a record declaration, struct literal, or struct pattern when followed by `:` (`type: i32`, `Ev { type: 3 }`, `Ev { type: t }`);
- after `.` (`e.type`, already allowed);
- as the field argument of `offsetof[T](field)` (`offsetof[c_ev](type)`).

Imported C record fields keep their C names without a trailing underscore (`ci_escape_reserved` no longer runs on field names; functions, types, variables, and bitfield accessor methods keep it). Writing the old `x.type_` spelling produces a diagnostic pointing to `x.type`.

**Implementation.** `Parser.at_field_name` / `expect_field_name` + `offsetof` argument handling; `CImport` field emission and member-access lowering; `SemaCheck` unknown-field help. Tests: `behav_3629_reserved_word_field_names`, `behav_3132_c_names_that_are_keywords`, `err_3132_c_field_named_by_keyword`.
