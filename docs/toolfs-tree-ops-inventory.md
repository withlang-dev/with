# ToolFs Tree Operation Inventory

Status: inventory only. No implementation changes.

This documents the filesystem capability surface before adding tree-level
operations for build actions.

## Current `ToolFs` Surface

Defined in `lib/std/build.w`:

- `ToolFs.exists(path: str) -> bool`
- `ToolFs.is_dir(path: str) -> bool`
- `ToolFs.mkdir_all(path: str) -> i32`
- `ToolFs.read_text(path: str) -> str`
- `ToolFs.write_text(path: str, contents: str) -> i32`
- `ToolFs.remove_file(path: str) -> i32`

All current `ToolFs` paths are required to be project-relative. Write-scoped
action contexts enforce declared outputs for `mkdir_all`, `write_text`, and
`remove_file`.

## Missing `ToolFs` Operations

These operations are needed so build actions do not spawn Unix filesystem tools
through `ProcessRunner`:

- `ToolFs.copy_tree(src: str, dst: str) -> i32`
- `ToolFs.remove_tree(path: str) -> i32`
- `ToolFs.symlink(target: str, link: str) -> i32`

`copy_tree` and `symlink` need source/target path validation and destination
write-scope validation. `remove_tree` needs write-scope validation equivalent
to recursively deleting a declared output tree.

## Runtime Primitives

Already available:

- `with_fs_remove_tree(path: str) -> i32`
- `rt_remove_tree(path: *const u8) -> i32`
- `rt_remove_tree_impl` in `rt/darwin_aarch64.w`

Missing:

- `with_fs_copy_tree(src: str, dst: str) -> i32`
- `with_fs_symlink(target: str, link: str) -> i32`
- `rt_copy_tree(src: *const u8, dst: *const u8) -> i32`
- `rt_symlink(target: *const u8, link: *const u8) -> i32`

The first implementation can be Darwin-specific below the runtime boundary.
Build action code should call only `ToolFs`.

## Current Leaks Through `ProcessRunner`

`build.w`:

- `issue61_regression_action` spawns `/bin/rm -rf` to remove a copied repo tree.
- `issue61_regression_action` spawns `/bin/cp -R` to copy `src`.
- `issue61_regression_action` spawns `/bin/ln -s` to link `lib`.

`build_runtime.w`:

- `br_collect_stdlib_files` spawns `/usr/bin/find` to enumerate `lib/std`
  source files. This is read-only enumeration, but it is still Unix userland
  filesystem behavior visible above the capability boundary.
