# Reference reading for the With specification audit

Status: analysis and editorial recommendations, not adopted language rules.

These notes supplement the [With specification audit](/Users/eric/with/docs/specification-audit-2026-09-26.md). They use the supplied ECMA-334 seventh-edition PDF (December 2023), the Swift compiler repository's documentation, and the published Scala 3.4 specification. Web material was consulted on 2026-09-26; Swift's `main` links are mutable.

This was a focused reading of semantic definitions and specification boundaries, not a cover-to-cover reading of the 699-page C# PDF or every document in the Swift directory. The C# PDF and With's normative specification were left unchanged.

## The distinction With needs

The useful boundary is whether a statement establishes a language contract. Its technical detail, use of pseudocode, or mention of the standard library does not by itself make it implementation material.

A language specification needs to determine:

1. Which source programs are well formed, including required static errors.
2. How expressions, declarations, and control transfers are interpreted.
3. Which observable behaviors an implementation must preserve.
4. Which choices remain unspecified, implementation-defined, or outside the language's guarantees.
5. Which external contracts are necessary to interpret those rules.

An abstract checking algorithm can therefore belong in the core spec. A description of how the current compiler implements that algorithm usually belongs in compiler documentation. Similarly, a library protocol used by language syntax can be normative without making the entire library catalogue part of the language definition.

## C#: the strongest editorial and conformance model here

The supplied edition is a fixed reference, not a claim about every feature of today's C#.

| Clauses examined | What they establish | Application to With |
|---|---|---|
| §§1–5: scope, references, definitions, description, conformance | Syntax, constraints, interpretation, and implementation obligations are in scope. Translation/invocation machinery and system capacity are excluded. Normative and informative text are explicitly distinguished. Dated references do not silently adopt later revisions. | Add an explicit scope and authority policy. Identify which external rulings or contracts are incorporated, and how versions are selected. |
| §7.10: execution order | Observable side effects and ordering constraints bound permitted execution changes. | Describe what an optimization must preserve; do not base safety on an assertion that an optimizer cannot make harmful mistakes. |
| §§9.4.1–9.4.4: definite assignment | Assignment status is determined by specified static rules, including control-flow joins. It is not whatever an implementation happens to prove safe. | Borrow/origin checking, move state, and contextual Copy need defined acceptance rules. Conservative rejection can be an intentional language rule. |
| §9.7 and §16.2.3: reference safety and ref structs | Escape permissions depend on defined contexts and transfer rules; restrictions are enumerated by use site. | Define how origins propagate through calls, returns, aggregates, closures, and conversions. “Cannot escape” needs a precise boundary. |
| §§12.6.2–12.6.3: calls and inference | Argument-to-parameter correspondence, evaluation order, conversions, passing modes, and inference are separate concerns. Named arguments retain textual evaluation order. | Specify these dimensions independently for named/default/implicit arguments, auto-ref, and contextual Copy. |
| §§13.10–13.11, §13.14, and §21: control transfer, cleanup, exceptions | Return-value computation, intervening cleanup, and transfer to the destination have specified ordering. `using` has a semantic expansion, while equivalent implementations are permitted. | Give `with`, `defer`, `errdefer`, Drop, propagation, panic, and cancellation one compositional account of scope exit. |
| §15.15: async functions | Task states, completion results, suspension, and the required builder interaction are specified. | Runtime-facing protocols can be part of language semantics. Define task outcomes before prescribing scheduler machinery. |
| §§23.1–23.2 and Annex C's introduction | Unsafe support is conditionally normative; the language also requires a minimum library surface. | Feature profiles and intrinsic library contracts need explicit obligations. A feature cannot be simultaneously required everywhere and unavailable in a supported profile without a stated rule. |

Two qualifications matter to the audit:

- **Informative explanation is legitimate.** C# §4 deliberately includes examples and notes and marks them informative. With can retain concise explanations and examples. Their status must be clear, and their factual claims must still be correct.
- **Algorithms are not automatically compiler internals.** C# definite-assignment rules determine program validity. With should distinguish an abstract analysis that defines the language from worklists, caches, passes, data structures, and performance tricks used to implement it.

## Swift: useful separation, but the linked directory is not one language spec

The repository's [documentation index](https://github.com/swiftlang/swift/blob/main/docs/README.md) separates reference guides, ABI material, optimizer and driver documentation, and rationales/manifestos. That organization is itself useful precedent. Files in this directory do not all carry the same authority or describe current accepted syntax.

The selected documents illustrate several different jobs:

