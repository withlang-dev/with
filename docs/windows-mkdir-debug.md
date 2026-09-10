# Recursive directory creation and native separators

Windows CI at 74ef66cd passed the three forward-slash header-origin cases,
then stopped before writing the first mixed-separator header. The captured
last migrated unit and executable both succeeded; no `mixed` parent existed.
Run 34432173059 retains `windows-test-captures`.

Route: filesystem runtime, minimal `std.fs.mkdir_p` call, native LLDB on
`fs_mkdir_p_c` and its platform `rt_mkdir` calls. The shared loop at
`rt/rt_core.w:3467` recognized only byte 47. At byte 92, LLDB observed
`w8=0x5c`, PC 0x1000078c8 (`fs_mkdir_p_c+92`); stepping the compare and
branch reached +64, advancing without creating the parent. The next mkdir
received `/tmp/with-mkdir-proof/mixed\Windows Kits`, without an intervening
mkdir of `mixed`. Logs: `/tmp/with-windows-mkdir-{lldb,branch-lldb}.log`.
This debugger observation is on macOS, where a backslash is a valid filename
character; the Windows capture supplies the failing native-host evidence.

The loop now recognizes backslash only when the existing `rt_sysinfo_os`
reports Windows, and restores the original separator after each temporary
NUL. POSIX names containing backslashes retain their meaning. No runtime
symbol or ABI is added. The regression checks forward, backward, mixed and
repeated separators, idempotence, file I/O, POSIX literal backslashes, and a
file obstructing a directory. The existing Windows header-origin regression
continues to exercise all seven cases without normalization or exemptions.

The runtime source check, stage1 self-compile, and new behavior regression
pass on macOS. Native Windows verification remains a CI gate. The runner's
missing panic text is tracked separately in #1110.
