module app.errors

use std.time.Duration

error DbError =
    | ConnectionFailed(host: str, port: u16)
    | QueryFailed(query: str, reason: str)
    | NotFound(table: str, id: str)
    | Timeout

error CacheError =
    | ConnectionLost
    | KeyTooLarge(size: usize, max: usize)
    | Timeout

error NotifyError =
    | ProviderDown(provider: str)
    | RateLimited(retry_after: Duration)
    | InvalidRecipient(addr: str)

// Unified service error — all subsystem errors convert into this
// via From impls, so ? propagation works across boundaries.
error ServiceError =
    | Db(DbError)
    | Cache(CacheError)
    | Notify(NotifyError)
    | Validation(msg: str)
    | Timeout(operation: str, limit: Duration)
    | Cancelled

impl From[DbError] for ServiceError:
    fn from(e: DbError) -> ServiceError: .Db(e)

impl From[CacheError] for ServiceError:
    fn from(e: CacheError) -> ServiceError: .Cache(e)

impl From[NotifyError] for ServiceError:
    fn from(e: NotifyError) -> ServiceError: .Notify(e)

impl From[TaskCancelled] for ServiceError:
    fn from(_: TaskCancelled) -> ServiceError: .Cancelled
