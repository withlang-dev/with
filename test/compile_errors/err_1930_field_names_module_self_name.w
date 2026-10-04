//! expect-error: bare 'err_1930_field_names_module_self_name' names both a field of the receiver `Odd` and this module's own name

// §9.5 (#1930), §18.1: the module's self-name is a name in scope (a
// qualifier only), so a field of that name is not reached by its bare name.

type Odd {
    err_1930_field_names_module_self_name: i32,
}

impl Odd:
    fn get -> i32: err_1930_field_names_module_self_name

fn main:
    let o = Odd { err_1930_field_names_module_self_name: 1 }
    print(f"{o.get()}")
