# Stdlib Issue: `with_getenv_str` Lifetime

Status: unresolved design question. Current workaround landed in `ed6d612`.

`with_getenv_str(name)` currently returns a `str` view into the process
environment storage returned by libc `getenv`. It does not copy the bytes. That
means a later environment mutation, such as `with_setenv_str`, may invalidate
the pointer that backs the returned `str`.

The action environment mitigation in `ed6d612` exposed this directly.
`tool_process_clear_driver_env` has to save the current driver-private
variables before clearing them, then restore them after the child process
launches. The function currently uses:

```with
let tool_token = with_getenv_str("WITH_TOOL_CAPABILITY_TOKEN") ++ ""
let action_name = with_getenv_str("WITH_BUILD_ACTION_NAME") ++ ""
```

The `++ ""` is intentional: it forces a copy before `with_setenv_str` mutates
the environment. Without that copy, the saved `str` could point at storage whose
contents or lifetime changed during the clear/restore sequence.

The open design question is the API contract for environment reads. Two
reasonable designs are:

- `with_getenv_str` always returns an owned copy, making callers safe by
  default at the cost of allocation.
- `with_getenv_str` is documented as a borrowed view whose lifetime ends at the
  next environment mutation, and APIs that need stable values must copy
  explicitly.

The current behavior is the second design in practice, but the contract is not
obvious at call sites. Until the contract is settled and documented, any code
that stores a `with_getenv_str` result across `setenv` must copy it first.
