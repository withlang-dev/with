# D198 — A proof about C is accepted only when the drafter can enumerate everything it depends on; where the library lets the program or the build vary it, it is a stated fact

**Laws:** 4 (docs/mission.md). Ruling §16.2b.2, §16.2b.5, §16.2b.9,
§16.2b.15; D121, D187.

**Date:** 2026-11-09. **Status:** ruled by Eric on the briefs of #3206 and
#3173 (C interop, ownership and safety: not delegable under D98). The
spec words for the in-place resource (#3173 shape B) and for the facts
clause (#3206 shape B) are not written yet; until they are, the compiler
is NON-COMPLIANT in those two places and nothing there is implemented.

**Questions.** The #3116 survey's two largest clusters of raw verdicts:
calls through function-pointer fields (#3206: 1648 functions in 14
libraries) and caller-allocated structs passed by pointer (#3173: 1538
functions in 21 libraries). The briefs are on the issues.

**The sentence for the record (Eric).** *A proof about C is accepted only
when the drafter can enumerate everything the proof depends on; where the
library lets the program or the build vary it, it's a stated fact.*

## Ruling, #3206 (function-pointer fields)

**Shape A, a table the package fills itself: the closed-world proof as
briefed is refused.** Its two conditions are one alias analysis over C,
and the analysis cannot finish: a `memcpy` of the table, a table passed
by pointer to an init function, a pointer to the struct cast to `char *`,
and SDL's own pattern of filling the jump table from a platform function
the host did not compile (an `#ifdef`'d-out unit is the common case, not
the edge). Wrong is a retained argument the checker thinks was observed:
use-after-free in safe code.

The rule that is accepted: **a function-pointer field's callee set is
proven only when the field is written in exactly one place, that place
is a constant initializer or a single assignment of a named package
function, and the containing struct is never passed by address to a
function outside the set the drafter can read. Anything else is a
registry fact.** That accepts glfw's static platform table and leaves
SDL's dynamically filled one to a line in the facts file (SDL does let a
build replace the jump table).

**Shape B, a hook the user may replace: a registry fact, as predicted,
with one addition.** The facts grammar gets `field alloc of Record is
allocator` / `is deallocator`, cited. The addition: where the library
offers a *setter* for the hook (`pcre2_set_memory_management`,
`cJSON_InitHooks`), the facade must mark that setter as mutating the
library's state domain, so every outstanding borrow from an allocation
made under the old hooks is invalidated. Otherwise the registry says
"this is the allocator" and a user swaps it mid-flight.

**Error and progress callbacks: §16.2b.9, as predicted.** libpng's
`error_fn` is a callback the user registered; the retention and argument
rules are already written. The one new sentence: a C library invoking a
user hook from inside an arbitrary API call makes that call reentrant
with respect to the hook's captures (the facade ruling's §47 already says
so). libpng's `longjmp` default is a `setjmp` question, not a callback
one.

## Ruling, #3173 (caller-allocated structs by pointer)

**Shape A, read-only: granted, with the proof tightened.** A `const T *`
to a complete record with retention proven absent is presented as `&T`.
"Retention proven absent" includes *the callee stores no pointer derived
from the parameter*, not only the parameter itself: `&rect->x` kept in a
static is retention.

**Shape A, written: granted.** An out-only record becomes the return
value. An in-out record makes the function a `mut fn` of the record.
Guardrail: only when the record is shape A, meaning no retention. The
brief's own example, `deflate(z_stream *)`, is shape B (`deflateInit`
retains the struct's address) and must not be classified by this rule
though it fits the signature: the rule checks the record against the
producer/destroyer pairs before it offers `mut`.

**Shape B, an init/end resource in caller storage: granted; needs spec
words with care.** A resource whose representation is the record in
pinned With storage, produced by init and dropped by end. The words must
say three things:

- *Pinned* means the With value may not move after init, which is a new
  property. The least invasive answer: the resource is non-movable after
  production (a move is a compile error naming the init), and the
  storage rule "storage values are owned, moved by value" gets an
  exception for in-place resources. The words say which.
- The pair is stated or proven, never named. `inflateInit`/`inflateEnd`
  and `deflateInit`/`deflateEnd` over the same `z_stream` are two
  resources; the drafter can only propose, and `_init`/`_end` suffixes
  are a suggestion, not evidence.
- Between init and end the struct is the resource; before init it is
  bytes. Reading a field of a `ZStream` before init is a type error, not
  a wrong read: the pre-init value is a different type (the
  representation) and init consumes it.

## What follows

- Implementable now, no new spec words: the narrowed shape-A proof for
  function-pointer fields (#3206); the read-only and out-only halves of
  #3173 shape A with the tightened retention proof.
- Waits for Eric's words: the facts clause and the setter's state-domain
  effect (#3206 B); the in-place resource (#3173 B) and, with it, the
  in-out `mut fn` form, whose guardrail depends on knowing the
  producer/destroyer pairs.

**What would reopen it.** A drafter that can finish the alias analysis
(a whole-program points-to result it can show its work for) reopens the
shape-A refusal; nothing else does.

## Amendment, the same day: the words are blessed (spec v7.43)

Eric settled the six points the draft wording left open and wrote the
replacement text, which is §16.2b.5 "Value records", the §16.2b.11
sentence, the sentence appended to §16.2b.3's in-place paragraph, and the
facts-file paragraph of §16.2b.15, verbatim.

1. **Clause words or none: keep the words** (`reads`, `fills`, `updates
   param N`). With no clause, a listed operation taking `const T *` would
   be presented as `&T` on the strength of its spelling, which infers
   non-retention from `const` (Law 4). A hand-written facade over a
   library with no readable source has no proof and needs a way to state
   the fact. Where the source exists, the draft writes the clause and the
   user writes nothing.
2. **`resource R in T`: dropped.** The form already exists: `resource
   InflateStream wraps z_stream` with `init inflateInit(self)`.
3. **`fills` beside a status: the existing rule decides.** With `ok` it is
   `Result[T, E]`; without `ok` the status is uninterpreted, so it is
   `(status, T)`.
4. **Where non-movable lives: nowhere.** §16.2b.3 already pins the
   representation and keeps the resource value movable. The draft's "an R
   is not movable" (and this entry's first reading of "pinned") contradicted
   that and does not land.
5. **One field per line.** Each fact carries its own citation.
6. **The context pointer is stated** (`field memory_data of R is
   context`). A hook setter retains it, and the drafter must not read it
   as an escaping argument.

§16.2b.9 gets no new sentence: its Reentrancy paragraph already covers a
library invoking a registered callback from inside an operation.

Where the first half of this entry and the amendment disagree (the
non-movable resource, `mut fn` for an in-out record), the amendment and
the spec text stand: an `updates` parameter is a `mut` parameter (D172),
the receiver only when the operation is presented as a method of `T`.

**Status of the implementation: NON-COMPLIANT** until the drafter writes
the three clauses from proofs, the facade checker and renderer accept and
present them, and the facts grammar reads the four field roles.
