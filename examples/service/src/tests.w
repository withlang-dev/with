module app.tests

use app.domain.*
use app.errors.*
use app.traits.*
use app.service.{UserService, ServiceConfig}
use std.sync.{Arc, RwLock, Mutex}
use std.collections.HashMap
use std.time.Duration

// --- In-Memory Mock Repository ---

type MockUserRepo = {
    users: RwLock[HashMap[UserId, User]],
    next_id: Mutex[i64],
}

extend MockUserRepo:
    fn new:
        MockUserRepo {
            users: RwLock.new(HashMap.new()),
            next_id: Mutex.new(1),
        }

impl UserRepository for MockUserRepo:
    async fn find_by_id(self: &MockUserRepo, id: UserId) -> Result[Option[User], DbError]:
        with self.users.read() as users:
            users.get(&id).cloned()

    async fn find_by_email(self: &MockUserRepo, email: &str) -> Result[Option[User], DbError]:
        with self.users.read() as users:
            users.values()
                |> find(u => u.email == email)
                |> map(u => u.clone())

    async fn list_active(self: &MockUserRepo, limit: i32, offset: i32) -> Result[Vec[User], DbError]:
        with self.users.read() as users:
            users.values()
                |> filter(u => u.active)
                |> skip(offset as usize)
                |> take(limit as usize)
                |> cloned()
                |> collect()

    async fn insert(self: &MockUserRepo, user: &User) -> Result[UserId, DbError]:
        let id = with self.next_id.lock() as mut next:
            let id = UserId(*next)
            *next += 1
            id
        let stored_user = { user.clone() with id: id }
        with self.users.write() as mut users:
            users.insert(id, stored_user)
        id

    async fn update(self: &MockUserRepo, id: UserId, fields: &UserUpdate) -> Result[Unit, DbError]:
        with self.users.write() as mut users:
            match users.get_mut(&id)
                Some(user) ->
                    if let Some(name) = &fields.name then user.name = name.clone()
                    if let Some(email) = &fields.email then user.email = email.clone()
                    if let Some(role) = &fields.role then user.role = *role
                    if let Some(active) = &fields.active then user.active = *active
                None => Err(.NotFound("users", "{id}"))

    async fn delete(self: &MockUserRepo, id: UserId) -> Result[Unit, DbError]:
        with self.users.write() as mut users:
            users.remove(&id)
                .map(_ => ())
                .ok_or(.NotFound("users", "{id}"))

    async fn count_posts(self: &MockUserRepo, _id: UserId) -> Result[i32, DbError]:
        0

    async fn count_followers(self: &MockUserRepo, _id: UserId) -> Result[i32, DbError]:
        0

// --- In-Memory Mock Cache ---

type MockCache = {
    store: RwLock[HashMap[str, Vec[u8]]],
}

extend MockCache:
    fn new:
        MockCache { store: RwLock.new(HashMap.new()) }

impl CacheService for MockCache:
    async fn get_bytes(self: &MockCache, key: &str) -> Result[Option[Vec[u8]], CacheError]:
        with self.store.read() as store:
            store.get(key).cloned()

    async fn set_bytes(self: &MockCache, key: &str, val: &[u8], _ttl: Duration) -> Result[Unit, CacheError]:
        with self.store.write() as mut store:
            store.insert(key.to_string(), val.to_vec())

    async fn delete(self: &MockCache, key: &str) -> Result[Unit, CacheError]:
        with self.store.write() as mut store:
            store.remove(key)

    async fn exists(self: &MockCache, key: &str) -> Result[bool, CacheError]:
        with self.store.read() as store:
            store.contains_key(key)

// --- Recording Mock Notifier ---
//
// Uses Arc-wrapped state so the test can hold a handle to the
// notification log independently from the service that owns the mock.

type NotificationLog = Arc[Mutex[Vec[Notification]]]

fn new_notification_log -> NotificationLog:
    Arc.new(Mutex.new(Vec.new()))

type MockNotifier = {
    sent: NotificationLog,
}

extend MockNotifier:
    fn new(log: NotificationLog):
        MockNotifier { sent: log }

    fn sent_count(log: &NotificationLog) -> i32:
        with log.lock() as sent:
            sent.len32()

impl NotificationService for MockNotifier:
    async fn send(self: &MockNotifier, notif: &Notification) -> Result[Unit, NotifyError]:
        with self.sent.lock() as mut sent:
            sent.push(notif.clone())

    async fn send_batch(self: &MockNotifier, notifs: &[Notification]) -> Result[i32, NotifyError]:
        with self.sent.lock() as mut sent:
            let count = notifs.len32()
            for n in notifs:
                sent.push(n.clone())
            count

