Fix Runtime Bug Tests
Goal: Fix the 7 tests that compile but crash or produce wrong
output at runtime.
Scope: Targeted fixes in codegen and runtime. Depends on Plan 1
(codegen bugs) being done first — several of these share root causes.
Checklist

 behav_defer — depends on mutable globals fix (Plan 1,
§2.3). After that fix, verify defer with string concatenation
works. If not, investigate defer codegen for allocating
expressions.
 behav_string_interp — depends on string interpolation
fix (Plan 1, §2.4). Should pass after lexer/parser fix.
 behav_vec — rewrite test to use explicit type annotation
(let v: Vec[i32] = Vec.new()). The inference bug is blocked
on generic instantiation (Plan 5). The test should still verify
Vec behavior with explicit types.
 behav_hashmap — same as behav_vec. Rewrite with
explicit type annotations.
 behav_result — depends on ? operator fix (Plan 1,
§2.2). Should pass after codegen fix.
 behav_move — multiple issues:

Fix let x = x + 1 (shadowing disallowed, use var x + mutation)
Depends on closure-in-variable fix (Plan 1, §2.8)
Test move closure if codegen supports it, otherwise remove
that section


 struct_after_main — depends on forward reference fix
(Plan 1, §2.1). Should pass after cycle detection added.

Exit gate
All 7 runtime bug tests pass. Combined with Plan 1 and Plan 2,
this should bring failures from 75 to ~37 (the unimplemented
feature tests).