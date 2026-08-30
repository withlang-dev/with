//! expect-stdout: ok

type Tool {
    prefix: str,
}

global tool = Tool { prefix: "ok" }

fn Tool.label(self: &Self) -> str:
    self.prefix.clone()

fn main:
    assert(tool.label() == "ok")
    print("ok")
