# D25 — D5's supersession is implemented: the classifier is gone

**Laws:** 9 (docs/mission.md).

**Date:** 2026-07-27
**Status:** Done — executes Eric's D5-overruled ruling; supersedes D5's
implementation notes wherever they described the effects sweep.

**Decision.** `Sema.assign_share_place_abi` (the effects-based free-parameter
share-place classifier) is deleted. A free parameter's ownership mode comes
only from its declared type: `&T` borrows (plain call spelling auto-refs),
plain `T` is owned by the callee. Receiver share-place (D12) is untouched and
is now the only inference — gated to parameter 0 (#732) and matched by
canonical type-name text.

**Execution calls worth not re-litigating.**
- 199 read-only free params across src/ and lib/std were migrated to `&T` by
  tools/migrate_shareplace.w (live Parameter facts + Lexer splices). Types
  that are only ever a discriminant opted into Copy instead of borrowing:
  ReceiverMode, AllocConstructKind, std Order, the Analysis enums, AstFileId.
- eff=[read] is NOT proof a param only reads: field-moves and consuming calls
  through a share-place param were invisible to effect analysis (#730's
  family). Five such fns keep plain owned params — the restore_* state
  transfers, store_workspace_record — because their bodies move out of the
  parameter.
- The sweep had been silently repairing real holes it now can't: generic
  receivers never classified via the declared path (NK_TYPE_GENERIC d0 is the
  base SYMBOL, not a node), per-module symbol identity split owner matching,
  and callee drops for owned generic params exposed missing eager caches and
  unterminating recursive-enum drop emission (fixed: rescue backfill at
  codegen's field queries; `__drop_enum_<tid>` outlining).
- Bootstrap rule for signature migrations: callee-side `T`→`&T` in lib/std is
  seed-compatible (owned args auto-ref), but a caller-side view flowing into a
  std signature the seed's embedded stdlib predates is not — those couple
  only after the next reseed (CImport.return_current was the instance).

**What would reopen this:** nothing short of Eric reversing the D5 ruling.
Free-parameter ownership inference does not come back for convenience.

---
