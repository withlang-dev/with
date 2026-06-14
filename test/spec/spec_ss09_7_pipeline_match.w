// Spec test: Section 9.7 — match in pipelines
//
// `expr |> match:` uses the piped expression as the match subject. This keeps
// pipelines expression-oriented without forcing a temporary binding.

type Ast { value: i32 }

fn parse(input: str) -> Result[Ast, str]:
    if input == "ok":
        Ok(Ast { value: 5 })
    else:
        Err("parse failed")

fn transform(ast: Ast) -> i32:
    ast.value * 10

fn default_ast -> i32:
    -1

fn compile(input: str) -> i32:
    input |> parse |> match:
        Ok(ast) => transform(ast)
        Err(_) => default_ast()

fn test_pipeline_match_ok:
    assert(compile("ok") == 50)

fn test_pipeline_match_err:
    assert(compile("bad") == -1)
