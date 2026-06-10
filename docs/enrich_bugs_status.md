# Handoff: GitHub Issue Enrichment Campaign — Status & Resume Instructions

Date: 2026-06-10. Session ended mid-campaign (credits). This file is the
complete handoff for a fresh agent. Read it top to bottom before acting.

## 1. What this campaign is

Eric reviewed issue #547 and found campaign-filed issues too thin: *"a
developer should be able to look at this github issue and know exactly what
to do."* Directive: **go through ALL ~190 open issues and enrich each into a
developer-ready implementation spec** — what the feature should look like,
exact changes needed, test plan, acceptance criteria.

This sits inside a larger arc (all already DONE and pushed, commits
`55761446`, `b18ffc43`, `1c525800`):
- Spec v7.0/v7.1 rulings (see `docs/completed/spec-feedback.md`,
  `docs/completed/spec-impl-unalignment.md`)
- Requirements triage: all 2,765 entries in `docs/requirements.md`
  checkboxed/verdicted/issue-linked; 138 consolidated issues #411–#548 filed
- Open-issue range: #348–#548 (~190 open)

## 2. Infrastructure (all under `out/issue-enrich/` — LOCAL ONLY, gitignored)

- `BRIEF.md` — the common agent brief with the REQUIRED body template:
  Summary / Spec / Current state / Implementation plan / Test plan /
  Acceptance criteria / Dependencies / Traceability(preserve verbatim).
  Rules: preserve all original content; verify file:line claims; flag
  stale premises as verify-and-close; #371–#410 already half-decent (add
  what's missing); return per-issue status lines.
- `orig/<N>.md` — snapshot of every open issue (title + body), N=348..548
- `index.tsv` — number<TAB>title for all 190
- `g01..g14.list` — area grouping (§-based); `g01..g12.rem` — REMAINING
  per group (computed; see §4)
- `new/<N>.md` — **enriched bodies produced so far (61 files)** — the
  work product. NOT yet pushed to GitHub.
