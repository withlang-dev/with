# Perl-Compatible Regular Expression Conformance Specification

Status: proposed

## 1. Goal

With regular expressions SHALL provide the closest practical compatibility with Perl 5 regular expressions that the bundled PCRE2 engine permits.

The governing rule is:

> **Perl defines the target semantics. PCRE2 provides the matching engine. With must bridge every difference that can reasonably be bridged above PCRE2.**

A behavior is not allowed to differ merely because the initial With regex implementation happened to expose PCRE2 differently.

A difference is acceptable only when all of the following are true:

1. Perl and PCRE2 genuinely differ for the behavior.
2. The difference cannot be faithfully repaired by With's lexer, parser, compile-time pattern preprocessing, wrapper API, capture/state machinery, or match/substitution driver.
3. Repair would require replacing or materially modifying the PCRE2 matching engine, or implementing a broader Perl runtime feature that With intentionally does not possess.
4. The divergence is recorded in the versioned PCRE2 compatibility manifest and covered by a test demonstrating the difference.

There are therefore no undocumented regex incompatibilities.

If a Perl-compatible behavior can be implemented on top of PCRE2, With SHALL implement it.

## 2. Versioned compatibility target

The compatibility suite SHALL pin two versions:

* the bundled PCRE2 version;
* the Perl version used as the differential oracle.

At the time of this proposal, With carries PCRE2 10.47.

The initial Perl oracle SHOULD be Perl 5.44.

An upgrade of either PCRE2 or the Perl oracle SHALL rerun the entire differential regex suite.

The repository SHALL contain a generated or maintained compatibility manifest recording every accepted divergence:

`docs/regex_pcre2_differences.md`

Each entry SHALL identify:

* Perl version;
* PCRE2 version;
* minimal pattern;
* minimal subject;
* Perl result;
* PCRE2 result;
* With result;
* PCRE2 compatibility issue involved;
* whether With bridges the difference;
* if not bridged, why faithful emulation cannot reasonably be implemented above PCRE2.

“PCRE2 is Perl-compatible” is not sufficient justification for an untested behavior.

## 3. Compatibility layers

Regex compatibility consists of four separate layers.

### 3.1 Pattern-language compatibility

The pattern between the delimiters SHALL accept every Perl pattern construct that PCRE2 accepts and SHALL preserve Perl semantics wherever PCRE2 does.

This includes, among other things:

* character classes;
* quantifiers;
* alternation;
* capturing and non-capturing groups;
* named captures;
* numbered and named backreferences;
* lookahead;
* lookbehind;
* variable-length lookbehind to the extent supported by the bundled PCRE2;
* atomic groups;
* possessive quantifiers;
* branch-reset groups;
* conditional patterns;
* recursion;
* subroutine calls;
* backtracking-control verbs;
* `\K`;
* `\R`;
* `\X`;
* Unicode properties supported by PCRE2;
* extended mode;
* PCRE2's Perl-compatible special groups.

With SHALL NOT maintain an arbitrary hand-written whitelist of pattern constructs.

The pattern is passed through to PCRE2 unless With deliberately preprocesses it to reproduce Perl semantics that raw PCRE2 does not reproduce.

### 3.2 Regex-literal and operator compatibility

Perl's regex usability does not come only from its engine. It also comes from the syntax surrounding the pattern.

With SHALL treat this operator surface as part of regex compatibility rather than dismissing it as “Perl syntax.”

### 3.3 Match-state and capture compatibility

Captures, global-match position, failed-match behavior, zero-width matches, and named-capture behavior are part of the observable regex semantics.

They SHALL be tested independently of raw PCRE2 pattern matching.

### 3.4 Text-operation compatibility

Substitution, regex splitting, and transliteration are part of the practical Perl regex/text-processing surface.

They SHALL be included in the parity campaign even where PCRE2 itself does not implement the operation.

---

# 4. Existing With behavior that remains valid

The following existing With features are retained:

```with
let re = /foo+/i

if text =~ /(\w+)=(\w+)/:
    print($1)
    print($2)

if text !~ /^\s*#/:
    process(text)

/foo/g.find_all(text)

/(foo)(bar)/.replace(text, "$2$1")
```

Regex literals remain first-class `Regex` values.

`=~` and `!~` remain operators.

Regex literals remain compiler-validated.

The high-level `Regex` API remains available even when shorter Perl-style surface syntax is added.

PCRE2 extensions MAY remain accessible. Supporting a PCRE2 extension that Perl lacks is not an incompatibility provided it does not change the semantics of valid Perl-compatible patterns.

