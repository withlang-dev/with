use issue61_queries.shared

pub type IntList = Vec[i32]

pub type StateBox[T] {
    value: T,
}

pub fn make_alias_list() -> IntList:
    let values: IntList = Vec.new()
    values.push(2)
    values.push(4)
    values.push(8)
    values

pub fn make_lookup() -> HashMap[str, i32]:
    let lookup = HashMap[str, i32].new()
    lookup.insert("alpha,one", 11)
    lookup.insert("beta", 7)
    lookup

pub fn boxed_state(state: State) -> StateBox[State]:
    let boxed: StateBox[State] = StateBox { value: state }
    boxed

pub fn alias_and_temporary_score(state: State) -> i32:
    let state_box = boxed_state(state)
    let alias_list = make_alias_list()
    var total = alias_list.len() as i32
    total = total + make_alias_list().len() as i32
    total = total + state_box.value.entries.len() as i32
    total = total + make_lookup().len() as i32
    if make_lookup().contains("beta"):
        total = total + 1
    if state_box.value.bonus.is_ok():
        total = total + 2
    if make_lookup().get("missing").is_none():
        total = total + 1
    total = total + make_lookup().get("beta").unwrap()
    total = total + state_box.value.alias.unwrap().len() as i32
    total