// --- No-Op Audit Log ---

type MockAudit = {}

impl AuditLog for MockAudit:
    async fn record(self: &MockAudit, _actor: UserId, _action: &str, _detail: &str) -> Result[Unit, DbError]:
        ()

// --- Test Helper: Build service with mocks ---
//
// Returns the service plus a handle to the notification log
// for asserting side effects. The notification log is shared
// via Arc between the mock (inside the service) and the test.

fn test_service -> (UserService, NotificationLog):
    let notif_log = new_notification_log()

    let service = UserService.builder()
        .repo(Box.new(MockUserRepo.new()))
        .cache(Box.new(MockCache.new()))
        .notifier(Box.new(MockNotifier.new(notif_log.clone())))
        .audit(Box.new(MockAudit {}))
        .build()
        .unwrap()

    (service, notif_log)

// --- Tests ---

async fn test_create_and_fetch_user:
    let (svc, notif_log) = test_service()

    let req = CreateUserRequest {
        name: "Alice",
        email: "alice@example.com",
        role: .Member,
    }

    // Create
    let user = svc.create_user(req, UserId(0)).await
        .unwrap()
    assert(user.name == "Alice")
    assert(user.email == "alice@example.com")
    assert(user.active)

    // Welcome email was sent
    assert(MockNotifier.sent_count(&notif_log) == 1)

    // Fetch profile
    let profile = svc.get_profile(user.id).await
        .unwrap()
    assert(profile.user.name == "Alice")
    assert(profile.post_count == 0)
    assert(profile.followers == 0)

async fn test_duplicate_email_rejected:
    let (svc, _) = test_service()

    let req = CreateUserRequest {
        name: "Alice",
        email: "alice@example.com",
        role: .Member,
    }

    // First create succeeds
    svc.create_user(req.clone(), UserId(0)).await.unwrap()

    // Second create with same email fails
    match svc.create_user(req, UserId(0)).await
        Err(.Validation(msg)) ->
            assert(msg.contains("already registered"))
        _ => unreachable()

async fn test_update_partial_fields:
    let (svc, _) = test_service()

    let user = svc.create_user(CreateUserRequest {
        name: "Bob",
        email: "bob@example.com",
        role: .Member,
    }, UserId(0)).await.unwrap()

    // Update only the name
    let updated = svc.update_user(user.id, UserUpdate {
        name: Some("Robert"),
        email: None,
        role: None,
        active: None,
    }, UserId(0)).await.unwrap()

    assert(updated.name == "Robert")
    assert(updated.email == "bob@example.com")  // unchanged
    assert(updated.role == .Member)             // unchanged

async fn test_delete_user:
    let (svc, _) = test_service()

    let user = svc.create_user(CreateUserRequest {
        name: "Charlie",
        email: "charlie@example.com",
        role: .Guest,
    }, UserId(0)).await.unwrap()

    svc.delete_user(user.id, UserId(0)).await.unwrap()

    // Profile should now 404
    assert_matches(svc.get_profile(user.id).await, Err(.Db(.NotFound(..))))

async fn test_cache_hit_on_second_fetch:
    let (svc, _) = test_service()

    let user = svc.create_user(CreateUserRequest {
        name: "Diana",
        email: "diana@example.com",
        role: .Admin,
    }, UserId(0)).await.unwrap()

    // First fetch — cache miss, hits repo
    let p1 = svc.get_profile(user.id).await.unwrap()

    // Second fetch — should be cached
    let p2 = svc.get_profile(user.id).await.unwrap()

    assert(p1.user.name == p2.user.name)

    // Verify metrics
    with svc.metrics.read() as m:
        assert(m.cache_misses >= 1)
        assert(m.cache_hits >= 1)

async fn test_batch_profiles:
    let (svc, _) = test_service()

    // Create 5 users
    let ids = with Vec.new() as mut out:
        for i in 0..5:
            let user = svc.create_user(CreateUserRequest {
                name: "User {i}",
                email: "user{i}@example.com",
                role: .Member,
            }, UserId(0)).await.unwrap()
            out.push(user.id)

    // Batch fetch all profiles
    let profiles = svc.get_profiles_batch(ids).await.unwrap()
    assert(profiles.len() == 5)
