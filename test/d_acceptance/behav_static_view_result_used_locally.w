//! expect-stdout: 1

// A callee's escape_view effect describes the origin of its returned value.
// Using that value only inside the caller must not make the caller return a
// view from its own owned parameter.
type LocalViewFactory { marker: i32 }

fn LocalViewFactory.borrow(values: &Vec[i32]) -> &Vec[i32]: values

fn inspect(values: Vec[i32]) -> i32:
    let view = LocalViewFactory.borrow(&values)
    view.len() as i32

fn main:
    let values: Vec[i32] = Vec.new()
    values.push(7)
    print_i32(inspect(move values))
