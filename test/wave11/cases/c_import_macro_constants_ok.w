use c_import("#define ANSWER 42\n#define GREETING \"with\"")

fn main -> i32:
    assert(ANSWER == 42)
    assert(GREETING == "with")
    0
