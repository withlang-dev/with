module cache.redis

use traits.*

// --- Redis Cache Implementation ---
//
// Demonstrates:
//   - Trait implementation for CacheService
//   - Key prefixing pattern
//   - f-string interpolation for key building
//   - Async trait methods

type RedisCache {
    prefix: str,
}

extend RedisCache:
    fn new(prefix: str) -> RedisCache:
        RedisCache { prefix }

    fn prefixed_key(self: &RedisCache, key: str) -> str:
        "{self.prefix}:{key}"

impl CacheService for RedisCache =
    async fn get_str(self: &RedisCache, key: str) -> Option[str]:
        let _full_key = self.prefixed_key(key)
        // In production: query Redis for the key
        None

    async fn set_str(self: &RedisCache, key: str, val: str, ttl_secs: i64) -> bool:
        let _full_key = self.prefixed_key(key)
        // In production: SET key val EX ttl_secs
        true

    async fn del(self: &RedisCache, key: str) -> bool:
        let _full_key = self.prefixed_key(key)
        // In production: DEL key
        true

    async fn exists(self: &RedisCache, key: str) -> bool:
        let _full_key = self.prefixed_key(key)
        // In production: EXISTS key
        false
