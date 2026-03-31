pub type Entry {
    name: str,
    values: Vec[i32],
}

pub type State {
    entries: Vec[Entry],
    tags: Vec[str],
    alias: Option[str],
    bonus: Result[i32, str],
}

pub fn entry(name: str, values: Vec[i32]) -> Entry:
    Entry { name, values }

pub fn state(entries: Vec[Entry], tags: Vec[str], alias: Option[str], bonus: Result[i32, str]) -> State:
    State {
        entries,
        tags,
        alias,
        bonus,
    }

pub type Counter {
    value: i32,
}

pub fn Counter.new() -> Self:
    Self { value: 0 }

pub fn Counter.bump(self: Counter, delta: i32) -> Self:
    Self { value: self.value + delta }

pub fn Counter.get(self: Counter) -> i32:
    self.value
