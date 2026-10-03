//! expect-stdout: a b c
//! expect-stdout: A B C
//! expect-stdout: 1 2 3
//! expect-stdout: drop a
//! expect-stdout: drop b
//! expect-stdout: drop c
//! expect-stdout: done

// §13.5 (#1837): a generic user collection `Bag[T]` with
// `fn iter() -> BagIter[T]` iterates bare, over the owned bag and over a
// `&Bag[T]` view; the loop observes — a Drop-class element binds as the
// `&T` view `next()` yields, is never copied, and drops exactly once when
// the bag does.
type Tok { name: str }

impl Drop for Tok:
    move fn drop(): print(f"drop {self.name}")

type Bag[T] { items: Vec[T] }

type BagIter[T] = ephemeral { items: &Vec[T], i: i32 }

impl[T] BagIter[T]:
    mut fn next() -> Option[&T]:
        if self.i >= self.items.len32():
            return None
        let v = &self.items[self.i]
        self.i += 1
        Some(v)

impl[T] Bag[T]:
    fn iter() -> BagIter[T]: BagIter { items: &self.items, i: 0 }

fn shout(b: &Bag[Tok]) -> str:
    var out = ""
    for t in b:
        out = if out.len() == 0: t.name.to_upper() else: out ++ " " ++ t.name.to_upper()
    out

fn main:
    var toks: Vec[Tok] = Vec.new()
    toks.push(Tok { name: "a" })
    toks.push(Tok { name: "b" })
    toks.push(Tok { name: "c" })
    let bag = Bag { items: toks }
    var out = ""
    for t in bag:
        out = if out.len() == 0: t.name.clone() else: out ++ " " ++ t.name
    print(out)
    print(shout(&bag))
    var nums: Vec[i32] = Vec.new()
    nums.push(1)
    nums.push(2)
    nums.push(3)
    let nbag = Bag { items: nums }
    var nout = ""
    for n in nbag:
        nout = if nout.len() == 0: f"{n}" else: nout ++ f" {n}"
    print(nout)
    drop(bag)
    print("done")
