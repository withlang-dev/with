module errors

// --- Database Errors ---

error DbError =
    | ConnectionFailed(host: str, port: u16)
    | QueryFailed(query: str, reason: str)
    | NotFound(table: str, id: str)
    | Timeout

// --- Cache Errors ---

error CacheError =
    | ConnectionLost
    | KeyTooLarge(size: usize, max: usize)
    | Timeout

// --- Notification Errors ---

error NotifyError =
    | ProviderDown(provider: str)
    | RateLimited(retry_seconds: i64)
    | InvalidRecipient(addr: str)

// Unified service error — `from` generates the Db, Cache and Notify
// wrappers, so `?` converts each subsystem error; the written variants
// are the service's own (§10.9).
error ServiceError from DbError, CacheError, NotifyError =
    | Validation(msg: str)
    | TimedOut(operation: str, limit_secs: i64)
    | Cancelled
