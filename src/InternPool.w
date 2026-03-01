// InternPool — String interning for identifiers and keywords.
//
// All identifier strings are deduplicated and stored once. Comparisons
// become integer equality checks on Symbol values.

// An interned string handle — index into the pool.
type Symbol = i32

type InternPool = {
    // Backing storage: all interned strings in order.
    strings: Vec[str],
    // Maps string content to its Symbol.
    map: HashMap[str, i32],
}

fn InternPool.init -> InternPool:
    var pool = InternPool {
        strings: Vec.new(),
        map: HashMap.new(),
    }
    // Reserve index 0 as a null sentinel so that symbol 0
    // can be used as "no symbol" throughout the parser.
    pool.strings.push("")
    pool

fn InternPool.deinit(self: InternPool):
    // No-op in current runtime model.
    return

// Intern a string, returning its Symbol. If the string was already
// interned, returns the existing symbol.
fn InternPool.intern(self: InternPool, s: str) -> Symbol:
    let existing = self.map.get(s)
    if existing.is_some():
        return existing.unwrap()
    let id = self.strings.len() as i32
    self.strings.push(s)
    self.map.insert(s, id)
    id

// Retrieve the string content for a previously interned symbol.
fn InternPool.resolve(self: InternPool, sym: Symbol) -> str:
    self.strings.get(sym as i64)
