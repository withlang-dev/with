# D113 — Brackets make a Vec

**Date:** 2026-10-08. **Status:** ruled (Eric Hartford). **Supersedes** D93
where D93 makes an unannotated, undemanded non-empty literal a fixed array
(§4.3c rule 1). **The compiler is NON-COMPLIANT** until implemented; no
implementation has started.

**Context.** On 2026-10-08 an agent writing build code reached for
`Vec.new()` plus `push` chains, because a literal passed straight to a
`&Vec[str]` parameter was not typed by it and `var v = Vec.new() |> push(..)`
did not infer its element type. Eric asked whether `[]` could simply mean
`Vec`.

**Ruling (Eric, verbatim).**

"can we simply make [] *mean* Vec? and anytime we do [a, b, c, d] we are
creating a Vec?"

"Yes, and it's the right default. It matches what every user expects, it
makes the rule one sentence ("brackets make a Vec"), and every question the
agent tripped on today goes away: a literal passed to a function is a Vec,
var out = [] is an empty Vec, a literal in a for is a Vec."

"Three things to settle so the rule stays simple in practice:"

"1. Cost is the compiler's problem, not the user's. A Vec normally means a
heap allocation, and nobody wants one for for flag in ["-v", "-q"] or a list
passed to a function that only reads it. So the meaning is "a Vec," and the
compiler is free to put a literal that's never grown or kept somewhere
cheaper: on the stack, or in static data if its elements are constants. The
user writes brackets and never sees the difference. This is the same deal as
strings: the semantics are simple, and the representation is chosen
underneath."

"2. Fixed-size arrays still need a way in, because of C. The migrator turns
int table[4] = {1, 2, 3, 4} into With, and that has to stay a fixed array for
layout and FFI. Two ways to keep that: Brackets are a Vec unless the
variable's type says otherwise. let t: [i32; 4] = [1, 2, 3, 4] is an array,
everything else is a Vec. One exception, and it only appears when someone
writes a fixed array type, which ordinary users rarely do. Brackets are
always a Vec, and fixed arrays get their own spelling. Stricter, but every
migrated C table and every fixed buffer pays a second syntax. I'd take the
first. The exception is invisible to anyone who doesn't write [T; N], and the
people who do are exactly the ones who know why."

"3. Element types default the obvious way. [1, 2, 3] is a Vec[i64],
["a", "b"] is a Vec[str], and [] waits for the first push or the first use to
say what it holds."

"So the rule for users is: brackets make a Vec. The rule for the spec adds
one line: unless a fixed array type is demanded. And one line for the
compiler: a literal that's never grown or retained needn't touch the heap."

**Consequences (derived, not ruled).**
- An unannotated `let xs = [1, 2, 3]` is a `Vec` whatever its uses; D93's
  use-demands no longer choose between array and `Vec`. They still give an
  empty `[]` its element type ("waits for the first push or the first use").
- A literal passed straight to a parameter, iterated by `for`, or bound with
  `var out = []` is a `Vec`; the spellings that failed on 2026-10-08 (a
  literal at a `&Vec[str]` argument, `f(&args)`, `Vec.new() |> push(..)`
  inference) are covered by the one rule.
- Another collection is built only where its type is demanded: a fixed array
  `[T; N]` or a set (`HashSet[T]`, `BTreeSet[T]`), wherever that type is
  demanded (an annotation, a field, a parameter, a C-facing signature). The
  migrator's C tables keep their `[T; N]` types.
- The repeat form `[value; N]` follows the same rule: a `Vec` of N elements
  unless a fixed array is demanded.
- Storage is the compiler's choice: a literal never grown or retained may
  live on the stack or in static data, with no observable difference.

**Ruled after the first entry (Eric, 2026-10-08).**
1. *Element default.* Ruled by D114: unsuffixed integer literals default to
   `isize`, "everywhere, including in bracket literals". `[1, 2, 3]` is a
   `Vec[isize]`.
2. *Set literals.* Eric, verbatim: "A, and the brief earns its place: it
   isn't re-asking a settled question, it's caught D113 contradicting itself,
   and that collision is yours to resolve. The closing spec line was my
   narrow wording leaking into the ruling. Fix it to match point 2:"

   "*A bracket literal is a `Vec[T]`, unless the demanded type is another
   collection that can be built from a list, such as a fixed array or a set.
   Then the literal builds that collection.*"

   "That keeps §4.3c rule 1 valid as it stands, matches Swift, and costs
   nothing for anyone who never writes a set type. B would turn valid code
   into errors to make a sentence shorter, which is the wrong trade."

   "**Duplicate constants in a set literal warn.** `["a", "a"]` demanded as a
   set is almost always a typo, and silently deduplicating it hides that."

   "**Whether the list stays closed is a follow-up, not part of this
   ruling.** §4.3c names `Vec`, `HashSet`, `BTreeSet` and fixed arrays.
   Swift's version is open: any collection that declares it can be built
   from a list literal gets bracket syntax, which would cover a user's
   `Deque` or `SmallVec` too. That's the more Withy end state, since a
   library type shouldn't need ceremony a stdlib type doesn't. But it needs
   a mechanism (a trait or declared constructor), so it's its own brief when
   someone actually wants it."

   Clarified (Eric, verbatim): "no we should treate val myvec = ["a", "a"]
   as a valid Vector of size 2.  myvec[0] is "a" and myvec[1] is also "a"".
   The warning is for a set demand only; a `Vec` keeps every element.

   The specification sentence is the corrected one above; the closing line
   "unless a fixed array type is demanded" is withdrawn.

**What would reopen it.** A measured cost that the compiler's storage choice
cannot remove, or a C-facing use where a fixed array cannot be demanded by a
type.
