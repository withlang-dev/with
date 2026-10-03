//! expect-stdout: ok 3 e2
//! expect-stdout: err big

// #2017: `out.push(get(i)?)` copies the Ok payload of a Result local into
// the push argument. The C backend guessed the local was an Option of that
// payload (Option[Entry]) over MIR's declared Result[Entry, str], then
// refused the Err downcast as "payload downcast for unit enum variant 1"
// (std.zip's ZipArchive.entries, in the compiler's own C).

type Entry { name: str, size: i64 }

fn get(i: i32) -> Result[Entry, str]:
    if i > 5: return Err("big".clone())
    Ok(Entry { name: f"e{i}", size: i as i64 })

fn all(n: i32) -> Result[Vec[Entry], str]:
    var out: Vec[Entry] = Vec.new()
    var i = 0
    while i < n:
        out.push(get(i)?)
        i = i + 1
    out

fn main:
    match all(3):
        Ok(v) => print(f"ok {v.len()} {v[2].name}")
        Err(e) => print(f"err {e}")
    match all(8):
        Ok(v) => print(f"ok {v.len()}")
        Err(e) => print(f"err {e}")
