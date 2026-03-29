type Param {
    name: str,
    rank: i32,
}

type Entry {
    name: str,
}

type Sig {
    params: Vec[Param],
}

type Bindings {
    entries: Vec[Entry],
}

error E =
    Bad

fn nested_name_eq(bindings: Bindings) -> bool:
    bindings.entries[0].name == bindings.entries[1].name

fn resolve(sig: Sig, bindings: Bindings) -> Result[Vec[i32], E]:
    var bi: i32 = 0
    while bi < bindings.entries.len() as i32:
        let name = bindings.entries[bi].name
        var next = bi + 1
        while next < bindings.entries.len() as i32:
            if bindings.entries[next].name == name:
                return Err(.Bad)
            next = next + 1
        var known = false
        for pi in 0..sig.params.len():
            if sig.params[pi].name == name:
                known = true
                break
        if not known:
            return Err(.Bad)
        bi = bi + 1

    let ordered: Vec[i32] = Vec.new()
    for pi in 0..sig.params.len():
        let param = sig.params[pi]
        var found = false
        for bind_index in 0..bindings.entries.len():
            let entry = bindings.entries[bind_index]
            if entry.name == param.name:
                found = true
                break
        if not found:
            return Err(.Bad)
        ordered.push(pi as i32)
    Ok(ordered)

fn main:
    let same_entries: Vec[Entry] = Vec.new()
    same_entries.push(Entry { name: "a" })
    same_entries.push(Entry { name: "a" })
    assert(nested_name_eq(Bindings { entries: same_entries }))

    let diff_entries: Vec[Entry] = Vec.new()
    diff_entries.push(Entry { name: "a" })
    diff_entries.push(Entry { name: "b" })
    assert(not nested_name_eq(Bindings { entries: diff_entries }))

    let params: Vec[Param] = Vec.new()
    params.push(Param { name: "a", rank: 1 })
    params.push(Param { name: "out", rank: 0 })
    let entries: Vec[Entry] = Vec.new()
    entries.push(Entry { name: "a" })
    entries.push(Entry { name: "out" })
    let out = match resolve(Sig { params }, Bindings { entries })
        Ok(v) => v
        Err(_) => Vec.new()
    assert(out.len() == 2)
