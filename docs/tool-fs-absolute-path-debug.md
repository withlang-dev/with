# Action paths resolve once inside the project

Windows CI reported `D:/a/with/with/D:/a/with/with/out/...stderr`
while trying to report a helper compilation error. ToolFs.resolve_path
appended the project root to an already absolute project path. On Darwin,
the same call instead failed the leading-slash relative-path guard.

LLDB on the actual action runner stopped at ToolFs.resolve_path
(`0x1000009a0`); its input was the absolute project `src/input.txt`.
The call at `0x1000009b4` passed that raw path to the relative-path guard.
Evidence: `/tmp/with-toolfspath-lldb.log`.

Fixing resolution alone left absolute output paths broken: the write guard
still checked the raw path. LLDB on the runner with that partial fix stopped
at tool_path_require_project_relative with the absolute declared output
`out/result.txt`. The comparison at `0x1000007fc` recognized the leading slash
and branched to failure at `0x100000800`.
Evidence: `/tmp/with-toolfspath-write-lldb.log`.

Resolution and write/mkdir permission checks now share the existing
project_relative_path normalization. They remove the project prefix before
checking scope and join it exactly once for I/O. Paths outside the project,
including Windows drive paths, still fail; undeclared writes and directory
creation still fail. The action regression exercises both accepted and
rejected paths without a platform skip.

The first full behavior battery also exercised the compile-time evaluator,
which has a separate capability implementation. Its retained capture reported
`ToolFs path escapes project root in read_text` for the same project input.
Setting WITH_BUILD_ACTION_WORKER=generate and WITH_BUILD_ACTION_FORCE=1
reproduces that route deterministically. LLDB stopped in
ComptimeEvaluator.capability_resolve_project_path: at `0x10012f5c0` it passed
the absolute input directly to comptime_tool_path_is_project_relative.
The input string and caller are recorded in `/tmp/with-comptime-path-lldb.log`.
The interpreter now normalizes before resolution and write/mkdir scope checks
too. The regression explicitly runs both native and interpreted actions.
