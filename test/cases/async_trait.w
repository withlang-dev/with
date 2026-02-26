// async fn in trait declarations - parsing and sync impl
trait AsyncFetcher =
    async fn fetch(self: &Self) -> i32
    fn name(self: &Self) -> str

type Fetcher = { value: i32 }

impl AsyncFetcher for Fetcher
    fn fetch(self: &Fetcher) -> i32: self.value
    fn name(self: &Fetcher) -> str: "fetcher"

fn main -> i32:
    let f = Fetcher { value: 99 }
    println(f.fetch())
    println(f.name())
    if f.fetch() == 99 then 0 else 1
