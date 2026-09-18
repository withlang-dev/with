# Primary verification — `tools/debug_sema_layout.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-tools-misc (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 46 lines (single complete read)

## Scope examined

Debugger companion: prints the native field layout around a hardcoded
byte offset (`target = 792`, `:43`) by iterating `Sema.fields()` at
comptime and printing the field whose `[offset, offset+size)` contains
the target (`:44`-`:46`). No writes, no args, no error paths. The `use`
block (`:5`-`:40`) pulls in the full compiler surface so `Sema` resolves.

## Behavioral matrix (EXECUTED vs HELD)

- EXECUTED, `with-stage1 check tools/debug_sema_layout.w` → ok (exit 0).
  Saved: `docs/audit/probes/tools_debug_sema_layout/check.txt`.
- EXECUTED, `with-stage1 run tools/debug_sema_layout.w` → exit 0 with
  `mres_recv_types: offset=784 size=32 type=Vec[i32]`.
  Saved: `docs/audit/probes/tools_debug_sema_layout/run.txt`.
- EXECUTED (independent oracle): field declaration cross-checked in
  source — `src/Sema.w:487` declares `mres_recv_types: Vec[i32]`.
  Name and type match the tool output exactly.
- HELD: exact numeric offset/size (784/32) — comptime-computed native
  layout with no second oracle; name+type agreement is the verified part.

## Findings

None. In-report notes (not filed):
- The target offset is a hardcoded magic number for one lldb session;
  that is the tool's stated purpose (debugger companion), not a defect.

Verdict: COMPLETE
