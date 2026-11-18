# D208 — A process domain names its writers

**Laws:** D51's test (never infer silently what can create unsafety: a domain
with no stated writers got no race check), 1 (a short list of writers states
once what a `preserves` line on every other function states hundreds of
times).

**Date:** 2026-11-18. **Status:** ruled by Eric; the words are §16.2b.7's.

**Context.** #3127: a C function that returns a pointer into its own static
array (`curl_version`, `strerror`) hands out a view of state its next call
rewrites. The first rule keyed on the call that returns the view. Eric,
2026-11-18: that keys on the wrong thing; the race is between a holder of a
view and any call that rewrites the state, whether or not that call returns a
view. Two programs fix the meaning: `getenv` on one thread and `setenv` on
another is refused; `main` holding a `curl_version` view while a task calls
`curl_easy_perform` is accepted.

**What was measured.** With the condition on every function of the library
that does not state `preserves domain D` (the default until now), 37 tests
and two release scenarios were refused: libcurl (`curl_easy_init` beside the
version text) and sdl (every SDL call beside `strerror`'s text, because
SDL's headers include libc's). With the condition only on the functions a
domain names, both programs above behaved as ruled and nothing else changed.

**Ruling.**

- A process domain says who rewrites it: `written by f, g`, or `written by
  any`. `written by any` is the conservative rule, for a domain whose writers
  are not known. A domain with neither is a contract error with a fix-it.
  The drafter always writes the list.
- Functions not named preserve the domain.
- A call of a named writer is safe where every call of the domain's writers
  and of the functions returning views of it is provably on one thread, and
  every linked contract either says `runs no threads` or says `preserves
  domain D`. Otherwise it is raw.
- `preserves domain D` at the level of a contract is one line for the whole
  library: its own threads do not rewrite `D`. SDL runs threads, and those
  threads may call `strerror` themselves; the writer list protects against
  the program's calls, not against a linked library's own. Without the line,
  a held `strerror` view in an SDL program is refused, which is correct
  until someone checks.
- A function-local static array is a domain of its own, written by its own
  function; it is not its library's coarse domain (ruled the same day).

**Why not the list as an option.** A hand-written domain without a list would
have had no race check: a silent unsafe default. Making the list mandatory
costs a few lines and closes it now, not in a second pass.

**Alternatives.** A `preserves domain D` line on every function that does not
rewrite it: the same fact, stated once per function; it is what the runtime's
contracts carried (about 550 lines). Keeping the default "every function
rewrites" as the meaning of a bare domain: `written by any` spells it, so the
choice is visible.

**Follow-up, not blocking.** A static array declared thread-local in the
source is drafted as a thread domain.

**Reopen if** a library's writers cannot be listed because they are reached
through function pointers the contract cannot name; `written by any` is the
answer until then.
