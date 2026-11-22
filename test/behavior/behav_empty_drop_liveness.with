//! expect-stdout: 12
//! expect-stdout: 12
//! expect-stdout: 22
//! expect-stdout: 2
//! expect-stdout: 2
//! expect-stdout: sizes 0 1 1 2

// D72 applies to empty Drop types as well as types with zero-valued fields.
// Member/element drop guards must distinguish a live empty owner from a move.
var trace: i32 = 0
fn note(n: i32): trace = trace * 10 + n

type Empty {}
type Child {}
extend Child:
    mut fn shutdown(): note(1)
impl Drop for Child:
    move fn drop(): note(2)

type Owner[T] { child: T }
impl[T] Drop for Owner[T]:
    move fn drop(): self.child.shutdown()

type PlainOwner { child: Child }

fn generic_owner(early: bool):
    let child = Child {}
    let owner = Owner { child }
    if early: return

fn elements:
    var children: List[Child] = List.new()
    children.push(Child {})
    children.push(Child {})

fn plain_owner:
    let owner = PlainOwner { child: Child {} }

fn make_child -> Child: Child {}

fn returned_owner:
    let child = make_child()
    let owner = PlainOwner { child }

fn main:
    generic_owner(false)
    print(trace)
    trace = 0
    generic_owner(true)
    print(trace)
    trace = 0
    elements()
    print(trace)
    trace = 0
    plain_owner()
    print(trace)
    trace = 0
    returned_owner()
    print(trace)
    print(f"sizes {size_of[Empty]()} {size_of[Child]()} {size_of[PlainOwner]()} {size_of[Owner[Child]]()}")
