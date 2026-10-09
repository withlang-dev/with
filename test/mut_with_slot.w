// Test: §10 scoped with-access via ListSlot

fn test_list_slot_get:
    var xs = List.new()
    xs.push(10)
    xs.push(20)
    xs.push(30)
    let s = xs.slot(1)
    assert(s.get() == 20)

fn test_list_slot_set:
    var xs = List.new()
    xs.push(10)
    xs.push(20)
    xs.push(30)
    with xs.slot(1) as mut s:
        s.set(99)
    assert(xs[1] == 99)

fn test_list_slot_read_modify_write:
    var xs = List.new()
    xs.push(10)
    xs.push(20)
    xs.push(30)
    with xs.slot(2) as mut s:
        let v = s.get()
        s.set(v + 1)
    assert(xs[2] == 31)
