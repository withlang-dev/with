# Child compiler output belongs to the test case

Linux run 34432540002 at a2109eb2 kept the captures that earlier CI lacked.
The Windows-origin fixture linked `/home/runner/work/with/with/out/src/main.o`
and parent `out/lib` runtime objects from a different test case's working
directory. The va_list child also used `src/main.w` and returned no expected
stdout. Those paths were shared among concurrently executing behavior tests.
The original va_list case had passed repeatedly in isolation without the
parent `WITH_OUT_DIR` environment setting.

Route: linker artifact paths, then LLDB on `link_stage_artifact_root`.
In a separate case cwd, LLDB observed the function return the inherited
`/tmp/with-parent-output-proof` (x0 string, x1=29) to
`link_stage_output_dir_for_source` at PC 0x1002f2650. `Link.w:1157–1159`
intentionally honors this override. The test helper changed cwd at
`pre_d_build_runner.w:107` but did not change the environment.
Log: `/tmp/with-p7-output-root-lldb.log`.

The regression builds two cases with identical `src/main.w` paths and a
deliberately inherited parent output directory. Before the fix it fails at
the assertion requiring the first case's binary: both outputs landed under
the parent. `/tmp/with-p7-output-isolation-before.log` records that assertion.

`p7_run` now sets `WITH_OUT_DIR` to the case's absolute `out` for its
synchronous child and restores the calling test process's prior value.
Test files execute in separate processes; this helper does not spawn
concurrent children within one process. The regression verifies both case
binaries, no parent object, and restoration of the parent's environment.
No compiler or ABI rule is relaxed, and no test is serialized or skipped.
