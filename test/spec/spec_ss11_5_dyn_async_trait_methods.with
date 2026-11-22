// Spec test: Section 11.5 — async trait methods through dyn dispatch.

trait DataSource:
    async fn fetch(self: &Self, id: i32) -> i32
    fn tag(self: &Self) -> i32

type LocalSource {
    base: i32,
}

impl DataSource for LocalSource:
    async fn fetch(self: &Self, id: i32) -> i32:
        self.base + id

    fn tag(self: &Self) -> i32:
        self.base

async fn check_source(source: &dyn DataSource):
    let pending = source.fetch(23)

    assert(source.tag() == 100)
    assert(pending.await == 123)
    assert(source.fetch(1).await == 101)

async fn main:
    let local = LocalSource { base: 100 }
    check_source(&local).await
