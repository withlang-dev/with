//! expect-stdout: x/engine
//! expect-stdout: y/tests/n
//! expect-stdout: before:x after:y

// `++` over a str read through a view of a view: a tuple-pattern binding
// over a `(str, &str)` element is a `&&str`, and `source ++ "/engine"` is a
// `str` wherever it is demanded (an argument, a binding, a return). Sema
// records the operator's type (D65); before it did not, MIR re-derived it
// from the operands, lost the doubly-viewed `str` and typed the result
// Unit ("call argument 0 is Unit", "use rvalue").

fn take(a: &str): print(a)

fn label_of(before_dir: &str, after_dir: &str) -> str:
    var out = ""
    for (label, source) in [("before", before_dir), ("after", after_dir)]:
        out = out ++ label ++ ":" ++ source ++ " "
    out.trim()

fn bench(before_dir: &str, after_dir: &str, name: &str):
    for (label, source) in [("before", before_dir), ("after", after_dir)]:
        if label == "before":
            take(source ++ "/engine")
        else:
            let path = source ++ "/tests/" ++ name
            take(path)

fn main:
    bench("x", "y", "n")
    print(label_of("x", "y"))
