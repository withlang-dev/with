//! expect-check-fail: ephemeral

type BadVecIterBox {
    iter: VecIter[i32],
}

type BadFilterIterBox {
    iter: FilterIter[VecIter[i32], i32],
}

type BadVecSlotBox {
    slot: VecSlot[i32],
}

type BadHashMapEntryBox {
    entry: HashMapEntry[str, i32],
}

type BadSlotMapSlotBox {
    slot: SlotMapSlot[i32],
}

fn main:
    ()