- **Ownership design.** The [Ownership Manifesto](https://github.com/swiftlang/swift/blob/main/docs/OwnershipManifesto.md) distinguishes semantic values, storage, accesses, and enforcement. It explicitly considers reentrant access through non-escaping closures. Its proposed `move` changes abstract initialization state; the essential rule is not a particular payload bit pattern. I read the exclusivity/enforcement discussion and selected sections on ephemerals, parameters/results, move/copy, and destruction. This is a design manifesto; proposed spellings and unresolved choices are not evidence of today's Swift language rules.
- **Calling contracts versus machine representation.** [CallingConvention.rst](https://github.com/swiftlang/swift/blob/main/docs/ABI/CallingConvention.rst) separates high-level passing behavior, ownership/validity conventions, and physical passing details. In particular, passing something indirectly does not establish source-level reference semantics. With should preserve the same distinction when specifying ownership and C interoperation.
- **Representation constraints.** [TypeLayout.rst](https://github.com/swiftlang/swift/blob/main/docs/ABI/TypeLayout.rst) describes using invalid payload representations for enum cases and additional tag storage when necessary. This does not validate With's universal zero sentinel: a representation is available for a sentinel only if it is distinguishable from every live value that owes destruction.
- **A separate compatibility contract.** [LibraryEvolution.rst](https://github.com/swiftlang/swift/blob/main/docs/LibraryEvolution.rst) defines permitted binary-compatible changes and distinguishes binary compatibility from semantic compatibility. Such a document is a specification in its own right. Moving ABI requirements out of With's core document should not make them informal or optional.
- **Rationale separated from a proposal.** [ErrorHandling.md](https://github.com/swiftlang/swift/blob/main/docs/ErrorHandling.md) identifies itself as the Swift 2.0 proposal and points to a separate rationale. Its selected propagation and cleanup sections show how a design can state rules and link the longer debate elsewhere. Its historical import heuristics should not be copied into With as established safety arguments.
- **Toolchain guidance.** [Driver.md](https://github.com/swiftlang/swift/blob/main/docs/Driver.md) addresses build-system integration and distinguishes the supported driver interface from frontend implementation details. This is the appropriate kind of home for With's build invocation, incremental compilation, and intermediate-file material.

These distinctions support several documents with explicit relationships: core semantics, intrinsic library/runtime contracts, platform ABI, toolchain reference, implementation guide, and design rationale. They do not imply that every related rule must be copied into each document.

## Scala 3.4: semantic precision and a caution about drift

The [introduction](https://www.scala-lang.org/files/archive/spec/3.4/) openly describes an incomplete update and lists missing Scala 3 material. I examined naming/scope rules, selected type relations, application and inference rules, control flow, implicits, pattern matching, top-level definitions, and the syntax summary. This is not a claim that the draft completely specifies Scala 3.

Useful techniques include separating surface syntax from semantic type forms, defining the relationship between expected types and inference, and specifying evaluation order independently of named-argument rearrangement. The [expressions chapter](https://www.scala-lang.org/files/archive/spec/3.4/06-expressions.html) spells out these stages rather than relying on “the compiler infers it.” That is a useful standard for With's auto-ref, contextual Copy, and implicit-context rules; it does not mean adopting Scala's particular conversions or inference choices.

The draft also contains a direct contradiction. Under **Conformance**, it says “conformance in Scala is not transitive.” The immediately following section describes the same `<:` relation as a preorder, saying “it is transitive and reflexive.” Those statements cannot both define the same relation without an additional distinction the passage does not supply. This is a textual finding, not a claim about compiler behavior. [Types chapter](https://www.scala-lang.org/files/archive/spec/3.4/03-types.html).

There is also visible grammar drift. The [top-level definitions chapter](https://www.scala-lang.org/files/archive/spec/3.4/09-top-level-definitions.html) gives a narrower `TopStat` production than the [syntax summary](https://www.scala-lang.org/files/archive/spec/3.4/13-syntax-summary.html), which includes ordinary definitions, extensions, exports, and end markers and contains an explicit porting TODO. A formal presentation and a versioned URL do not guarantee consistency.

For With, this reinforces the need for one controlling definition per rule, consistent cross-references, and examples/grammar checked against that definition.

## Consequences for the existing With audit

The reading strengthens the audit's distinction between semantic defects and editorial placement. It also narrows any suggestion that all algorithms, runtime requirements, or library contracts should be extracted.

| Audit area | What a repair must settle |
|---|---|
| F01, F03, F05: ownership/destruction | Define a live value's destruction obligation, moved/uninitialized states, and observable cleanup behavior independently of a proposed representation. State permitted implementation freedom separately. |
| F02, F04, F06–F08: borrowing and escape | Give each propagation, storage, return, capture, and thread-transfer operation explicit conditions. Lifetime containment, aliasing/exclusivity, and concurrency safety require separate arguments. |
| F10–F14: suspension, interfaces, cancellation | Define task states and completion outcomes, which operations may suspend, what callers must know, and what each scope exit produces. A scheduler sketch cannot fill these semantic gaps. |
| F18: evaluation and control flow | State receiver/operand/argument/default evaluation order, abrupt completion, and cleanup ordering. Specify where contextual conversion occurs relative to these events. |
| F19–F20: claims and authority | Move comparisons, benchmarks, compiler plans, and project process to their proper documents. Mark retained rationale/examples informative. An informative label does not excuse a false safety argument. |

A useful review test is to ask whether two implementations could disagree on acceptance, observable results, or required safety behavior while each plausibly follows the text. If so, the problem is semantic underspecification or contradiction. If both agree and differ only in internal organization, the disputed detail probably belongs in implementation documentation—unless a separately stated ABI or toolchain contract requires it.

No reference language's design should decide With's policy by analogy alone. The references provide models of precision, separation, and explicit obligations; With still needs its own coherent rules.
