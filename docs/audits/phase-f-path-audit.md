# Phase F Path Containment Audit

Status: complete. Path containment, install capability gating, and
promotion staleness checks are implemented and verified.

Phase F hardens path-writing capabilities so that build graph targets
cannot accidentally write outside the project root unless they are
explicitly marked as install or promote targets.

## Containment Validation

Every target dispatched through `build_graph_dispatch_standard_target`
now passes through `build_graph_validate_target_containment` before
any operation runs.

### Rules

| Field | Non-install targets | Install targets | Promote targets | Clean targets |
|-------|-------|---------|---------|-------|
| `output` | Must be project-relative | Must be install-dest (`$HOME/`, `$INSTALL_BINDIR/`, `$INSTALL_LIBDIR/`) or project-relative | Must be project-relative | Skipped (has own validation) |
| `entry` | Must be project-relative (except command/corpus/action targets where entry is an executable) | No restriction | Must be project-relative | Skipped |
| `extra_output` | Must be project-relative | Must be project-relative | Must be project-relative | Skipped |

### Path containment definition

`build_graph_path_project_contained(path)` rejects:
- Empty paths (returns true, treated as absent)
- Absolute paths (leading `/`)
- Parent-directory traversal (`..`)
- Install variable prefixes (`$`)
- Embedded NUL, LF, CR, TAB

### Install destination definition

`build_graph_path_is_install_dest(path)` accepts only:
- `$HOME/...`
- `$INSTALL_BINDIR/...`
- `$INSTALL_LIBDIR/...`

## Promotion Staleness

`build_graph_promote_tree_if_verified` replaces the former
`copy_manifest_files` dispatch for PromoteTreeIfVerified targets.
It compares source and destination file contents byte-by-byte:

- Files identical to their source are skipped (counted as fresh).
- Files that differ or are missing are written (counted as stale).
- A diagnostic reports the stale/fresh count after promotion.

## Diagnostics

All path validation errors name:
- The target name
- The field that failed (`output`, `entry`, `extra_output`, `input[N]`, `arg[N]`)
- The rejected path value

## Files Changed

| File | Change |
|------|--------|
| `src/BuildGraphSupport.w` | Added `build_graph_path_project_contained`, `build_graph_path_is_install_dest`, `build_graph_validate_target_containment`. Improved `build_graph_validate_process_args` diagnostics. |
| `src/BuildGraphDispatch.w` | Added containment check at dispatch entry. Switched promote dispatch to `build_graph_promote_tree_if_verified`. |
| `src/BuildGraphOps.w` | Added `build_graph_promote_tree_if_verified` with staleness detection. |
| `build.w` | Removed stale `main_emit_temp` clean artifacts. |
