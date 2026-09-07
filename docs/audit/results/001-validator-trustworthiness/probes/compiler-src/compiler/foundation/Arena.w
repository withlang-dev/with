// Wave 1 foundations: deterministic handle arena.
//
// This is a simple bump-style arena with two storage lanes (`i32`, `str`)
// keyed by `ArenaId`. Deallocation is bulk-only via reset.

use compiler.foundation.Ids

pub fn ARENA_SLOT_EMPTY -> i32: 0
pub fn ARENA_SLOT_I32 -> i32: 1
pub fn ARENA_SLOT_STR -> i32: 2

pub type ArenaSlot {
    kind: i32,
    int_value: i32,
    str_value: str,
}

pub type Arena {
    slots: Vec[ArenaSlot],
}

pub fn Arena.init -> Arena:
    var a = Arena {
        slots: Vec.new(),
    }
    // Slot 0 reserved for invalid handle.
    a.slots.push(ArenaSlot {
        kind: ARENA_SLOT_EMPTY(),
        int_value: 0,
        str_value: "",
    })
    a

impl Arena:
    pub mut fn reset():
        while self.slots.len() > 1:
            self.slots.pop()

    pub fn len(): self.slots.len() as i32

    pub mut fn alloc_i32(value: i32) -> ArenaId:
        let id = arena_id_from_raw(self.slots.len() as i32)
        self.slots.push(ArenaSlot {
            kind: ARENA_SLOT_I32(),
            int_value: value,
            str_value: "",
        })
        id

    pub mut fn alloc_str(value: &str) -> ArenaId:
        let id = arena_id_from_raw(self.slots.len() as i32)
        self.slots.push(ArenaSlot {
            kind: ARENA_SLOT_STR(),
            int_value: 0,
            str_value: value.clone(),
        })
        id

    pub fn contains(id: ArenaId) -> bool:
        if not arena_id_is_valid(id):
            return false
        let raw = arena_id_raw(id)
        raw > 0 and raw < self.slots.len() as i32

    pub fn kind(id: ArenaId) -> i32:
        if not self.contains(id):
            return ARENA_SLOT_EMPTY()
        self.slots.get(arena_id_raw(id) as i64).kind

    pub fn get_i32(id: ArenaId) -> i32:
        if self.kind(id) != ARENA_SLOT_I32():
            return 0
        self.slots.get(arena_id_raw(id) as i64).int_value

    pub fn get_str(id: ArenaId) -> str:
        if self.kind(id) != ARENA_SLOT_STR():
            return ""
        self.slots.get(arena_id_raw(id) as i64).str_value.clone()
