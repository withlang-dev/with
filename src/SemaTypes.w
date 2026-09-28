// Type tags shared by semantic analysis and the frozen MIR type tables.
// Keep this vocabulary independent of the semantic-analysis driver.
pub enum TypeKind: i32:
    TY_ERR = 0
    TY_INT = 1
    TY_FLOAT = 2
    TY_BOOL = 3
    TY_VOID = 4
    TY_STR = 5
    TY_STRUCT = 6
    TY_ENUM = 7
    TY_ARRAY = 8
    TY_SLICE = 9
    TY_TUPLE = 10
    TY_RANGE = 11
    TY_FN = 12
    TY_PTR = 13
    TY_REF = 14
    TY_ALIAS = 15
    TY_GENERIC_FN = 16
    TY_TRAIT_OBJ = 17
    TY_NEVER = 18
    TY_GENERIC_INST = 19
    TY_EXTERN_FN = 20
    // C's va_list, modeled per target (#1104): a pointer on Darwin and
    // Windows, a 24-byte __va_list_tag on SysV x86_64, a 32-byte
    // struct on AAPCS64 Linux. Opaque to With code; Copy; passed to a
    // callee the way the target's C passes va_list (TypeLayout, FnAbi).
    TY_VA_LIST = 21

pub type TypeId = i32

pub enum BorrowKind: i32:
    SHARED = 0
    EXCLUSIVE = 1

// §4.5 (D75, #1802): what a cast whose target relabels its source does with
// the source (Sema.cast_modes). The target states the mode, as a parameter's
// type does.
pub enum CastMode: i32:
    // An owned value crosses into or out of its distinct type: the source is
    // consumed and the result owns it.
    MOVE = 1
    // An owned place viewed as a view type (`n as &str`, `s as []u8`): the
    // result borrows the place.
    BORROW = 2
    // A cast through a reference (`r as str`, `r: &Name`): the result is the
    // same reference, relabeled — a view with the source's origins.
    REF_RELABEL = 3

// D61 (§15.4.7): how `:?` formats one registered type (Sema.debug_fmt_*).
pub enum DebugFmtKind: i32:
    // A formatter MirLower synthesizes: struct, enum, tuple, array, slice,
    // Vec, Box — each component formatted with `:?`.
    SYNTH = 1
    // An explicit `impl Debug`: its debug_str, at every depth.
    IMPL = 2
    // A std collection's formatter method (HashMap, BTreeMap).
    HELPER = 3
