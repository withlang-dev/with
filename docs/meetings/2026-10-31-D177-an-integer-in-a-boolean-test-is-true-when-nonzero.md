# D177 — An integer in a boolean-test context is true when nonzero; no conversion between `bool` and integers anywhere else

**Laws:** 1, 2, 11 (docs/mission.md).

**Date:** 2026-10-31. **Status:** ruled by Eric.

**Ruling (Eric's words).** "I am ok with the user being responsible to
debug this kind of issue, rather than the compiler owning it. With did not
promise to always discover / prevent every error the compiler is capable
of discovering / preventing. if it comes to thoroughness vs convenience I
would choose convenience." The rule: integers are accepted in boolean-test
contexts — the condition of `if`, `while`, `do`-`while`, the operand of
`not`, the operands of `and` and `or` — zero false, every nonzero integer
true, negatives included. The test does not change the expression's type
and establishes no `bool` demand. `and`, `or` and `not` produce `bool`,
short-circuiting as today. There is no conversion between `bool` and an
integer in a `let`, an assignment, a parameter, a return or generic
inference: `let b: bool = n`, `fn ready -> bool: n` and `let n: i32 = true`
stay errors. `bool as <int>` is 1 for `true` and 0 for `false`. An
assignment expression is not refused as a condition (`if rc = next():`
tests the stored value); nothing in With exists only to catch a typo.

**Why (the brief).** The proposal began as "treat integers as booleans"
and split in two. Converting at type boundaries gives inference a second
answer (D93, D126 type literals and locals by use; `List[bool]` versus
`List[i32]`), gives one checker meaning to two layouts, and removes the
information a `bool` return carries; rejected on Law 2. A *test* of an
integer has one meaning (nonzero) and binds nothing. The cost named
against it — `if sqlite3_step(stmt): commit()` compiles under the wrong
polarity — is a logic error the programmer owns: `if rc != 0:` proves
nothing more about what they understood, and a modeled C contract (D51
§63) types the return anyway. What it buys is With's own shape: `if
count:`, `while n:`, `if flags & READY:`, `with -n 'if nr % 2: print(line)'`,
C migrated without `!= 0` noise. Rust, Zig and Swift refuse it; that is
not evidence ("if zig jumps off a cliff I won't jump off").

**Law 11 (new, docs/mission.md).** The compiler guarantees safety, not
correctness of intent. Memory, ownership, undefined behavior in safe code
and type–representation consistency are the compiler's; program logic is
the programmer's. A restriction whose only purpose is to catch a mistake
the programmer might make is refused in favor of the convenience. *Test:
is this restriction needed to keep a guarantee, or does it only protect the
programmer from themselves?*

**Consequence.** Spec §4.2a Boolean Tests carries the words above.
Sema: `check_bool_condition`, the `not` operand and the `and`/`or` operands
accept an integer type and record a truth test on the node
(`truth_test_exprs`); the recorded type is the integer's, never `bool`
(D126: a condition use types no literal). MIR materializes a recorded
truth test as a compare-with-zero before the branch or the logical
operator (Law 3: Sema decided, MIR materializes). Codegen unchanged.
Fixtures: `behav_d177_integer_truth.w` (positive, negative, zero, a
bit test, `not`, `and`/`or` short-circuit, a `while` countdown),
`err_d177_bool_from_int_binding.w`, `err_d177_bool_return_from_int.w`,
`err_d177_int_from_bool.w`; the one-liner matrix gains `if nr % 2:`.
The migrator's `!= 0` on a C truth test is an idiom to retire under this
ruling's campaign (D112: a ruling re-promotes). Compiler hygiene, with
judgment not a sweep: a function that answers yes/no returns `bool`;
`if c: 1 else: 0` is `c as i32` where the number is meant; neither is a
census pattern until reviewed, since some `i32` returns are a C ABI or a
flag word.

**Reopen if:** a truth test ever binds a type (a literal or local typed
`bool` by a condition use), or a program is found where the integer test
and the `bool` test of the same expression disagree.