---

# 5. Current gaps in With

The current implementation has the following With-level compatibility gaps.

| Area                                 | Current With                                         | Required target                                                                             |
| ------------------------------------ | ---------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| Pattern engine                       | PCRE2                                                | Keep PCRE2                                                                                  |
| Basic literal                        | `/pattern/flags`                                     | Keep                                                                                        |
| Pattern syntax                       | PCRE2 syntax                                         | Full bundled-PCRE2 Perl-compatible surface                                                  |
| Match operator                       | `=~`, `!~`                                           | Keep                                                                                        |
| Alternate match delimiters           | missing                                              | support Perl-equivalent `m//`, `m{}`, `m!!`, etc. where grammar permits                     |
| First-class quoted regex             | ordinary `/.../` already yields `Regex`              | functional parity already exists; `qr//` MAY be added as compatibility spelling             |
| Pattern interpolation                | missing/incomplete                                   | implement Perl-equivalent regex interpolation                                               |
| `\Q...\E` interpolation behavior     | raw PCRE2 behavior                                   | bridge Perl behavior in With frontend where possible                                        |
| Literal flags                        | `i m s x g u U`                                      | expose all feasible Perl modifiers                                                          |
| `/xx`                                | missing                                              | implement                                                                                   |
| `/n`                                 | missing                                              | implement no-auto-capture                                                                   |
| `/a`, `/aa`                          | missing                                              | map to closest PCRE2 ASCII restrictions                                                     |
| `/d`                                 | missing                                              | emulate if possible; otherwise registered PCRE2 limitation                                  |
| `/l`                                 | missing                                              | support if PCRE2 locale facilities can reproduce semantics; otherwise registered limitation |
| `/p`                                 | missing                                              | implement pre/match/post capture state                                                      |
| `/g`                                 | exists                                               | correct Perl global-state semantics                                                         |
| `/c`                                 | missing                                              | implement                                                                                   |
| `/o`                                 | missing                                              | implement for interpolated/dynamic patterns                                                 |
| Captures                             | `$0`, `$1`, `$name` in narrow controlled scopes      | Perl-equivalent last-successful-match behavior                                              |
| Captures from dynamic `Regex` values | no magic capture bindings                            | support                                                                                     |
| Captures through compound conditions | deliberately unavailable                             | support where control flow establishes a successful match                                   |
| Unmatched optional capture           | currently flattened toward empty text in magic paths | preserve unset versus empty distinction                                                     |
| Special match variables              | mostly missing                                       | provide Perl-equivalent information                                                         |
| Global position                      | stored on `Regex` object                             | match Perl target-match-position semantics as closely as With's value model permits         |
| Empty global matches                 | manually advance one byte                            | use Perl/PCRE2 next-match rules                                                             |
| Substitution syntax                  | method calls                                         | add concise `s///`-class surface                                                            |
| Non-destructive substitution         | method API                                           | support `/r` semantics                                                                      |
| Expression replacement               | callback API                                         | support concise `/e` equivalent                                                             |
| Transliteration                      | missing                                              | add `tr///` / `y///`-equivalent operation                                                   |
| Regex split                          | basic `Regex.split`                                  | match Perl split semantics                                                                  |
| Empty-pattern reuse                  | missing                                              | implement where syntax permits                                                              |
| Match offsets                        | available through `Match`                            | expose Perl-equivalent last-match offset information                                        |
| Named duplicate captures             | wrapper currently resolves one numeric group         | reproduce Perl behavior to PCRE2's limit                                                    |

---

# 6. Pattern interpolation and quoting

Perl regexes are quote-like operators, not raw PCRE2 pattern strings.

With SHALL support interpolation in regex forms intended to correspond to Perl's interpolating forms.

Conceptually:

```with
let word = "cat"
text =~ /the $word/
```

SHALL construct the same logical pattern that the corresponding Perl expression constructs.

Literal interpolation SHALL preserve regex semantics: interpolated regex values remain regex fragments where Perl treats them as such, while quoted text uses the equivalent of Perl's quoting behavior.

`\Q...\E` requires special handling.

PCRE2 itself treats `$` and `@` literally inside `\Q...\E` because PCRE2 has no language variables. Perl performs interpolation before the regex engine sees the result.

Therefore this difference SHALL be bridged by the With frontend rather than accepted as an engine limitation whenever With interpolation is involved.

