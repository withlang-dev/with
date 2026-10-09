//! expect-stdout: ok
// Static method calls have no receiver param: arg_i pairs with param_i.
// The effect/view propagation used a hardcoded receiver offset, so arg0
// (a Copy pool handle) inherited param1 (a Drop-payload diags param)'s
// consume verdict, requiring `move` on a Copy value and escalating the
// calling method's receiver. Provable on shipped seeds; must compile.
type R { id: i32 }
impl Drop for R:
    move fn drop(): print(f"drop {self.id}")

type PS { xs: List[i32] }
type P { state: *mut PS }
impl Copy for P

type DL { items: List[R] }

type SM { p: P, d: DL }

fn SM.holder(p: P, d: DL) -> SM:
    SM { p: p, d: d }

type Z { pool: P, last: SM }

extend Z:
    mut fn clear():
        self.last = SM.holder(self.pool, DL { items: List.new() })

fn main:
    print("ok")
