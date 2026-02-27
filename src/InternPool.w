// InternPool — String interning for identifiers and keywords.
//
// All identifier strings are deduplicated and stored once. Comparisons
// become integer equality checks on Symbol values.

// An interned string handle — index into the pool.
type Symbol = i32

type InternPool = {
    strings: Vec[str],
    map: HashMap[str, i32],
}

fn InternPool.new() -> InternPool:
    InternPool {
        strings: Vec.new(),
        map: HashMap.new(),
    }

// Intern a string, returning its Symbol. If the string was already
// interned, returns the existing symbol.
fn InternPool.intern(self: InternPool, s: str) -> i32:
    let existing = self.map.get(s)
    if existing.is_some():
        return existing.unwrap()
    let id = self.strings.len() as i32
    self.strings.push(s)
    self.map.insert(s, id)
    id

// Retrieve the string content for a previously interned symbol.
fn InternPool.resolve(self: InternPool, sym: i32) -> str:
    self.strings.get(sym as i64)
