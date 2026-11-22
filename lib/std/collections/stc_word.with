// std.collections.stc_word — the word shape's conversions (D148, as ruled
// on its brief): an integer scalar — i8..i64, u8..u64, isize, usize — is
// stored inline in an STC engine instantiated over one 64-bit word, no
// allocation per element. `Deque`, `Stack`, `Queue`, `LinkedList`,
// `UnorderedSet` and `PriorityQueue` pick the shape at compile time by the
// element type (`comptime if` instantiates only the branch taken); the
// conversions live here once.

/// Whether `T` rides the word shape.
pub fn stc_is_word[T]() -> bool:
    comptime if T.name() == "i64" or T.name() == "u64" or T.name() == "i32" or T.name() == "u32" or T.name() == "i16" or T.name() == "u16" or T.name() == "i8" or T.name() == "u8" or T.name() == "isize" or T.name() == "usize": true
    else: false

/// The element's bits as the engine's unsigned word (an unordered engine:
/// the deque, the stack, the queue, the hash set).
pub fn stc_to_word[T](value: T) -> u64:
    comptime if T.name() == "i64": value as u64
    else if T.name() == "u64": value
    else if T.name() == "i32": (value as i64) as u64
    else if T.name() == "u32": value as u64
    else if T.name() == "i16": (value as i64) as u64
    else if T.name() == "u16": value as u64
    else if T.name() == "i8": (value as i64) as u64
    else if T.name() == "u8": value as u64
    else if T.name() == "isize": (value as i64) as u64
    else if T.name() == "usize": value as u64
    else: 0

/// The element back from its unsigned word.
pub fn stc_from_word[T](word: u64) -> T:
    comptime if T.name() == "i64": word as i64
    else if T.name() == "u64": word
    else if T.name() == "i32": (word as i64) as i32
    else if T.name() == "u32": word as u32
    else if T.name() == "i16": (word as i64) as i16
    else if T.name() == "u16": word as u16
    else if T.name() == "i8": (word as i64) as i8
    else if T.name() == "u8": word as u8
    else if T.name() == "isize": (word as i64) as isize
    else if T.name() == "usize": word as usize
    else: panic("stc_word: not a word element")

/// The element as the engine's signed word, in the element's own order
/// (an ordered engine: the priority queue, the linked list's sort). An
/// unsigned 64-bit value flips its sign bit, which keeps its order under
/// the engine's signed `<`.
pub fn stc_to_ordered_word[T](value: T) -> i64:
    comptime if T.name() == "u64" or T.name() == "usize": ((value as u64) ^ 9223372036854775808) as i64
    else if stc_is_word[T](): value as i64
    else: 0

/// The element back from its ordered word.
pub fn stc_from_ordered_word[T](word: i64) -> T:
    comptime if T.name() == "u64": (word as u64) ^ 9223372036854775808
    else if T.name() == "usize": ((word as u64) ^ 9223372036854775808) as usize
    else:
        let plain: T = stc_from_word(word as u64)
        plain
