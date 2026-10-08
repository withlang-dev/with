//! args: --validate-all
//! expect-check-stdout: validate-all: ok

// #1750 (§9.7, §2.4): a let-else's success path keeps its subject's cleanup
// — what the bindings moved out is blanked, the rest is freed there. It was
// retired on both paths, so with a Copy payload the success path left an
// owned subject Init at return: "owned local _3 is still Init at return —
// no path drops or moves it (a leak)". Owned payloads, ignored owned parts
// and named subjects are the other shapes of the same statement.

type Pair { name: str, tags: Vec[str] }

fn owned(s: &str): s

fn int_or_err(k: i32) -> Result[i32, str]:
    if k == 0: return Err(owned("none"))
    k

fn vec_or_err(k: i32) -> Result[Vec[str], str]:
    if k == 0: return Err(owned("none"))
    var v: Vec[str] = Vec.new()
    for i in 0..k: v.push(f"w{i}")
    v

fn tuple_or_err(k: i32) -> Result[(str, i32), str]:
    if k == 0: return Err(owned("none"))
    Ok((owned("t"), k))

fn pair_or_err(k: i32) -> Result[Pair, str]:
    if k == 0: return Err(owned("none"))
    Ok(Pair { name: owned("p"), tags: Vec.new() })

fn copy_payload(k: i32) -> i32:
    let Ok(v) = int_or_err(k) else: return -1
    v

fn owned_payload(k: i32) -> i32:
    let Ok(v) = vec_or_err(k) else: return -1
    v.len() as i32

fn ignored_owned_part(k: i32) -> i32:
    let Ok((_, n)) = tuple_or_err(k) else: return -1
    n

fn named_subject(k: i32) -> i32:
    let r = int_or_err(k)
    let Ok(v) = r else: return -1
    v

fn field_moved(k: i32) -> i32:
    let Ok(p) = pair_or_err(k) else: return -1
    p.name.len() as i32

fn main:
    print(f"{copy_payload(0)} {copy_payload(2)} {owned_payload(2)} {ignored_owned_part(3)} {named_subject(4)} {field_moved(1)}")
