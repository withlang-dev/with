module app.errors

use std.time.Duration

error DbError =
    ConnectionFailed(host: str, port: u16)
    QueryFailed(query: str, reason: str)
    NotFound(table: str, id: str)
    Timeout

error CacheError =
    ConnectionLost
    KeyTooLarge(size: usize, max: usize)
    Timeout

error NotifyError =
    ProviderDown(provider: str)
    RateLimited(retry_after: Duration)
    InvalidRecipient(addr: str)

// Unified service error — `from` shorthand auto-generates wrapper
// variants (Db, Cache, Notify) and From impls for ? propagation.
// Cancellation just works — no Cancelled variant needed (§14.7).
error ServiceError from DbError, CacheError, NotifyError =
    Validation(msg: str)
    Timeout(operation: str, limit: Duration)
