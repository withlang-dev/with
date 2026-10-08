// BuiltinSigs — the declared signatures of the builtin types' methods (D110).
//
// A parameter's mode is what the method does with it: a `&T` parameter is a
// probe the method only reads (observed: the caller keeps the argument, and
// nothing in the call drops it); a plain `T` parameter is stored or consumed
// (taken: the argument moves in). Each row is the method's parameter list as
// it would be written in With. Sema loads the table once, indexed by
// (owner symbol, method symbol), and resolves each builtin call to its row
// when it checks the call; every phase reads that row, so a builtin has no
// second ownership system:
//   Sema      marks a taken non-Copy argument moved; an observed one stays live.
//   MirLower  lowers an observed argument as a probe, a taken one as a move.
//   codegen   drops only what the method stores; a probe is the caller's.
//
// Owners are type names, plus `str`, `array` (arrays and slices), `int`,
// `float` and `Iter` (VecIter and every iterator adapter); the float math
// methods are MathBuiltins' and take every operand. A builtin method called
// with arguments must resolve to a row; MirLower refuses one that did not.

pub type BuiltinSigRow { pub owner: str, pub method: str, pub params: str }

fn sig(owner: str, method: str, params: str) -> BuiltinSigRow: BuiltinSigRow { owner, method, params }

pub fn builtin_sig_table() -> Vec[BuiltinSigRow]:
    var t: Vec[BuiltinSigRow] = Vec.new()
    t.push(sig("str", "byte_at", "index: i64"))
    t.push(sig("str", "slice", "start: i64, end: i64"))
    t.push(sig("str", "contains", "needle: &str"))
    t.push(sig("str", "starts_with", "prefix: &str"))
    t.push(sig("str", "ends_with", "suffix: &str"))
    t.push(sig("str", "find", "needle: &str"))
    t.push(sig("str", "index_of", "needle: &str"))
    t.push(sig("str", "split", "sep: &str"))
    t.push(sig("str", "replace", "from: &str, to: &str"))
    t.push(sig("str", "repeat", "count: i64"))
    t.push(sig("array", "split_at", "mid: i64"))
    t.push(sig("array", "split_at_mut", "mid: i64"))
    t.push(sig("int", "rotate_left", "n: u32"))
    t.push(sig("int", "rotate_right", "n: u32"))
    t.push(sig("int", "min", "other: Self"))
    t.push(sig("int", "max", "other: Self"))
    t.push(sig("float", "min", "other: Self"))
    t.push(sig("float", "max", "other: Self"))
    t.push(sig("float", "mul_add", "a: Self, b: Self"))
    t.push(sig("Sender", "send", "value: T"))
    t.push(sig("Vec", "with_capacity", "capacity: i64"))
    t.push(sig("Vec", "push", "value: T"))
    t.push(sig("Vec", "get", "index: i32"))
    t.push(sig("Vec", "remove", "index: i32"))
    t.push(sig("Vec", "slot", "index: i32"))
    t.push(sig("Vec", "get_disjoint", "a: i32, b: i32"))
    t.push(sig("Vec", "range", "r: Range[i32]"))
    t.push(sig("Vec", "split_at", "mid: i64"))
    t.push(sig("Vec", "split_at_mut", "mid: i64"))
    t.push(sig("Vec", "map", "f: fn(&T) -> U"))
    t.push(sig("Vec", "filter", "pred: fn(&T) -> bool"))
    t.push(sig("Vec", "fold", "init: A, f: fn(A, &T) -> A"))
    t.push(sig("Vec", "contains", "value: &T"))
    t.push(sig("Vec", "join", "sep: &str"))
    t.push(sig("FixedString", "push_byte", "b: u8"))
    t.push(sig("FixedString", "push_str", "s: &str"))
    t.push(sig("FixedString", "equals", "other: &str"))
    t.push(sig("Iter", "map", "f: fn(T) -> U"))
    t.push(sig("Iter", "filter", "pred: fn(&T) -> bool"))
    t.push(sig("Iter", "filter_map", "f: fn(T) -> Option[U]"))
    t.push(sig("Iter", "take", "n: i64"))
    t.push(sig("Iter", "drop", "n: i64"))
    t.push(sig("Iter", "take_while", "pred: fn(&T) -> bool"))
    t.push(sig("Iter", "drop_while", "pred: fn(&T) -> bool"))
    t.push(sig("Iter", "zip", "other: J"))
    t.push(sig("Iter", "chain", "other: J"))
    t.push(sig("Iter", "zip_with", "other: J, f: fn(T, U) -> R"))
    t.push(sig("Iter", "step_by", "n: i64"))
    t.push(sig("Iter", "flat_map", "f: fn(T) -> J"))
    t.push(sig("Iter", "fold", "init: A, f: fn(A, T) -> A"))
    t.push(sig("Iter", "reduce", "f: fn(T, T) -> T"))
    t.push(sig("Iter", "min_by", "f: fn(&T, &T) -> Ordering"))
    t.push(sig("Iter", "max_by", "f: fn(&T, &T) -> Ordering"))
    t.push(sig("Iter", "find", "pred: fn(&T) -> bool"))
    t.push(sig("Iter", "position", "pred: fn(&T) -> bool"))
    t.push(sig("Iter", "any", "pred: fn(&T) -> bool"))
    t.push(sig("Iter", "all", "pred: fn(&T) -> bool"))
    t.push(sig("Iter", "none", "pred: fn(&T) -> bool"))
    t.push(sig("Iter", "for_each", "f: fn(T)"))
    t.push(sig("Iter", "partition", "pred: fn(&T) -> bool"))
    t.push(sig("VecSlot", "set", "value: T"))
    t.push(sig("SlotMap", "insert", "value: T"))
    t.push(sig("SlotMap", "get", "h: Handle[T]"))
    t.push(sig("SlotMap", "slot", "h: Handle[T]"))
    t.push(sig("SlotMap", "remove", "h: Handle[T]"))
    t.push(sig("SlotMap", "replace", "h: Handle[T], value: T"))
    t.push(sig("SlotMap", "contains", "h: Handle[T]"))
    t.push(sig("SlotMap", "get_disjoint", "a: Handle[T], b: Handle[T]"))
    t.push(sig("SlotMapSlot", "set", "value: T"))
    t.push(sig("VecRange", "get", "index: i32"))
    t.push(sig("VecRange", "set", "index: i32, value: T"))
    t.push(sig("VecRange", "split_at", "mid: i64"))
    t.push(sig("VecRange", "split_at_mut", "mid: i64"))
    t.push(sig("HashMap", "insert", "key: K, value: V"))
    t.push(sig("HashMap", "get", "key: &K"))
    t.push(sig("HashMap", "contains", "key: &K"))
    t.push(sig("HashMap", "remove", "key: &K"))
    t.push(sig("HashMap", "increment", "key: &K"))
    t.push(sig("HashMap", "decrement", "key: &K"))
    t.push(sig("HashMap", "update", "key: &K, default: V, f: fn(V) -> V"))
    t.push(sig("HashMap", "entry", "key: K"))
    t.push(sig("HashMap", "slot_live", "index: i64"))
    t.push(sig("HashMap", "slot_key", "index: i64"))
    t.push(sig("HashMap", "slot_value", "index: i64"))
    t.push(sig("HashMap", "slot_take", "index: i64"))
    t.push(sig("HashMapEntry", "or_insert", "value: V"))
    t.push(sig("HashMapEntry", "set", "value: V"))
    t.push(sig("HashSet", "insert", "value: T"))
    t.push(sig("HashSet", "contains", "value: &T"))
    t.push(sig("HashSet", "remove", "value: &T"))
    t.push(sig("HashSet", "slot_live", "index: i64"))
    t.push(sig("HashSet", "slot_key", "index: i64"))
    t.push(sig("Option", "expect", "msg: &str"))
    t.push(sig("Option", "filter", "pred: fn(&T) -> bool"))
    t.push(sig("Result", "expect", "msg: &str"))
    t.push(sig("Atomic", "load", "order: Ordering"))
    t.push(sig("Atomic", "store", "value: T, order: Ordering"))
    t.push(sig("Atomic", "swap", "value: T, order: Ordering"))
    t.push(sig("Atomic", "fetch_add", "value: T, order: Ordering"))
    t.push(sig("Atomic", "fetch_sub", "value: T, order: Ordering"))
    t.push(sig("Atomic", "fetch_and", "value: T, order: Ordering"))
    t.push(sig("Atomic", "fetch_or", "value: T, order: Ordering"))
    t.push(sig("Atomic", "fetch_xor", "value: T, order: Ordering"))
    t.push(sig("Atomic", "fetch_min", "value: T, order: Ordering"))
    t.push(sig("Atomic", "fetch_max", "value: T, order: Ordering"))
    t.push(sig("Atomic", "compare_exchange", "current: T, new: T, success: Ordering, failure: Ordering"))
    t.push(sig("Atomic", "compare_exchange_weak", "current: T, new: T, success: Ordering, failure: Ordering"))
    t

