pub type Entry {
    name: str,
    values: List[i32],
}

pub type State {
    entries: List[Entry],
    alias: Option[str],
    bonus: Result[i32, str],
}

pub fn entry(name: str, values: List[i32]) -> Entry:
    Entry { name, values }

pub fn state(entries: List[Entry], alias: Option[str], bonus: Result[i32, str]) -> State:
    State {
        entries,
        alias,
        bonus,
    }
