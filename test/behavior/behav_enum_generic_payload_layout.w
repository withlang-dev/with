type Artifact {
    path: str,
}

type DeclSummary {
    name: str,
}

enum CompilerMessage:
    Typechecked(Vec[DeclSummary])
    Diagnostic(str)
    Artifact(Artifact)

fn main:
    let message = CompilerMessage.Artifact(Artifact { path: "out/bin/app" })
    match message:
        CompilerMessage.Artifact(artifact) => assert(artifact.path == "out/bin/app")
        _ => assert(false)
    print("ok")
