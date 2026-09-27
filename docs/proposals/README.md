# With Language Proposals

Live plans and design proposals: the documents that describe how a ruling or
a campaign is to be carried out, and designs that have not been ruled on
yet. A proposal is a derivative execution plan — it cannot amend the
specification (`docs/spec/`) or a ruling (`docs/meetings/`); where they
disagree, the specification and the ruling win.

A proposal is *active* while it is being worked toward; it is stored
directly in this folder. A proposal that has been superseded is moved to
[inactive](inactive) so the record survives without cluttering the main
folder. A finished phase is archived in [docs/completed](../completed).

## Active

- [D21 Mutator Pipeline Implementation Plan](d21-mutator-pipeline-implementation.md)
- [D22 Implementation Plan — Uniform Keyed Lookup, Contextual Copy, and View Origins](d22-implementation-plan.md)
- [D27 Element-View Implementation Plan (#740)](d27-implementation-plan.md)
- [D30 Runtime Retirement Implementation Plan (#761)](d30-implementation-plan.md)
- [Modeled C Implementation Plan (D51)](modeled-c-implementation-plan.md)
- [D66 retained variadic pairs (#1652): implementation notes](modeled-c-pair-state-plan.md)
- [Draft: specification projections of D51 (modeled C)](modeled-c-spec-projection-draft.md)
- [Storage Types and Caller-Place Parameters — Specification](storage-types-and-caller-places-spec.md)
- [Structural Types and Anonymous Struct Literals](structural-types.md)
- [Unified `from` Query Expressions](from-query-expressions.md)
- [Eliminate `self`: Swift-style implicit receiver](eliminate-self.md)
- [i128/u128 End-to-End Implementation Plan (#914)](i128.md)
- [comptime Integer Width — Implementation Plan (#943)](comptime-int-width.md)
- [The WebAssembly target](wasm-target.md)
- [Fiber Backend: minicoro Convergence Port](async-proposal.md)
- [State Machine Async — Specification & Implementation Notes](state_machine_async.md)
- [Implementation Plan: mutability](mutability-impl.md)
- [`with fmt` — Specification](with-fmt.md)
- [Editor Support](editor-support.md)
- [Regex Integration Plan](regex.md)
- [zlib Migration Proposal](zlib.md)
- [libgit2 Migration Proposal](libgit2.md)
- [COBOL → With Migration Plan](COBOL-migrate.md)
- [Taming `with migrate`: a boring pipeline for 40 upstreams](harden_migrate.md)
- [Hardening the whole project: wire the guardrails to where they bite](harden_plan.md)
- [Stdlib sourcing: three migrated corpora, one facade](stdlib_sourcing_plan.md)
- [Stdlib Migration Build System](stdlib_migration.md)
- [Stdlib Issue: Build Action Environment Leakage](stdlib-action-env-leak.md)
- [Stdlib Issue: `with_getenv_str` Lifetime](stdlib-getenv-lifetime.md)
- [Stdlib Fluent Builder Follow-Up — Superseded](inactive/stdlib-fluent-builder-blocker.md)
- [Three-tier library architecture](libs.md)
- [Eliminating External Tool Dependencies](no-deps.md)
- [UAT plan — `with uat`](uat-plan.md)
- [Implementation Plan for Open Issue Campaign](implementation_plan.md)
- [With Language — Implementation Roadmap](roadmap.md)
- [What Go, Rust, Swift, Vale, and Zig Do Right That With Does Wrong](build-perf-reference-study.md)
- [Floating-package release investigation](with-get-release-investigation.md)

## Inactive

- [D22 Stage 0 Salvage Manifest](inactive/d22-stage0-salvage-manifest.md)
- [Resume After Mutability Is Fixed — Historical Queue (Superseded)](inactive/resume_after_mutability_fixed.md)
- [Share-place (D5) — Historical Gap Record (Superseded)](inactive/share_place_known_gaps.md)
- [Share-Place: The Minimal Design (Historical — Superseded)](inactive/share_place_minimal_design.md)
- [Share-Place Restoration — Historical Plan (Superseded)](inactive/share_place_restoration_plan.md)
