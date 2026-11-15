# D205 — Runtime contract citations: one short citation per function, of the actual function's documented behavior; the domain-wide reasoning is stated once

**Laws:** 12 (a claim is the programmer's, and is made reviewable), 2 (a
fact is written once: the reasoning for a domain is not repeated on every
row).

**Date:** 2026-11-14. **Status:** ruled by Eric. No specification change:
§31.9 rule 2 already says a citation on an `fn` line covers the clauses
under it. Done 2026-11-14 for the runtime: every `fn` row with a claim in
`rt/*.w` carries its citation, and `build/uncited-claims.tsv` holds every
file at zero, so a new uncited claim is refused (it held 161 for
rt/darwin_aarch64.w, 141 for each Linux file, 25 for each Windows file, 28
for rt/fiber_core_darwin.w). Still uncited: the toolchain's libc contract
(src/compiler/LibcFacade.w), whose text is selected line by line and
cannot yet carry a comment.

**The question.** Nearly every uncited runtime claim is `preserves domain
environ` or `preserves domain locale` on one libc function, and the reason
is the same for every row: POSIX names `setenv`, `unsetenv` and `putenv`
as the functions that alter the environment, and C11 7.11.1.1 names
`setlocale` for the locale. That reasoning is written once above each
contract block. What is a citation for such a row?

**The options weighed.** A: one short line per function naming the
function and what it does, the domain reasoning left where it is. B: a
quotation of each manual page (about 1,200 comment lines). C: a new rule
that a citation on a `domain` line covers that domain's `preserves`
clauses (six comments, and a new row would inherit a justification nobody
checked for it).

**What reopens it.** A proof engine that establishes these effects from
the C library's source: a proved row is no claim and needs no citation.

Eric's ruling follows, as he gave it. Its code block arrived with its line
breaks lost; they are restored here and nothing else is changed.

---

**I choose A, with one refinement: cite the function's documented behavior, and keep the domain-wide reasoning in one place.**

I think this is the right balance between attention to detail and avoiding ceremony.

The purpose of a citation isn't to repeat the entire justification. It's to make the human assertion **traceable, reviewable, and deliberate**.

For example:

```
// POSIX write(2): writes bytes to a file descriptor;
// does not modify the process environment or locale.
fn rt_libc_write
    preserves domain environ
    preserves domain locale
```

The contract header already explains what can invalidate each domain. There's no reason to repeat those rules hundreds of times.

### **Why I wouldn't choose C**

A blanket domain citation has an attractive simplicity, but it removes something valuable: **evidence that each function was individually considered**.

Suppose somebody adds a new libc wrapper six months from now. Under C, it automatically inherits the domain justification.

Under A, that person must identify what the function does and provide a citation.

That's useful friction. Not because the compiler needs to police the programmer, but because a new foreign-function contract is a deliberate assertion of responsibility.

### **Why I wouldn't choose B**

Quoting a manual page at length doesn't provide a stronger guarantee.

A manual page explaining that `write()` writes bytes doesn't mathematically prove that it never modifies the environment.

WCL already has the correct distinction:

- A **proof** is established through compiler analysis.
- A **claim** is something the programmer asserts.
- A **citation** records the basis for the claim.

A citation should never be mistaken for a proof.

Requiring 1,200 lines of quotations would add bulk without meaningfully improving confidence.

### **One refinement I'd insist on**

The citation must describe the **actual function being called on that platform**.

A Darwin/POSIX manual page isn't automatically sufficient for a Windows runtime wrapper. Where appropriate, cite the platform API or the runtime implementation itself.

And don't manufacture citations merely to make the count reach zero. If a particular function's behavior isn't covered by the shared reasoning, examine that function separately.

## **My ruling**

I'd record:

> **Runtime contract citations.** A citation on each function declaration covers its uncited clauses, as §31.9 already specifies. The citation identifies the actual function's documented behavior and the basis for its claimed effects. Domain-wide explanations may be stated once and referenced by individual citations. Manual quotations are not required. A citation makes a human claim reviewable; it does not turn that claim into a compiler proof.

No specification change is needed for this ruling.

The implementation can then replace the temporary citation-count allowances with the existing strict citation requirement once the review is complete.

**This is exactly the kind of detail that makes a language feel well engineered.** Not more words, not less rigor, but the right amount of information in the right place.

Five hundred repeated explanations would be bad design. One blanket assertion would be too easy to misuse. Approximately 300 short, meaningful, function-specific citations strike the right balance.
