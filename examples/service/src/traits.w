module traits

use domain.*
use errors.*

// --- Data Access ---

trait UserRepository:    async fn find_by_id(self: &Self, id:
    UserId) -> Option[User]
    async fn find_by_email(self: &Self, email: str) -> Option[User]
    async fn list_active(self: &Self, limit: i32, offset: i32) -> Vec[User]
    async fn insert(self: &Self, user: User) -> UserId
    async fn update(self: &Self, id: UserId, fields: UserUpdate) -> bool
    async fn delete(self: &Self, id: UserId) -> bool
    async fn count_posts(self: &Self, id: UserId) -> i32
    async fn count_followers(self: &Self, id: UserId) -> i32

// --- Caching ---
//
// The trait uses string-level get/set for simplicity.
// A production version would use byte-level serialization.

trait CacheService:    async fn get_str(self: &Self, key:
    str) -> Option[str]
    async fn set_str(self: &Self, key: str, val: str, ttl_secs: i64) -> bool
    async fn del(self: &Self, key: str) -> bool
    async fn exists(self: &Self, key: str) -> bool

// --- Notifications ---

trait NotificationService:    async fn send(self: &Self, notif:
    Notification) -> bool
    async fn send_batch(self: &Self, notifs: Vec[Notification]) -> i32

// --- Audit Logging ---

trait AuditLog:    async fn record(self: &Self, actor: UserId, action: str, detail:
    str) -> bool
