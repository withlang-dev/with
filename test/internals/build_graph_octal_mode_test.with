//! expect-stdout: ok
// #971: a copy_file or install mode is an octal file mode, at most 0o7777.
// `10000` was accepted and the host masked it to 0000 (an unreadable file).
use BuildGraphOps

fn main:
    assert(build_graph_parse_octal_mode("644") == 0o644)
    assert(build_graph_parse_octal_mode("0755") == 0o755)
    assert(build_graph_parse_octal_mode("7777") == 0o7777)
    assert(build_graph_parse_octal_mode("10000") == -1)
    assert(build_graph_parse_octal_mode("777777777777") == -1)
    assert(build_graph_parse_octal_mode("") == -1)
    assert(build_graph_parse_octal_mode("8") == -1)
    print("ok")
