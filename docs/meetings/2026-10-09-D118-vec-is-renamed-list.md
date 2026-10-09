# D118 — The growable sequence is `List[T]`; `Vec` names no type

**Date:** 2026-10-09. **Status:** ruled (Eric Hartford). **The compiler,
stdlib, tools, tests and corpora are NON-COMPLIANT** until the rename
campaign below lands.

**Context.** D113 (brackets), D115 (`[first, ..rest]`, O(1) remainder),
D116 (`++`) and D117 (`first()`, `last()`, `rest()`) converged on what most
of With's audience calls a list. Eric proposed renaming `Vec` to `List`.

**References** (verified in `.reference/`):

| Language | Growable array | "list" there |
|---|---|---|
| Vale | `List<E>` over a mutable `Array` (`stdlib/src/collections/list/List.vale`) | the growable array; `Vec<N, T>` is a fixed math vector (`roguelike.vale`) |
| Mojo | `List[T]` (`collections/list.mojo`) | the growable array |
| C# | `List<T>` | the growable array |
| Swift | `Array<Element>` (`Array.swift`) | none |
| Rust | `Vec<T>` | `LinkedList<T>` |
| Zig | `ArrayList(T)` | `SinglyLinkedList`, `DoublyLinkedList` |
| Go | slice `[]T` + `append` | `container/list.List`, doubly linked |
| Scala | `ArrayBuffer`, `Vector` | immutable cons `List` |

With's own SIMD type is already `Vector[N, T]` (§4.3d).

**Ruling (Eric, verbatim).** The proposal: "What we've converged on is what
most of With's audience calls a list. Brackets build it, it grows, it
indexes in O(1), it has first(), last() and rest(), and it concatenates with
++. … It also frees Vec for what it means everywhere else. In numeric code a
vector is a mathematical vector … Two rules for the ruling: No alias. Vec
doesn't remain as a second spelling, or agents will find both and copy
whichever is nearby. Rename cleanly, and let the compiler's error on Vec
suggest List. Do it before the next campaigns land, since D115's offset
work, first/rest and ++ are all about to add new code that names the type."

On the brief: "Bless it. The brief is better than my proposal in all three
of its additions: the two-seed sequence is the only way the rename can
actually happen, leaving Vec permanently unbound so old code keeps getting
the helpful error is right, and naming the UAT fixture before touching it is
exactly the contract working. LinkedList for the STC container is the right
name too, and the Vale precedent (List for the container, Vec for math) is
the strongest citation in the table."

"One gap in step c, and it's the one that will bite. A Lexer-driven rewrite
changes identifier tokens, but a lot of Vec in this tree isn't an
identifier: The migrator emits With source from string templates. … A token
rewrite leaves it alone, and the migrator keeps generating Vec straight into
the corpora after step d makes it an error. Diagnostics and their expected
outputs. … The 406 spec occurrences and the docs are prose, not tokens. So
step c needs a second pass: every string literal and every doc line
containing Vec, listed and reviewed rather than blindly replaced, since some
of those strings will be about other things. Step d is the safety net. Once
Vec is an error, any template still emitting it fails the migrator gate on
the first re-migration, which is a good reason to re-migrate a corpus
immediately after step d instead of waiting."

"Three small additions: Runtime and internal names (rt_vec_*, codegen
helpers) should go in the same sweep unless something external pins them.
Agents read the runtime, and a codebase that says List to users and vec
everywhere inside will keep teaching the old word. Add Vec to the ceremony
census with a target of zero after step d, so a new occurrence fails a lane
rather than waiting for someone to notice. The corpora re-promote as part
of this campaign, per D112's third trigger. A rename that breaks every
corpus is the clearest case that rule was written for."

**Decisions.**
- `List[T]` is the growable sequence; `Vec` is not a second spelling and
  stays permanently unbound (a later math type takes `Vector`, never `Vec`),
  so old code always gets the error that suggests `List`.
- STC's singly-linked list (Phase 3) is `LinkedList`. Derived names follow:
  `SortedVec` → `SortedList`, `VecIter` → `ListIter`, `VecIntoIter` →
  `ListIntoIter`, `VecSlot` → `ListSlot`, `VecRange` → `ListRange`,
  `collect[Vec]` → `collect[List]`.
- The UAT fixture `uat/fixtures/sdl_main.w` (`var bars: Vec[SDL_FRect]`) and
  the examples are updated under this ruling, and the PR says so.

**Campaign.**
a. The compiler accepts `List` as the type beside `Vec`; cut a seed.
b. (The double spelling exists only between the two seeds and is never
   documented.)
c. Rewrite the tree: a Lexer-driven pass over identifier tokens (compiler,
   stdlib, runtime and internal `with_vec_*`/codegen helper names unless
   something external pins them, tools, build layer, tests, examples), then
   a reviewed pass over every string literal and doc line containing `Vec`
   (migrator templates in CImport.w/CiMigrate.w, diagnostics and their
   expected outputs, docs), listed and judged, not blindly replaced.
d. `Vec` becomes an error suggesting `List`; `Vec` joins the ceremony census
   with a target of zero; cut the second seed; re-migrate a corpus at once
   (any template still emitting `Vec` fails there).
e. The corpora re-promote within the campaign (D112, third trigger).

The spec projection lands with this entry (docs/spec swept, reviewed:
Rust's `Vec<T>` and `vec!` stay as Rust; `Vec2`/`Vec3` user math types and
SIMD `Vector` stay). `docs/spec/guide/with_for_ai.md` moves with step a,
since `with init` embeds it and must emit what the compiler accepts.

**What would reopen it.** Nothing short of a reason the name misleads the
users it was chosen for.
