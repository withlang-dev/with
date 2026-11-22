//! expect-stdout: ok
// #1021: the root's dirname and basename are the root (POSIX); they were "".
// #1023: a union type declaration renders; it was `<unknown type decl>`.
use BuildGraphSupport
use Lexer
use Parser
use InternPool
use Diagnostic
use render

fn main:
    assert(build_graph_dirname("/") == "/")
    assert(build_graph_dirname("/a") == "/")
    assert(build_graph_dirname("/a/b") == "/a")
    assert(build_graph_dirname("a") == ".")
    assert(build_graph_path_basename("/") == "/")
    assert(build_graph_path_basename("/a") == "a")
    assert(build_graph_path_basename("/a/b") == "b")
    assert(build_graph_path_basename("a") == "a")
    let text = "type Ufc = union { freq: u16 = 0, code: u16 = 0 }\n"
    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()
    let intern = InternPool.init()
    let diags = DiagnosticList.init()
    var parser = Parser.init(tokens, text, 0, intern, diags)
    let pool = parser.parse_module()
    let rendered = render_module(pool, intern)
    if not rendered.contains("type Ufc = union") or rendered.contains("unknown type decl"): print(rendered)
    assert(rendered.contains("type Ufc = union") and rendered.contains("freq: u16") and not rendered.contains("unknown type decl"))
    print("ok")
