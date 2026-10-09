//! D22-NON-COMPLIANT
//! owner-stage: 6
//! required-verdict: compile-and-run under `--debug-alloc`
//! exact-type: `get_value` returns `Option[&List[i64]]`; `view` is `&List[i64]`
//! expected-diagnostic: none
//! origin-set: the checked raw reborrow gives `view` `{store}`
//! drop-behavior: `store` remains sole owner and drops the nested List once; leak count=0
//! expect-debug-alloc: leak count=0

// Library-maintainer control for BTreeMap.get: a checked raw reborrow formed
// directly from List storage remains rooted in the enclosing owner.
type D22Store { entries: List[(i32, List[i64])] }

fn get_value(store: &D22Store, index: i64) -> Option[&List[i64]]:
    if index < 0 or index >= store.entries.len():
        return None
    unsafe { Some(&(*(store.entries.ptr + (index as usize))).1) }

fn main:
    let values: List[i64] = List.new()
    values.push(5)
    let entries: List[(i32, List[i64])] = List.new()
    entries.push((1, move values))
    let store = D22Store { entries }
    let view = get_value(&store, 0).unwrap()
    assert(view.len() == 1)
