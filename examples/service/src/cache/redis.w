module app.cache.redis

use app.traits.CacheService
use app.errors.CacheError
use std.time.Duration

type RedisCache = {
    client: RedisClient,
    prefix: str,
}

extend RedisCache
    fn new(client: RedisClient, prefix: str) -> RedisCache =
        RedisCache { client, prefix }

    fn prefixed_key(self: &RedisCache, key: &str) -> str =
        "{self.prefix}:{key}"

impl CacheService for RedisCache {
    async fn get_bytes(self: &RedisCache, key: &str) -> Result[Option[Vec[u8]], CacheError] =
        let full_key = self.prefixed_key(key)
        match self.client.get(&full_key).await
            Ok(Some(bytes)) -> Ok(Some(bytes))
            Ok(None)        -> Ok(None)
            Err(_)          -> Err(.ConnectionLost)

    async fn set_bytes(self: &RedisCache, key: &str, val: &[u8], ttl: Duration) -> Result[Unit, CacheError] =
        let full_key = self.prefixed_key(key)
        self.client.set_ex(&full_key, val, ttl.as_secs()).await?
        Ok()

    async fn delete(self: &RedisCache, key: &str) -> Result[Unit, CacheError] =
        let full_key = self.prefixed_key(key)
        self.client.del(&full_key).await?
        Ok()

    async fn exists(self: &RedisCache, key: &str) -> Result[bool, CacheError] =
        let full_key = self.prefixed_key(key)
        self.client.exists(&full_key).await
}