Similarly, Perl pattern-level case-conversion escapes and named-character escapes that are processed before or outside the matching engine SHOULD be implemented by With preprocessing when an equivalent PCRE2 pattern can be produced.

The rule is:

> A feature does not become “unsupported by PCRE2” merely because Perl performs it before invoking its regex engine.

If With can transform it into an equivalent PCRE2 pattern, it SHALL do so.

---

# 7. Delimiters and quote-like forms

With's existing `/pattern/` literal remains the preferred ordinary syntax.

For one-liner and Perl compatibility, With SHOULD additionally support alternate delimiters for cases where `/` occurs frequently inside the pattern.

Required compatibility forms include the semantic equivalents of:

```perl
m/foo/
m{foo/bar}
m!foo/bar!
qr/foo/
s/foo/bar/
s{foo/bar}{baz}
tr/a-z/A-Z/
y/a-z/A-Z/
```

Paired delimiters SHALL nest where Perl's corresponding quote-like syntax nests.

Supporting `m{...}` is particularly important for URLs, paths, and HTML patterns because requiring slash escaping introduces unnecessary one-liner verbosity.

`qr//` does not need a separate runtime type: With regex literals are already first-class `Regex` values. It is compatibility syntax over the same type.

---

# 8. Modifiers

## 8.1 Pattern modifiers

With SHALL expose Perl-equivalent behavior for every modifier that can be expressed using the bundled PCRE2 plus frontend logic.

At minimum:

```text
i   case insensitive
m   multiline anchors
s   dot matches newline
x   extended mode
xx  stronger extended character-class mode
n   non-capturing by default
u   Unicode semantics
a   ASCII restrictions
aa  stronger ASCII restrictions
p   retain pre-match/match/post-match information
```

`d` and `l` require explicit compatibility investigation against PCRE2.

PCRE2 documents that it cannot exactly reproduce Perl's context-dependent `/d` character-set behavior. If no faithful wrapper implementation is possible, `/d` SHALL be entered in the compatibility manifest as an engine-bound divergence.

`/a` and `/aa` SHALL use the closest PCRE2 ASCII-restriction options available and SHALL be differential-tested against Perl.

`/l` SHALL use PCRE2 locale facilities if they provide equivalent behavior. Any remaining difference SHALL be explicitly documented and tested.

With's existing uppercase `/U` may remain as a PCRE2 extension, but SHALL be documented as a With/PCRE2 extension rather than a Perl modifier.

## 8.2 Match-operation modifiers

The match operation SHALL support equivalents of Perl's:

```text
g   global / successive matching
c   retain global position after failed match
o   compile interpolated pattern once
```

These are operation semantics, not PCRE2 compile flags.

## 8.3 Substitution modifiers

Substitution SHALL additionally support:

```text
g   replace globally
r   return modified value without mutating source
e   evaluate a statically compiled With expression for replacement
```

A Perl-style `/ee` depends on runtime evaluation of generated source code. Unless With gains a general runtime source-evaluation facility, `/ee` SHALL be recorded separately as a broader dynamic-language capability gap rather than falsely attributed to PCRE2.

---

# 9. Capture semantics

The current direct-condition-only capture rule is not the target.

With SHALL maintain last-successful-match information with semantics as close to Perl as its static type system permits.

A successful match SHALL update match state.

A failed match SHALL behave like Perl with respect to existing match state.

Captures SHALL work for:

```with
text =~ /(...)/
text =~ regex_value

if text =~ /(...)/:
    ...

while text =~ /(...)/g:
    ...

let ok = text =~ /(...)/

let ok = ready and text =~ /(...)/
```

The compiler SHALL NOT make captures unavailable merely because the regex expression was stored in a variable or appeared inside a compound boolean expression.

Control-flow analysis may restrict a capture use when success has not been established, but that is a safety/dataflow question, not a regex-language restriction.

## 9.1 Capture participation

Perl distinguishes:

* a capture that participated and captured `""`;
* a capture that did not participate.

With SHALL preserve that distinction internally and expose a way to test it.

Flattening both states to `""` is not Perl-compatible.

The implementation may use an ephemeral compiler-known capture value, `Option[str]`, or another representation, but observable behavior MUST retain the distinction.

## 9.2 Numbered and named captures

The normal Perl-compatible forms SHALL be available:

```text
$1
$2
...
$name
```

The full match SHALL be available.

Named captures with duplicate names SHALL follow Perl behavior to the extent PCRE2 can represent the pattern.

Where PCRE2 cannot represent Perl's duplicate-number/name topology, that exact case belongs in the engine compatibility manifest.

