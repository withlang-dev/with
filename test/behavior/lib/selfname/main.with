// §18.1 fixture (#1930): a module whose stem is `main` names itself `main`.
// `main.helper()` reaches its own declaration; the bare `main` is still the
// function of that name.

fn main -> i32: 40

fn helper -> i32: 2

pub fn main_module_answer -> i32: main.helper() + main()
