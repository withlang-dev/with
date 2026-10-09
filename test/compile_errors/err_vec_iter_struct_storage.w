//! expect-check-fail: ephemeral

use std.collections.ListIter

use std.collections.SlotMapSlot
type BadListIterBox {
    iter: ListIter[i32],
}

type BadFilterIterBox {
    iter: FilterIter[ListIter[i32], i32],
}

type BadListSlotBox {
    slot: ListSlot[i32],
}

type BadHashMapEntryBox {
    entry: HashMapEntry[str, i32],
}

type BadSlotMapSlotBox {
    slot: SlotMapSlot[i32],
}

fn main:
    ()