## 9.3 Additional last-match information

With SHALL expose equivalent information for Perl's useful regex match state, including:

* whole match;
* pre-match text;
* post-match text;
* highest participating capture;
* capture start offsets;
* capture end offsets;
* named-capture lookup;
* all captures sharing a name;
* current global-match position.

Exact punctuation-variable spelling is desirable for one-liner parity where it fits With's grammar, but semantic availability is normative.

---

# 10. Global matching

`/g` is a semantic operation, not merely “find all.”

Perl global matching maintains a current position associated with the matched target and successive matches continue from that position.

With's current Regex-object-local cursor is not the normative model.

The required behavior is Perl's observable behavior:

```text
success with /g       advances match position
subsequent /g         begins from current position
failure               resets position unless /c is active
/c                    preserves position on failure
changing target       uses the target's appropriate match state
```

The exact internal mechanism MAY differ because With strings and places differ from Perl scalars.

However, using two regex values on the same target MUST NOT produce observably incorrect behavior merely because With stored position in the regex object rather than the target match state.

A `pos(...)`-equivalent operation SHALL be available if required to reproduce Perl programs.

---

# 11. Zero-length global matches

Zero-length matching is a mandatory compatibility case.

With SHALL NOT implement global iteration by simply advancing one byte whenever a match has zero length.

That algorithm is incorrect for both Perl compatibility and UTF-8 safety.

The bundled PCRE2's recommended next-match behavior SHALL be used, including the retry rules required after an empty match.

PCRE2 10.47 provides `pcre2_next_match`; the wrapper SHOULD use it or implement its exact algorithm.

This rule applies to:

* `=~ /.../g`;
* `find_all`;
* `captures_all`;
* callback global replacement;
* regex splitting;
* any future regex iterator.

Every one of these APIs SHALL share one tested next-match helper rather than independently reimplement empty-match advancement.

---

# 12. Substitution

With SHALL provide a concise substitution surface equivalent in power to Perl `s///`.

The current method APIs remain available:

```with
re.replace(text, replacement)
re.replace_all(text, replacement)
re.replace_fn(text, callback)
re.replace_all_fn(text, callback)
```

but they are not sufficient for Perl one-liner parity.

A concise syntax SHALL support:

```text
pattern
replacement
global replacement
capture interpolation
mutation of a target place
non-destructive replacement
computed replacement
alternate delimiters
```

The Perl behavioral model is the target.

A destructive substitution returns the substitution count/condition information required to reproduce Perl control flow.

A non-destructive `/r` form returns the new string and leaves the source untouched.

Replacement interpolation SHALL support numbered and named captures.

Computed replacement SHALL make capture values available directly to the replacement expression.

Conceptually:

```with
text =~ s/foo/bar/g
let y = text =~ s/foo/bar/r
text =~ s/(\d+)/$1 + 1/eg
```

Exact parser details may be adapted to avoid ambiguity with existing With syntax, but the resulting one-liner SHALL not require expansion into `replace_all_fn` boilerplate.

---

# 13. Transliteration

Perl `tr///` / `y///` is not a regular-expression engine operation, but it is part of Perl's compact text-processing surface and is required for one-liner parity.

With SHALL provide equivalent transliteration functionality, including equivalents of Perl's applicable transliteration modifiers:

```text
c   complement search set
d   delete characters with no replacement
s   squash repeated translated output
r   return transformed value without mutating source
```

The implementation SHALL handle character ranges and Unicode according to the compatibility profile.

ROT13 and case inversion SHALL not require regex callbacks or manually constructed character maps when they can be expressed as transliteration.

---

# 14. Regex split

`Regex.split` SHALL be audited against Perl `split`.

Current “split wherever the regex matches” behavior is insufficient as a conformance definition.

Compatibility tests SHALL cover:

* positive and zero limits;
* negative limits if exposed;
* leading empty field behavior;
* trailing empty field removal;
* zero-width separators;
* separators containing capture groups;
* captured separators appearing in output where Perl does so;
* empty patterns;
* Unicode patterns;
* empty input;
* separators at the start and end of input.

Where Perl's special `split " "` whitespace behavior is not intrinsically regex behavior, With SHALL nevertheless provide an equally concise `fields()`/split facility for one-liner parity.

---

# 15. Dynamic regular expressions

A runtime-created `Regex` SHALL not lose regex capabilities merely because it is not a literal.

At minimum, dynamic regex values SHALL support:

