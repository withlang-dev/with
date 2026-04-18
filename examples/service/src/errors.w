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

// Unified service error — all subsystem errors convert into this.
// Use explicit conversion functions instead of From trait.
error ServiceError =
    | Db(DbError)
    | Cache(CacheError)
    | Notify(NotifyError)
    | Validation(msg: str)
    | TimedOut(operation: str, limit_secs: i64)
    | Cancelled

// Explicit conversion functions (From trait not yet available)
fn service_error_from_db(e: DbError) -> ServiceError: .Db(e)
fn service_error_from_cache(e: CacheError) -> ServiceError: .Cache(e)
fn service_error_from_notify(e: NotifyError) -> ServiceError: .Notify(e)
