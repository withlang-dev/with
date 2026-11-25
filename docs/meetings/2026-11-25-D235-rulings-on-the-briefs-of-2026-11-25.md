# D235 — Rulings on the eighteen briefs of 2026-11-25 (ruled)

**Laws:** 4 (ownership, retention and lifetime come from a clause, a profile
or a proof, never from a name) for the proof rules; 1 (what the program has
already determined is not written again) for the presentation rules.

**Date:** 2026-11-25. **Status:** ruled by Eric, as written answers to
`briefs.md` (eighteen briefs covering the twenty issues then labelled
`human attn needed`). Each ruling is also on its issue. #2425 (D216's words)
was not answered: the brief's text was missing when it was read.

**Context.** The briefs gave, for each question, the state, the options,
what other languages do, what the spec says, mission fit and one
prediction. The answers below are the rulings, in the brief's order. Where a
ruling needs normative words that were not blessed as exact text, the words
are brought before they land.

## #3174

**A: both extensions, under the six conditions**, gated on the measuring build. Three conditions on the yes:
- **Fixed point.** The words say which one. 'Retained' is the least fixed point (a retention needs a real store as witness). 'Returns owned' must be grounded: a cycle through the tables cannot prove ownership by assuming it.
- **Per-target verdicts.** The survey was darwin-aarch64 only and GLFW's platform table is filled by different units per platform. 'Every unit of the build was read' holds per build configuration.
- **`holds` is deferred** until the measuring build shows what A leaves undecided. If it comes later it is checked against every store the drafter can see.

Order: the measuring build (changes no verdict), then the proof. #3206 shape 1 and #3176's yyjson misread go with it. Label removed; this is mine.

## #3124

**A: a proof rule, with a fourth condition.** A store of a resource's pointer is not retention when:
1. the store's target is a field of a record reachable only through a field of the resource's own record;
2. the resource's destroyer destroys that record;
3. no function of the package returns that record or a pointer into it, and none stores it anywhere else;
4. **exclusivity:** the owned record is held by this resource only: the field is assigned only a fresh allocation, is never copied to another resource, and the old record is destroyed if the field is overwritten.

Run the rule report-only over the 22 libraries before it changes a verdict. Label removed; this is mine.

## #3175

**A: a parameter (or a pointer derived from it) written through another parameter's slot is returned through that parameter, not stored**, the caller judged by what it passed for the slot. First cut limited to a direct write through the parameter (`*out = p`); `out->field = p` stays a store. Public functions that return a parameter this way stay raw. Label removed; this is mine.

## #3119

**Yes to `case K: fills T`, with one added clause.** The blessed sentence for §16.2b.5:

> A case may state `fills T`: the variadic argument is a pointer to one `T` that the callee writes without reading and does not keep. `T` obeys the rule for `fills` on a fixed parameter. With passes the address of a zeroed `T` and presents the value as the operation's result, under the function's `ok` contract; a function with no `ok` contract cannot state the case.

Label removed; implementation is mine.

## #3120

**A: the borrow.** The handle holds a shared borrow of the retained resource for D194's window; no hidden state in the handle (B would forbid sharing a list between handles, which libcurl allows). I bring the exact §16.2b.5 sentence before landing it. Label removed.

## #3121

