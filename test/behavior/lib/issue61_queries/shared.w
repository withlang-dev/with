pub type Entry {
    name: str,
    values: Vec[i32],
}

pub type State {
    entries: Vec[Entry],
    alias: Option[str],
    bonus: Result[i32, str],
}

pub fn entry(name: str, values: Vec[i32]) -> Entry:
    Entry { name, values }

pub fn state(entries: Vec[Entry], alias: Option[str], bonus: Result[i32, str]) -> State:
    State {
        entries,
        alias,
        bonus,
    }