* matching;
* captures;
* named captures;
* global matching;
* substitution;
* splitting;
* match-position behavior.

Magic capture syntax may require compiler/dataflow support, but dynamic regex values MUST expose equivalent capture information.

Perl-style interpolated regexes SHALL compile at the same logical point Perl would compile them, subject to `/o` semantics.

---

# 16. PCRE2 compatibility differences

PCRE2's compatibility document SHALL be treated as an input to With's implementation plan, not as a blanket waiver.

Each known difference receives one of three dispositions:

```text
BRIDGED
    With compensates above PCRE2 and matches Perl.

ENGINE_LIMITATION
    Exact Perl behavior cannot reasonably be reproduced above PCRE2.

PCRE2_EXTENSION
    PCRE2 supports additional behavior; With may expose it without
    changing valid Perl behavior.
```

The current known classes include:

| PCRE2 difference                                                | With disposition                                                             |
| --------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `.` behavior under non-LF newline conventions                   | configure Perl-compatible newline behavior by default; bridge                |
| smaller/different Unicode-property universe                     | engine/version limitation; upgrade PCRE2/UCD when possible                   |
| quantifiers Perl treats as literals/warnings where PCRE2 errors | frontend compatibility parsing where feasible                                |
| captures inside negative assertions                             | engine limitation unless wrapper can reconstruct Perl result                 |
| Perl `\F \l \L \u \U` preprocessing                             | frontend bridge                                                              |
| Perl `\N{character name}` where PCRE2 lacks it                  | frontend Unicode-name bridge                                                 |
| `\Q...\E` interpolation differences                             | frontend bridge                                                              |
| `(?{ code })`                                                   | engine/language limitation unless exact callout mapping is proven            |
| `(??{ code })`                                                  | engine/language limitation unless exact dynamic-subpattern mapping is proven |
| control verbs inside called subpatterns                         | engine limitation                                                            |
| repeated-capture final-state differences                        | engine limitation unless reconstructible                                     |
| some duplicate name/number arrangements                         | engine limitation unless frontend rewriting can preserve semantics           |
| warning versus compile-error differences                        | frontend bridge where practical                                              |
| `\K` lookaround behavior                                        | configure PCRE2's Perl-compatible default                                    |
| PCRE2-only pattern options/extensions                           | permitted extension                                                          |
| pattern/match resource limits                                   | engine limitation; configure generous documented defaults                    |
| Perl `/d` character-set semantics                               | likely engine limitation; verify                                             |
| Perl `/a`/`/aa`                                                 | bridge using closest PCRE2 ASCII controls and differential tests             |
| recursive-pattern cases where PCRE2 accepts more than Perl      | PCRE2 extension; valid Perl behavior must remain unchanged                   |
| malformed `\x` warning/recovery differences                     | frontend bridge where feasible                                               |

No row becomes permanently accepted merely because it is listed here.

If a later PCRE2 release closes a difference, the corresponding With exception SHALL be removed.

---

# 17. PCRE2 extensions

With MAY expose useful PCRE2 features not present in Perl.

Examples include PCRE2-specific verbs, partial matching APIs, match limits, and other engine facilities.

Extensions SHALL obey three rules:

1. they must not change the default semantics of a valid Perl-compatible pattern;
2. they must be clearly documented as PCRE2/With extensions;
3. they do not count toward Perl parity coverage.

With's existing `/U` ungreedy modifier is such an extension.

The default compatibility profile remains Perl-oriented.

---

# 18. Unicode and character semantics

The bundled PCRE2 SHALL be built with Unicode support.

With SHALL expose the closest Perl-compatible UTF/UCP behavior available from that PCRE2 release.

The compatibility suite SHALL include:

* Unicode general categories;
* scripts;
* script extensions where available;
* `\X`;
* Unicode word boundaries;
* case-insensitive Unicode matching;
* non-ASCII case folding;
* combining marks;
* supplementary-plane code points;
* malformed UTF behavior where With permits malformed byte strings.

The PCRE2 Unicode version SHALL be reported by the toolchain and recorded in conformance output.

When Perl and PCRE2 use different Unicode data versions, a mismatch attributable solely to the Unicode database is an engine-version divergence, not a With frontend bug.

---

# 19. Diagnostics

For valid Perl-compatible syntax supported by PCRE2, With MUST NOT reject the pattern because of an independent With parser restriction.

For invalid patterns, diagnostics SHOULD identify:

* pattern;
* offset;
* PCRE2 error;
* With preprocessing phase when applicable.

