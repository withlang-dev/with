//! env: WITH_CODEGEN_UNITS=8
//! expect-stdout: 4
//! expect-stdout: 376

// #681 codegen units, the method-receiver case of #1325: `Vec[i32].clone`
// is a concrete receiver specialization (`Vec.clone__receiver__<owner>_<T>`)
// whose MIR body is packed into one unit while its caller sits in another.
// A compiler without #1325's gen_owned_specializations defined the instance
// only on demand in the caller's unit, demoted it there, and the link came
// up undefined (`_Vec.clone__receiver__94_3` referenced from
// `___wcu$146$Holder.dup in t.o.u1.o`, defined by no unit) — the pinned
// seed failed this way linking stage1 once src/MirCore.w cloned a Vec[i32].

fn big(n: i32) -> i32:
    var acc = 0
    for i in 0..n:
        acc = acc + i * 3
        if acc % 7 == 0: acc = acc - 1
        if acc % 11 == 0: acc = acc + 2
        if acc % 13 == 0: acc = acc + 5
    acc

fn t1(): big(3)
fn t2(): big(5)
fn t3(): big(7)
fn t4(): big(9)
fn t5(): big(11)

type Holder { refs: Vec[i32] }

impl Holder:
    fn dup(): Holder { refs: self.refs.clone() }

fn caller() -> i32:
    var v: Vec[i32] = Vec.new()
    v.push(4)
    let h = Holder { refs: v }
    let d = h.dup()
    d.refs[0]

fn main:
    print(f"{caller()}")
    print(f"{t1() + t2() + t3() + t4() + t5()}")
