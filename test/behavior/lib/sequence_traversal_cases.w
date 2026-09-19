// Traversal observes (§2.3, §13): `for` over a slice or array of Drop-class
// elements binds `&T` views and leaves the sequence intact. Each case traverses
// twice; under the scribbling debug allocator a copied-and-dropped element, or
// an array moved into the loop, shows on the second pass.

fn join_slice(words: []str) -> str:
    var out = ""
    for w in words: out = out ++ w ++ ","
    out

fn join_slice_ref(words: &[str]) -> str:
    var out = ""
    for w in words: out = out ++ w ++ ","
    out

fn join_array_ref(words: &[2]str) -> str:
    var out = ""
    for w in words: out = out ++ w ++ ","
    out

fn sum(xs: &[i32]) -> i32:
    var total = 0
    for x in xs: total = total + x
    total

type Holder { names: [2]str }

fn main:
    let words = ["one".to_owned() ++ "!", "two".to_owned() ++ "?"]
    assert(join_slice(words[..]) == "one!,two?,")
    assert(join_slice(words[..]) == "one!,two?,")
    assert(join_slice_ref(words[..]) == "one!,two?,")
    assert(join_slice_ref(words[..]) == "one!,two?,")
    assert(join_array_ref(&words) == "one!,two?,")
    assert(join_array_ref(&words) == "one!,two?,")
    var direct = ""
    for w in words: direct = direct ++ w ++ ";"
    for w in words: direct = direct ++ w ++ ";"
    assert(direct == "one!;two?;one!;two?;")
    assert(words[0] == "one!" and words[1] == "two?")
    let holder = Holder { names: ["a".to_owned() ++ "1", "b".to_owned() ++ "2"] }
    var held = ""
    for n in holder.names: held = held ++ n
    for n in holder.names: held = held ++ n
    assert(held == "a1b2a1b2")
    let nums = [1, 2, 3]
    let none: [0]i32 = []
    assert(sum(nums[..]) == 6 and sum(nums[1..1]) == 0 and sum(none[..]) == 0)
    print("ok")
