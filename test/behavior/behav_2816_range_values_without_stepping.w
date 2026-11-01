//! expect-stdout: true
//! expect-stdout: 97 98 99

// #2816 (§4.7): a range of str is still a value — bounds and membership —
// only iteration needs a successor; a range of code points steps.
fn main:
    let letters = "a".."z"
    print("m" in letters)
    var out = ""
    for c in 'a'..='c': out = out ++ (if out.len() > 0: " " else: "") ++ f"{c}"
    print(out)
