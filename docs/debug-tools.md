Tooling plan — three tools, bounded sessions, oracle-first
The governing principle, learned the hard way this arc: build each tool as its own session, validate it against answers you already know before trusting it on open ones, and land it before the work that needs it — not after. These are the oracles for the ownership substrate; they go in first.

Session A — Allocation-origin tagging (highest leverage, build first)
Goal: when the ledger reports a leak or double-free, it names where the block was allocated, not just its address. Turns "two mystery 512-byte leaks" into "two leaks from fiber_create."
Shape: the in-process frame-pointer walker was already proven not to work (no walkable aarch64 chain). So origin tagging can't be a backtrace. Two viable native mechanisms, agent picks by what the code supports:

A lightweight alloc-site token threaded to rt_alloc at the call sites that matter (runtime allocation primitives: with_vec_new, channel/fiber/task creation), stored in the ledger entry alongside {addr, size, freed_flag}. Coarse but cheap, and enough to answer "which subsystem."
Or an lldb-resolved scheme like the existing site-resolution: the ledger records the allocation's return address (one frame, readable even without a full chain), lldb maps it to a symbol out-of-process.

The agent should determine which is feasible against the actual codegen, not assume.
Acceptance (validate against known answers): run a known double-free → abort names the alloc site of the doubly-freed block. Run the #608 POD Vec[i32] leak → leak line names the Vec allocation site. And settle the open question: run the 512-byte channel leak under it — does it originate in fiber/task/channel runtime (likely pre-existing, file separately) or in substrate-touched code? That single answer closes a thread that's been open since the close-out.
Bounded: alloc-origin only this session. NOT drop-origin (that's codegen, session B). Commit on green corpus + the three known cases named correctly.

Session B — Drop-origin MIR tagging (the ownership oracle)
Goal: each emitted Drop carries its MIR origin, so a double-free abort says which two drops hit the same buffer — e.g. "drop of _2.items AND drop of _4 freed addr=…". This is the thing that collapses a multi-pass ownership investigation into one line.
Shape: this is a codegen change (the reason it's a separate session from A). The StmtKind.Drop carries a tag — a stable identifier for the MIR place + origin (scope-exit / reassignment / field-receiver / generated-state). The runtime double-free path, given both the current free's tag and the ledger's record of the first free's tag, prints both. Tag plumbing flows MIR → codegen → the drop call → ledger.
Why after A, before the substrate: A proves the ledger can carry and report origin metadata (the cheap, runtime-only version). B extends that to codegen-emitted origin, which is the harder plumbing — but it's the exact readout the place-ownership work needs ("which drop double-freed" is the ownership question). Build it with a known double-free as the oracle: the field_sym fix double-free should report both drop origins, naming the over-drop precisely.
Acceptance: re-create a known double-free (throwaway), confirm the abort names both drop origins at the MIR-place level; confirm zero overhead when --debug-alloc is off (tags are inert metadata). Commit on green.
Bounded: drop-origin tagging only. This does NOT implement the ownership state machine — it's the instrument that machine will be debugged with.

Session C — MIR drop-state dump (--dump-drop-state)
Goal: print, per basic block, each place's ownership state (Init / Moved / Uninit). Makes the path-sensitive bugs the ownership work is about — premature ledger-clear, partial-move-across-branches, divergent cleanup paths — directly observable instead of hand-reasoned from raw MIR.
Important sequencing caveat: this tool describes a per-place drop-state model. That model substantially exists only once the ownership substrate is being built (the design note's DropState lattice). So C is not standalone-before-the-substrate the way A and B are — it's the first slice of the substrate work: define the canonical Place + DropState representation, and make --dump-drop-state print it, before implementing the transitions. It's the development oracle you build in the same session you lay the substrate's foundation, validated by dumping a known case (A6: h.a = Moved, h.b = Init at the relevant block).
So C's real placement: the opening move of the ownership substrate's first session, not a tool you finish beforehand. A and B are true prerequisites; C is the substrate's own first instrument.

What's explicitly NOT in this plan

Full ASan-shadow emission — reserved (no-C only) for ecosystem interop you don't need; don't build.
Runtime drop flags — that's the Step-9 language feature you've decided to reject (conditional partial moves error, not flag) in v1. Not a tool.
Never-reuse UAF mode — a refinement of a working instrument; defer.
Cross-platform site resolution — real gap (harness is Darwin-arm64-validated), but not blocking current arm64 work. File it; build at release-hardening, not now.


Sequencing summary

Session A — alloc-origin tagging. Standalone. Validate against known double-free + #608 + the 512-byte channel leak. Lands first; immediately closes the open leak question.
Session B — drop-origin MIR tagging. Standalone, codegen change. Validate against a known double-free naming both drop origins. The oracle the ownership work needs.
Then the ownership substrate begins — and Session C (--dump-drop-state) is its opening slice, built alongside the canonical-Place foundation, not before it.

Each session: prove the tool against an answer you already know, commit on green, stop. Same discipline that made the debug allocator succeed — the tool earns trust on known cases before it's used on open ones. And critically, A and B land before the substrate, so for the first time the agent goes into the ownership work able to see what it's changing — which is the whole reason the last attempt onioned.
One check to run inside Session A, given the search finding: confirm whether the #70 small-block rt_free header fix ever landed. If rt_free still leaks small allocations by design, that's likely the 512-byte channel leak's true origin, and alloc-origin tagging will prove it in one run — which would mean the leak was never the substrate's fault and never blocked that commit at all.