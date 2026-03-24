use issue37.core

type State {
    values: Vec[Value],
}

fn len_i32(state: State) -> i32:
    state.values.len() as i32

pub fn sentinel -> i32:
    0
