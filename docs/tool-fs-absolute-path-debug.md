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
