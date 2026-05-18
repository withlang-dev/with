# Scratch Directory Capability

Status: design note. Not implemented.

Build actions often need transient files that are neither declared outputs nor stable project artifacts: archives, extraction directories, compiler response files, captured tool logs, and generated manifests. Today each action must manually choose a scratch path and declare it as an extra output so `ToolFs` write-scope checks allow it.

That works for one target, but it does not scale. Shared paths such as `out/tmp` are too broad for action-local scratch. They also obscure ownership: two actions can accidentally write the same transient file because both declared the same shared directory.

## Proposed API

Add an action-scoped scratch capability:

```with
pub fn ToolFs.scratch_dir(self: &Self) -> str
```

For an action named `pcre2-reference`, this would return a driver-managed directory such as:

```text
out/tmp/pcre2-reference/
```

The exact layout is driver-owned. User code should treat the returned path as opaque except for creating files and subdirectories inside it.

## Semantics

- The scratch directory is private to the current action invocation.
- The driver automatically grants `ToolFs` write-scope permission for the scratch directory.
- The directory may be removed before each action run unless the action explicitly requests persistent cache behavior through a separate future API.
- The path is project-relative when exposed to build code.
- The driver may map the project-relative scratch path to a host-specific absolute path internally.

## Why This Belongs in ToolFs

Scratch directories are filesystem authority. The action should not need to know how the driver scopes writes, where temporary directories live, or how cleanup is handled. Keeping this behind `ToolFs` preserves the same boundary as `copy_tree`, `remove_tree`, and `rename`: build actions request filesystem effects through a capability, and platform or driver details stay below that line.

## Current Workaround

The PCRE2 reference action currently uses `out/pcre2_tmp` and declares that directory as an action extra output. That is intentionally action-scoped and avoids the shared `out/tmp` write-scope problem, but it is still manual per-target plumbing.

`ToolFs.scratch_dir()` should replace that pattern once implemented.
