module app.traits

use app.domain.*
use app.errors.*

// --- Data Access ---

trait UserRepository {
    async fn find_by_id(self: &Self, id: UserId) -> Result[Option[User], DbError]
    async fn find_by_email(self: &Self, email: &str) -> Result[Option[User], DbError]
    async fn list_active(self: &Self, limit: i32, offset: i32) -> Result[Vec[User], DbError]
    async fn insert(self: &Self, user: &User) -> Result[UserId, DbError]
    async fn update(self: &Self, id: UserId, fields: &UserUpdate) -> Result[Unit, DbError]
    async fn delete(self: &Self, id: UserId) -> Result[Unit, DbError]
    async fn count_posts(self: &Self, id: UserId) -> Result[i32, DbError]
    async fn count_followers(self: &Self, id: UserId) -> Result[i32, DbError]
}

// --- Caching ---
//
// The trait uses byte-level get/set so it remains object-safe
// (no generic methods in the vtable). Generic convenience helpers
// cache_get and cache_set handle serialization outside the trait.

trait CacheService {
    async fn get_bytes(self: &Self, key: &str) -> Result[Option[Vec[u8]], CacheError]
    async fn set_bytes(self: &Self, key: &str, val: &[u8], ttl: Duration) -> Result[Unit, CacheError]
    async fn delete(self: &Self, key: &str) -> Result[Unit, CacheError]
    async fn exists(self: &Self, key: &str) -> Result[bool, CacheError]
}

// Generic helpers — these are free functions, not trait methods,
// so they can be generic while still working with &dyn CacheService.

async fn cache_get[T: Deserialize](cache: &dyn CacheService, key: &str) -> Result[Option[T], CacheError] =
    match cache.get_bytes(key).await
        Ok(Some(bytes)) -> Ok(Some(deserialize(&bytes)?))
        Ok(None) -> Ok(None)
        Err(e) -> Err(e)

async fn cache_set[T: Serialize](cache: &dyn CacheService, key: &str, val: &T, ttl: Duration) -> Result[Unit, CacheError] =
    let bytes = serialize(val)
    cache.set_bytes(key, &bytes, ttl).await

// --- Notifications ---

trait NotificationService {
    async fn send(self: &Self, notif: &Notification) -> Result[Unit, NotifyError]
    async fn send_batch(self: &Self, notifs: &[Notification]) -> Result[i32, NotifyError]
}

// --- Audit Logging ---

trait AuditLog {
    async fn record(self: &Self, actor: UserId, action: &str, detail: &str) -> Result[Unit, DbError]
}