- Also relevant: `out/req-campaign/g*.tsv` (per-requirement verdict notes
  feeding enrichment), `out/req-campaign/issue-map.json` (NEW-key→issue#).

**Workflow decided:** agents write enriched bodies to `new/<N>.md` only
(NO direct GitHub edits, no repo-file edits); after review, push serially:
`gh issue edit <N> --body-file out/issue-enrich/new/<N>.md` with
`sleep 1.2` between calls (GitHub secondary rate limits; ~190 edits ≈ 5min).
**gh NOTE:** GraphQL is 401 on this machine — `gh issue list --json` FAILS;
use `gh api repos/withlang-dev/with/issues?...` (REST) or plain
create/edit/comment, which work.

## 3. Current state: 61/190 enriched, 129 remaining

DONE (on disk in `new/`): 348 349 350 355 357 359 360 361 362 370 371 372
373 375 378 379 393 398 401 402 408 411 412 415 416 417 421 423 429 430 433
434 436 437 444 447 448 451 457 461 465 466 477 490 491 493 495 496 497 502
510 511 526 527 532 535 536 541 543 545 547

REMAINING by group (`.rem` files exist with these contents):
- g01 (5): 407 424 470 475 377
- g02 (15): 382 389 422 428 446 452 454 484 522 523 **544** 546 483 492 529
- g04 (22): 387 397 399 400 405 406 443 445 456 459 468 472 474 478 481 508 509 517 519 530 383 518
- g05 (3): 515 498 521
- g06 (18): 388 396 404 409 414 **420** 431 432 435 464 469 488 494 512 514 533 538 **391**
- g07 (12): 376 385 390 392 439 442 453 482 504 506 507 384
- g08 (22): 354 369 374 381 394 395 403 413 418 **419** 455 **458** 471 473 480 489 501 524 525 531 534 540
- g09 (8): 426 427 **438** 440 441 503 516 528
- g10 (16): 449 450 460 463 467 479 499 500 505 520 539 542 548 485 486 487
- g12 (8): 380 410 425 462 476 537 386 513

(Bold = four of the "eight bugs" still unenriched; see §5 for the verified
facts to inject.)

## 4. How to resume

1. Launch one general-purpose agent per `.rem` group (parallel is fine),
   prompt = "Read out/issue-enrich/BRIEF.md and follow it exactly. Your
   issues: out/issue-enrich/gXX.rem. SKIP any issue whose
   out/issue-enrich/new/<N>.md already exists." plus the per-group fact
   injections from §5 below. Agents should read each `orig/<N>.md` first —
   group routing was keyword-based and a few issues sit in unexpected
   groups; enrich what the orig body says, not what the number suggests.
2. When all 190 exist in `new/`: spot-check ~10 (template compliance,
   Traceability preserved, no hallucinated file:lines), then push serially
   with rate limiting (script pattern: out/req-campaign/file_issues.sh).
3. Post a short comment on issues whose premise was found stale
   (agents flag these as `premise-stale` in their return summaries).
4. New bugs DISCOVERED during enrichment (file as new issues during
   resume — not yet filed):
   - unsigned min/max use signed compares; unsigned abs not identity;
     mixed-type min/max accepted (CodegenDispatch.w:7229-7268; found by
     g11 while enriching #511)
   - `comptime if T.is_copy()` in generics FATALs at codegen
     (CodegenDispatch.w:9793; erased branch is checked) — captured in
     #423's body but consider a separate codegen-bug issue
   - implicit params: closure capture silently computes WRONG VALUE
     (miscompile), method-call implicit fill hits LLVM verify error
     (found by g03; captured in #398's enriched body — consider
     promoting the miscompile to its own Bug issue)
   - `with fmt --prefer-brace/--prefer-colon` inline conversions
     unimplemented (captured in #502's body)
   - `lib/std/libc.w:60` declares `exit -> void` not `-> Never`
   - `Vec[ephemeral]` wrongly accepted (captured in #362/#477/#497 notes)

## 5. Verified facts to inject into the remaining groups' prompts

These were established by deep exploration this session; without them the
resuming agents will re-derive (or worse, miss) the root causes.

**g02 → #544 (todo/unreachable don't panic):** special-cased to bare
`wl_build_unreachable` at CodegenDispatch.w:8967-8969 (sym_todo/
sym_unreachable); TK_UNREACHABLE codegen 10219-10221. Panic substrate
EXISTS: rt/rt_core.w:737-754 `with_panic_core` (stderr `panic: msg at
file:line`, then `rt_exit(1)`); lib/std/builtins.w:19 extern with_panic;
assert/require/check call it with `src()` defaults (builtins.w:55-83).
Recommended deep fix: make todo()/unreachable() ordinary Never-typed
stdlib fns calling with_panic(msg, src(), 0); DELETE the codegen special
case; mark with_panic noreturn in codegen (free LLVM unreachable after
call); route §4.10 implicit TK_UNREACHABLE through a panic call. Exit-code
unification needed: with_panic_core exits 1 but
behav_checked_overflow_panic.w expects 134 and build/selfhost.w:341
harness self-test expects 134 from assert(false) — investigate, pick one
(recommend 134), audit expect-exit tests. rt_core.w is seed-sensitive
(AGENTS.md bootstrap rules).

**g06 → #420 (closure captures):** SemaCheck.w capture collection
6920-6927; classification 7059-7102: `is_non_escaping =
closure_direct_arg_depth>0 AND direct_arg_escapes==0 AND not move||`
(7065); non-escaping captures by BORROW including Copy values (7076-7096;
line 7094 picks EXCLUSIVE/SHARED, never copy ⇒ the Copy write-through
bug); escaping path marks non-Copy MOVED (7129-7130) ⇒ bound closures
move. Effects via set_closure_capture_summary (7036-7039); MirLower
lower_closure (7625-7637) ignores capture params, delegates to codegen.
Copy-half fix unambiguous (copy at creation). Non-Copy bound-closure
half: write plan per §12.3's v1 rule (bound = escaping = move is correct;
spec §12.4's `let f = || xs.push(1)` example then needs a spec fix), flag
the alternative (local non-escape analysis) as a BDFL decision.

**g06 → #391 (generics keystone):** TY_GENERIC_INST erasure
(Vec[i32]==Vec[str] in sema). Needs phased plan: per-instantiation type
identity, instantiation-time checking (§11.2), monomorphization. Most
stdlib issues depend on it (#392 #394 #470 #471 #475 #405...).

**g08 → #419 (channels):** runtime ALREADY elem_size-generic:
rt/channel_runtime.w CHAN_OFF_ELEM_SIZE layout (18-36), grow/send/recv
memcpy elem_size (54-86, 114-139, 141-162); CodegenDispatch CHAN_CREATE
abi_size_of(elem) (~618-648), CHAN_SEND/RECV typed stack slots (~604-617,
650-681). ONLY type blocker: stale guard SemaCheck.w:4555-4566
(`payload_kind != TY_INT` rejection). Remaining real work: (a) replace
guard with payload-vs-element-type + Send checks; (b) send must CONSUME
its arg — wire a consume effect on the intrinsic into call-site move
enforcement (SemaCheck.w:8177-8186 family; @[effect] parses at
Parser.w:600-649; spec §16.3d); (c) drop-glue for queued non-Copy
elements — with_channel_destroy (181-192) frees buffer without dropping;
design drop-fn pointer passed at CHAN_CREATE; (d) Sender/Receiver
close-on-drop. Also g08: #374 was_cancelled — runtime state exists
(with_fiber_was_cancelled_return, rt/fiber_runtime.w:266-269), expose as
Task method per §14.7. #471 — Mutex/RwLock are non-locking i64 facades
(lib/std/sync.w); plan generic + fiber-aware blocking, depends #391.

**g09 → #438 (float 'inf' bug) and #440 (modes):** default path
rt/rt_core.w rt_f64_to_buf (64-134): inf checks, u64 int part, frac*1e6
single-scale; rt_f64_to_fixed_buf (137-185) lacks inf guards;
with_fmt_f64_spec (1091-1130) DISCARDS mode (`let _ = mode`, 1092) and
routes only on precision sign. 'inf' for 3.14/10.0 verified live.
Prescribe REPLACING the hand-rolled formatter with a Ryū d2s port in
rt_core (covers default g + :e + :f; fixes #440 in same rewrite), with
regression values (3.14, 10.0, 1.5, 0.5, 0.001, 1e308, 1e-308, NaN,
±inf, -0.0) and round-trip property tests. Seed-sensitive.

**g04 → #387 (globals):** spec §9.1c (v7.1) defines layered rule +
E0921 + conservative-first ruling (v1 proof = whole-program syntactic
scan: any async / spawn_os / @[c_export] / extern-C coercion ⇒ proof
fails); never-mutated classification via usage scan; §19.4
proof-dependent-unsafe warning amendment; open sub-question: bare
top-level let/var vs `global` keyword (Parser.w:2341-2360,
LET_FLAG_GLOBAL bits; design doc docs/completed/mut.md §12).
Also g04: #399 let-else parses but codegen fails; #474 slice ..rest
binding never emitted (MirLower.w:5440+ region); #478 @[tailrec] accepts
live Drop local (verified) + observed `let _ = t` double-drop
(cross-ref #430's enriched body, which is DONE — read it).

**g12:** #380 pub enforcement (visibility cached Sema.w:1323-1349, never
errors; expect stdlib fallout — fix by adding pub, never weaken);
#410 inventory gate (diff Token.w keywords vs §29.11, Parser attributes
vs §29.14 + internal list, main.w CLI vs §18.5, lib/std vs §18.6; wire
into build.w beside requirements-informative-check, build.w:457-463
pattern); #386 requirements regeneration against v7.1 (new sections
§4.3c §9.1c §13.5d §15.8 §16.3d §29.14; preserve the 2026-06-10 triage
checkbox/link annotations — requirement IDs are the join key).

## 6. The paused "eight bugs" thread

Before the enrichment directive, Eric asked for a deep-fix plan for the
eight Bug-titled issues (#545 unwrap-no-panic, #430 drop temporaries,
#438 float display, #419 channels, #465 ?.-on-Result, #544
todo/unreachable, #458 no_std leaks, #420 captures), "fix it right the
first time," mission-grounded. That planning was absorbed INTO this
enrichment: the enriched bodies of those eight ARE the implementation
plans. Four are done (#545 #430 #465 + #458? — check new/; 545/430/465
confirmed done), four remain (#544 g02, #420 g06, #419 g08, #438 g09)
with facts above. After enrichment, the natural next step is executing
them in this order: panic substrate (#544+#545 together) → #438 → #465 →
#430 → #420 → #419 → #458, one fix per verification cycle
(build/fixpoint/test gates per AGENTS.md), commit per fix.

## 7. Session task-list state (harness tasks, for cleanup)

#5 #6 #10 #11 completed; #7 #8 #9 #12 (g01 issues 475/470/377/407)
pending; #13 (#424) marked in_progress but NOT on disk — treat as
pending; #14 (g04) #15 (g05) #16 (g02) marked in_progress — their .rem
files are accurate. Trust disk over task list.

## 8. Uncommitted state

`docs/enrich_bugs_status.md` (this file) is the only uncommitted repo
change. Everything else is pushed through commit `1c525800`. The
`out/issue-enrich/` and `out/req-campaign/` trees are local-only
artifacts on this machine (gitignored) — do not lose them before the
push step completes.