**A: `consumes param N` on a producer of the same resource presents `move fn append(s) -> Result[R, E]`, the failure carrying the input back (D59's `FailedWithResource`).** Two requirements: the new §16.2b.4 sentence says the resource in the error is in a good state; the contract names the status for a NULL return, the facade does not invent one. An in-place `mut` presentation can be layered on the same facts later. I bring the sentence before landing. Label removed.

## #3122

- **7a: yes** to the §16.2b.11 words as proposed, plus: 'A second presentation of a producer is itself a producer and is checked as one.'
- **7b:** the version floor is a suffix on the clause: `param 0 fixed null since 7.87.0`. The floor belongs to that claim.
- **7c:** a keyword may follow `rename`, matching the rule after `.`.
- No veto on the `unwrap`/`expect` origins change of #3589.

Label removed; the words, the `since` suffix with its refusal against an older pinned package, and the keyword after `rename` are mine.

## #3128

**9a: C.** `setopt(K, value)` returning `Result` is unconditional (it is the `ok` contract applied). Per-option setters are switched on by one line on the contract, not per case. The issue's example `easy.url(u)?.header_list(h)?` does not work with setters returning `Result[(), E]`: either the setters return the receiver or the example changes, and the §16.2b.5 sentence has to choose; I bring that sentence. **9b** (collect-into-buffer callback): not in scope now. Label removed.

## #2757

**Option 1: mbedtls where openssl cannot be built**, with three conditions:
- the lock records the backend per platform, so a project locked with openssl on macOS shows the difference on linux-aarch64;
- a user can pin the backend, and a pin to openssl gives today's refusal, not a substitution;
- the recipe moves off mbedtls 3.5.0 to the 3.6 line that `with get c.mbedtls` already takes.

Option 3 rejected: the result would depend on whether Perl happens to be installed. Label removed; this is mine.

## #3134

**(b): std.http over a migrated TLS engine**, with the notes of #3593 as the interim; (a) can run beside it. Label removed.

## #3132

**Yes to the ten** (`c_import ephemeral union opaque where dyn gen module global extend`) becoming contextual; `spawn` is dropped; `type` stays reserved. To check on `type`: a member name after `.` may already be a keyword, yet `e.type` is refused and the C field is imported as `type_`. If so, the cheap fix is to import the C field as `type` and allow it in field position only. I bring the §29.11 words as exact text. Label removed.

## #727

**B: refuse after the second half of eliminate-self is ruled and landed.** Two things need not wait and are mine now: the count of contract programs that use the explicit form, and the fix-it shipped as a `fix-ceremony` rewrite (which proves it exact before it backs a refusal). Label removed.

## #3401

**A: a build file's dependencies are read from source.** Two invariants to write into the design: a package is always distributed with its source, and the source a build file reads is checked against the bundle (a hash), so the two cannot be different versions. The other questions were ruled 2026-11-20 (package-bundles.md). Label removed; step 1 continues.

## #2817

**A: `std.complex`, the four compiler-rt helpers as a migrated engine, the libm functions bound from the platform C library first.** Two requirements: `c_import`'s plain `Complex32`/`Complex64` records become the `std.complex` types (one type per meaning), and the by-value ABI of `_Complex` is checked against a two-field record on each supported target. Label removed.

## #3013

**Engine: libspng** (it decodes through zlib, so `std` has one inflate; and the spiral's `--capture` writes a PNG, so the engine needs an encoder). Both properties to be confirmed against the pinned package before promoting. **Yes** to the plan's §18.5d words; **yes** to the spiral's `--capture`. Label removed.

## #2519

**Fold only a plain one-expression body, only when the folded line fits `with fmt`'s existing width (no new number), on by default.** The rule is symmetric: a folded line that no longer fits is unfolded, so the output does not depend on history. A body that carries a comment is not folded. Label removed; this is mine.

## #2458

**Port `mssql-tds`, module by module; start the value types (`std.decimal`, `std.time`, `std.guid`) now.** TDS runs its TLS handshake inside its own packets, so the security and connection modules depend on #3134's answer (a migrated TLS engine); message, token and datatype modules do not. Entra ID waits until SQL login works. Label removed.

## #2425

The words were not answered: the copy of the brief that was read still had a placeholder where the text goes. The full text is in `briefs.md` now and in the comment above on this issue.

One answer was given, on note 3: **build the `mut` borrow for a facade-resource parameter before landing**, as the ruling asks. A producer with no resource to borrow is recorded as a gap. It matters only for the pointer form with `release`. That part is mine now; the label stays for the words.