When Perl accepts a construct that raw PCRE2 rejects but With has a compatibility rewrite, the user SHALL see the Perl-compatible behavior rather than the raw PCRE2 error.

When the construct is an accepted engine limitation, the error SHOULD explicitly say that the construct is valid Perl but unsupported by the bundled PCRE2 compatibility profile.

---

# 20. Differential conformance suite

Regex compatibility SHALL be tested against a real Perl executable.

The suite has four lanes:

### A. PCRE2 engine lane

Run the bundled migrated PCRE2 against the upstream PCRE2 corpus.

This verifies that migration has not changed PCRE2.

### B. Shared Perl/PCRE2 pattern lane

For patterns supported by both engines:

```text
pattern + modifiers + subject
    → Perl result
    → With result
```

Compare:

* success/failure;
* whole match;
* every numbered capture;
* participation/unset state;
* named captures;
* start/end offsets;
* global-match sequence;
* match position;
* substitution result;
* substitution count;
* split result.

### C. Known-divergence lane

Every accepted PCRE2 limitation gets a pinned test proving:

```text
Perl result != PCRE2 result
With result == chosen PCRE2-bound result
```

There SHALL be no uncategorized failures in this lane.

### D. With-surface lane

Test behavior PCRE2 does not provide itself:

* interpolation;
* alternate delimiters;
* `m//`;
* `qr//` if provided;
* `s///`;
* `/r`;
* `/e`;
* `tr///`;
* capture-variable lifetime;
* compound-condition captures;
* dynamic-regex captures;
* `/g`;
* `/c`;
* `/o`;
* `pos`;
* special match variables;
* Perl-compatible split semantics.

---

# 21. Corpus strategy

Do not invent a small compatibility suite by hand.

Use, at minimum:

* upstream PCRE2 tests;
* PCRE2's Perl-comparison tests where available;
* targeted cases from `pcre2compat`;
* Perl's documented regex examples;
* every regex appearing in the With one-liner corpus;
* regression fixtures for every discovered mismatch.

A differential test generator SHOULD make it easy to add:

```text
pattern
flags
subject
expected divergence class
```

and execute the case through both Perl and With.

---

# 22. Acceptance criteria

The regex campaign is complete when:

1. Every pattern accepted by both the target Perl and bundled PCRE2 produces the same observable match behavior unless present in the explicit compatibility manifest.
2. Every supported Perl regex modifier has equivalent With behavior.
3. With adds no arbitrary capture-scope restriction.
4. Dynamic and literal regexes expose the same matching power.
5. `/g` and `/c` match Perl's state-machine behavior.
6. Zero-length global matching is correct and UTF-safe.
7. Substitution has concise Perl-equivalent power.
8. Transliteration has concise Perl-equivalent power.
9. Regex splitting passes a Perl differential suite.
10. Every remaining divergence maps to a concrete PCRE2 limitation or a separately named broader With-language limitation.
11. No difference is justified merely by saying “With is statically typed” or “the wrapper currently works this way.”
12. `docs/regex_pcre2_differences.md` contains every accepted exception.
13. The one-liner corpus can use the concise regex surface without working around wrapper verbosity.

---

# 23. Required immediate changes

The first implementation campaign should address these in order:

1. Replace the claim “everything Perl supports” with the precise conformance rule in this specification.
2. Introduce the versioned Perl/PCRE2 differential harness.
3. Centralize global-next-match logic and use PCRE2's correct empty-match algorithm.
4. Fix `/g` state semantics and add `/c`.
5. Remove the direct-literal-only capture restriction.
6. Preserve unset versus empty captures.
7. Add missing feasible pattern modifiers (`xx`, `n`, `p`, `a`/`aa`, etc.).
8. Add pattern interpolation and Perl-compatible `\Q...\E` preprocessing.
9. Add alternate-delimiter `m//`-style syntax.
10. Add concise `s///` semantics, including `g`, `r`, and statically compiled `e`.
11. Audit and correct `Regex.split`.
12. Add `tr///`/`y///`-equivalent transliteration.
13. Generate the initial PCRE2-difference manifest from the compatibility documentation plus differential tests.
14. Re-run the complete With one-liner corpus and classify any remaining regex verbosity as a conformance defect rather than a generic one-liner inconvenience.

---

# 24. Governing principle

The regex layer has one rule:

> **If Perl does it and PCRE2 gives us enough information or machinery to reproduce it, With does it too.**

PCRE2's genuine engine limitations are accepted, explicit, versioned exceptions.

Everything else is ours to fix.
