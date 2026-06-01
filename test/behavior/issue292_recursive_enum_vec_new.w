enum V:
    N(x: i32)
    L(items: Vec[V])

fn take(e: V):
    print("got")

fn main:
    take(V.L(Vec.new()))
    print("done")
