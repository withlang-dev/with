use std.collections

type Holder { handle: Handle[i32], tag: i32 }
impl Holder:
    mut fn change_generation(value: u32): self.handle.generation = value

fn changed(handle: Handle[i32]):
    var result = handle
    result.generation = 4294967295
    result

fn test_handle_fields_preserve_source_identity:
    var map = SlotMap[i32].new()
    assert(map.ptr != 0)
    var handle = map.insert(7)
    let original_index = handle.index
    handle.generation = 2
    assert(handle.index == original_index and handle.generation == 2)
    let returned = changed(handle)
    assert(returned.index == original_index and returned.generation == 4294967295)
    let constructed: Handle[i32] = Handle { generation: 9, index: 12 }
    assert(constructed.index == 12 and constructed.generation == 9)
    var holder = Holder { handle, tag: 42 }
    holder.change_generation(3)
    assert(holder.handle.generation == 3 and holder.tag == 42)
    var pair = (handle, 42)
    (pair.0).generation = 4
    assert((pair.0).generation == 4 and pair.1 == 42)
    let handles = [handle, returned]
    handles[0].generation = 5
    assert(handles[0].generation == 5 and handles[1].generation == 4294967295)
    let vec_handles: Vec[Handle[i32]] = [handle, returned]
    vec_handles[0].generation = 6
    assert(vec_handles[0].generation == 6 and vec_handles[1].generation == 4294967295)
