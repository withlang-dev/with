//! expect-debug-alloc: leak count=0
// #1365 (§9.7, §2.4): `let PAT = subject else: <diverge>` consumes its
// subject on both paths. When the pattern does not match, the whole subject —
// whichever variant it holds — drops exactly once before the else body
// diverges (return / break / continue); when it matches, only the bound parts
// move into the bindings and the unbound owned parts drop exactly once.
// Before the fix the failing path leaked the non-matching variant's payload
// (a `str` Err) and dropped the never-initialized binding (a `Vec[str]` Ok
// payload freed stack garbage).

type Pair { name: str, tags: Vec[str] }

enum Shape:
    Named(str)
    Listed(Vec[str])
    Empty

fn owned(s: &str): s.clone()

fn words(n: i32) -> Vec[str]:
    var v: Vec[str] = Vec.new()
    for i in 0..n: v.push(f"w{i}")
    v

fn int_or_err(k: i32) -> Result[i32, str]:
    if k == 0: return Err(owned("none"))
    k

fn vec_or_err(k: i32) -> Result[Vec[str], str]:
    if k == 0: return Err(owned("none"))
    words(k)

fn maybe_vec(k: i32) -> Option[Vec[str]]:
    if k == 0: return None
    Some(words(k))

fn shape(k: i32) -> Shape:
    if k == 0: return Shape.Named(owned("n"))
    if k == 1: return Shape.Empty
    Shape.Listed(words(k))

fn nested(k: i32) -> Option[Shape]:
    if k < 0: return None
    Some(shape(k))

fn pair_or_err(k: i32) -> Result[Pair, str]:
    if k == 0: return Err(owned("none"))
    Ok(Pair { name: owned("p"), tags: words(k) })

fn tuple_or_err(k: i32) -> Result[(str, Vec[str]), str]:
    if k == 0: return Err(owned("none"))
    Ok((owned("t"), words(k)))

// Subject is the call's temporary.
fn int_temp(k: i32) -> i32:
    let Ok(v) = int_or_err(k) else: return -1
    v

fn vec_temp(k: i32) -> i32:
    let Ok(v) = vec_or_err(k) else: return -1
    v.len() as i32

fn option_temp(k: i32) -> i32:
    let Some(v) = maybe_vec(k) else: return -1
    v.len() as i32

fn enum_temp(k: i32) -> i32:
    let .Listed(v) = shape(k) else: return -1
    v.len() as i32

fn nested_temp(k: i32) -> i32:
    let Some(.Listed(v)) = nested(k) else: return -1
    v.len() as i32

fn pair_temp(k: i32) -> i32:
    let Ok(p) = pair_or_err(k) else: return -1
    p.tags.len() as i32 + p.name.len() as i32

// `_` owns and drops the unbound tuple element on the matching path.
fn tuple_temp(k: i32) -> i32:
    let Ok((_, tags)) = tuple_or_err(k) else: return -1
    tags.len() as i32

// Subject is a named local.
fn vec_local(k: i32) -> i32:
    let r = vec_or_err(k)
    let Ok(v) = r else: return -1
    v.len() as i32

fn enum_local(k: i32) -> i32:
    let s = shape(k)
    let .Named(n) = s else: return -1
    n.len() as i32

// break / continue leave the loop body with the subject dropped.
fn vec_break(k: i32) -> i32:
    var total = 0
    for i in 0..3:
        let Ok(v) = vec_or_err(k - i) else: break
        total = total + v.len() as i32
    total

fn vec_continue(k: i32) -> i32:
    var total = 0
    for i in 0..3:
        let Ok(v) = vec_or_err(k - i) else: continue
        total = total + v.len() as i32
    total

fn nested_local_continue(k: i32) -> i32:
    var total = 0
    for i in 0..4:
        let s = nested(k - i)
        let Some(.Listed(v)) = s else: continue
        total = total + v.len() as i32
    total

// #1383 (§2.2, §9.7): the else branch diverges, so a value it consumes is
// consumed on that path only. The matching path still owns it whole: its
// reads see the value and its scope-exit drop frees it. Before the fix Sema
// rejected the later read, and MIR flushed the else branch's reset-on-move
// blank on the matching path (`keep` read "" and its buffer leaked).
fn consume(s: str) -> i32: s.len() as i32

type Holder { f: str, g: str }

fn keep_inline(k: i32) -> i32:
    let keep = owned("keep")
    let Ok(v) = vec_or_err(k) else: return consume(keep) - 100
    keep.len() as i32 + v.len() as i32

fn keep_block(k: i32) -> i32:
    let keep = owned("keep")
    let Ok(v) = vec_or_err(k) else:
        let n = consume(keep)
        return n - 100
    keep.len() as i32 + v.len() as i32

fn keep_field(k: i32) -> i32:
    var h = Holder { f: owned("f"), g: owned("gg") }
    let Ok(v) = vec_or_err(k) else: return consume(move h.f) - 100
    h.f.len() as i32 + h.g.len() as i32 + v.len() as i32

fn keep_twice(k: i32) -> i32:
    let keep = owned("keep")
    let Ok(v) = vec_or_err(k) else: return consume(keep) - 100
    let Ok(w) = vec_or_err(k + 1) else: return consume(keep) - 200
    consume(keep) + v.len() as i32 + w.len() as i32

fn keep_continue(k: i32) -> i32:
    var total = 0
    for i in 0..3:
        let keep = f"k{i}"
        let Ok(v) = vec_or_err(k - i) else:
            total = total + consume(keep)
            continue
        total = total + keep.len() as i32 + v.len() as i32
    total

fn main:
    assert(keep_inline(0) == -96)
    assert(keep_inline(1) == 5)
    assert(keep_block(0) == -96)
    assert(keep_block(1) == 5)
    assert(keep_field(0) == -99)
    assert(keep_field(1) == 4)
    assert(keep_twice(0) == -96)
    assert(keep_twice(1) == 7)
    assert(keep_continue(1) == 7)
    assert(int_temp(0) == -1)
    assert(int_temp(3) == 3)
    assert(vec_temp(0) == -1)
    assert(vec_temp(2) == 2)
    assert(option_temp(0) == -1)
    assert(option_temp(2) == 2)
    assert(enum_temp(0) == -1)
    assert(enum_temp(1) == -1)
    assert(enum_temp(3) == 3)
    assert(nested_temp(-1) == -1)
    assert(nested_temp(0) == -1)
    assert(nested_temp(4) == 4)
    assert(pair_temp(0) == -1)
    assert(pair_temp(2) == 3)
    assert(tuple_temp(0) == -1)
    assert(tuple_temp(2) == 2)
    assert(vec_local(0) == -1)
    assert(vec_local(2) == 2)
    assert(enum_local(0) == 1)
    assert(enum_local(3) == -1)
    assert(vec_break(1) == 1)
    assert(vec_continue(1) == 1)
    assert(nested_local_continue(3) == 5)
    print("ok")
