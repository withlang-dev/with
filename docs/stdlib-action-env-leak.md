# Stdlib Issue: Build Action Environment Leakage

Status: unresolved design question. Current mitigation landed in `ed6d612`.

Build actions are dispatched by re-entering the compiler driver with two
driver-private environment variables:

- `WITH_TOOL_CAPABILITY_TOKEN`
- `WITH_BUILD_ACTION_NAME`

Those variables are capability-bearing process state. If an action launches a
child process through `ProcessRunner`, the child inherits them unless the runner
scrubs the environment. That made nested compiler invocations look like they
were still inside the parent action. In practice, fixture builds could fail by
trying to run the parent's action target inside the child project, for example
with a diagnostic such as `build action target not found:
c-migrator-pcre2-prep-tests`.

Commit `ed6d612` added the current per-call mitigation:
`ProcessRunner` clears both variables before spawning a child process and
restores them after the spawn/capture call returns. This prevents accidental
capability inheritance for normal process launches.

The open design question is whether environment variables are the right
primitive for capability passing at all. They are process-global, inherited by
default, and must be carefully scrubbed at every process boundary. Alternatives
to evaluate before declaring the design final include driver-managed handles,
explicit process environment construction, an inherited file descriptor or pipe,
or an RPC-style capability channel that is not visible as ordinary user
environment.

Until that design is settled, action-spawned processes must not inherit the
driver capability token or action name.
