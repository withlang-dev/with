//! expect-stdout: ok

// §10.9 / D57: `error E from A, B =` followed by variants declares one error
// type with generated wrapper variants for A and B plus its own variants.

error DbError =
    | NotFound(table: str)
    | Timeout

error CacheError =
    | ConnectionLost

error NotifyError =
    | RateLimited(retry_seconds: i64)

error ServiceError from DbError, CacheError, NotifyError =
    | Validation(msg: str)
    | TimedOut(operation: str, limit_secs: i64)
    | Cancelled

fn db_fail -> Result[i32, DbError]:
    Err(.NotFound("users"))

fn cache_fail -> Result[i32, CacheError]:
    Err(.ConnectionLost)

fn notify_fail -> Result[i32, NotifyError]:
    Err(.RateLimited(30))

fn load_db -> Result[i32, ServiceError]:
    db_fail()?

fn load_cache -> Result[i32, ServiceError]:
    cache_fail()?

fn load_notify -> Result[i32, ServiceError]:
    notify_fail()?

fn validate(name: &str) -> Result[i32, ServiceError]:
    if name.len() == 0:
        return Err(.Validation("empty name"))
    name.len() as i32

fn failure(r: Result[i32, ServiceError]) -> ServiceError:
    match r:
        Err(e) => e
        Ok(_) => panic("expected an error")

fn classify(e: &ServiceError) -> str:
    match e:
        .Db(DbError.NotFound(table)) => f"db not found: {table}"
        .Db(DbError.Timeout) => "db timeout"
        .Cache(_) => "cache"
        .Notify(NotifyError.RateLimited(secs)) => f"notify retry {secs}"
        .Validation(msg) => f"validation: {msg}"
        .TimedOut(op, secs) => f"{op} timed out after {secs}s"
        .Cancelled => "cancelled"

fn main:
    let db = failure(load_db())
    let cache = failure(load_cache())
    let notify = failure(load_notify())
    let invalid = failure(validate(""))
    let timed = ServiceError.TimedOut("query", 5)
    let cancelled = ServiceError.Cancelled
    assert(classify(&db) == "db not found: users")
    assert(classify(&cache) == "cache")
    assert(classify(&notify) == "notify retry 30")
    assert(classify(&invalid) == "validation: empty name")
    assert(classify(&timed) == "query timed out after 5s")
    assert(classify(&cancelled) == "cancelled")
    assert(validate("ada").unwrap() == 3)
    assert(f"{cache}" == "Cache(ConnectionLost)")
    assert(f"{notify:?}" == "Notify(RateLimited(30))")
    assert(f"{cancelled}" == "Cancelled")
    assert(f"{cancelled:?}" == "Cancelled")
    let db_timeout = ServiceError.Db(DbError.Timeout)
    assert(f"{db_timeout:?}" == "Db(Timeout)")
    assert(f"{db_timeout}" == "Db(Timeout)")
    print("ok")