// The byte range of parameter `index`'s declared type in `params`, as
// (start, end); (-1, -1) when there is no such parameter. Parameters split
// at the top-level commas.
fn builtin_param_type_span(params: &str, index: i32) -> (i32, i32):
    var depth = 0
    var param = 0
    var start = -1
    var i = 0
    while i < params.len():
        let c = params.byte_at(i)
        if c == '(' or c == '[': depth = depth + 1
        else if c == ')' or c == ']': depth = depth - 1
        else if c == ',' and depth == 0:
            if param == index and start >= 0:
                return (start, i)
            param = param + 1
        else if c == ':' and depth == 0 and param == index and start < 0:
            start = i + 2
        i = i + 1
    if param == index and start >= 0: (start, i) else: (-1, -1)

// Each parameter's mode as one letter: `o` observed (`&T`), `s` stored
// (taken as one of the receiver's type parameters `T`, `K`, `V`), `t` taken.
pub fn builtin_param_modes(params: &str) -> str:
    var modes = ""
    var index = 0
    while true:
        let (start, end) = builtin_param_type_span(params, index)
        if start < 0:
            return modes
        let c = params.byte_at(start)
        modes = modes ++ (if c == '&': "o" else: if end == start + 1 and (c == 'T' or c == 'K' or c == 'V'): "s" else: "t")
        index = index + 1
    modes

