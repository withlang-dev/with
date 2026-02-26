#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "building compiler/runtime for phase6 lsp tests..."
zig build -Doptimize=Debug >/dev/null

python3 <<'PY'
import json
import subprocess
import sys

WITH_BIN = "./zig-out/bin/with"

def read_message(stream):
    header = b""
    while b"\r\n\r\n" not in header:
        b = stream.read(1)
        if not b:
            raise RuntimeError("lsp stream closed while reading headers")
        header += b
    head, _ = header.split(b"\r\n\r\n", 1)
    length = None
    for line in head.split(b"\r\n"):
        if line.lower().startswith(b"content-length:"):
            length = int(line.split(b":", 1)[1].strip())
            break
    if length is None:
        raise RuntimeError("missing Content-Length header")
    body = stream.read(length)
    if len(body) != length:
        raise RuntimeError("short lsp body read")
    return json.loads(body.decode("utf-8"))

def send_message(proc, payload):
    raw = json.dumps(payload, separators=(",", ":")).encode("utf-8")
    hdr = f"Content-Length: {len(raw)}\r\n\r\n".encode("ascii")
    proc.stdin.write(hdr)
    proc.stdin.write(raw)
    proc.stdin.flush()

def read_until(proc, predicate, limit=64):
    for _ in range(limit):
        msg = read_message(proc.stdout)
        if predicate(msg):
            return msg
    raise RuntimeError("expected lsp message not received within limit")

proc = subprocess.Popen(
    [WITH_BIN, "lsp"],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
)

try:
    source_ok = """fn make_point -> i32: 1
fn use_point -> i32:
    make_point()
"""
    uri = "file:///tmp/with_lsp_phase6.w"

    # initialize
    send_message(proc, {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {}})
    init_resp = read_until(proc, lambda m: m.get("id") == 1)
    caps = init_resp["result"]["capabilities"]
    assert caps.get("hoverProvider") is True
    assert caps.get("definitionProvider") is True
    assert caps.get("referencesProvider") is True
    assert caps.get("renameProvider") is True
    print("PASS(lsp-init-capabilities)")

    send_message(proc, {"jsonrpc": "2.0", "method": "initialized", "params": {}})

    # didOpen + diagnostics
    send_message(proc, {
        "jsonrpc": "2.0",
        "method": "textDocument/didOpen",
        "params": {
            "textDocument": {
                "uri": uri,
                "languageId": "with",
                "version": 1,
                "text": source_ok,
            }
        },
    })
    diag_ok = read_until(proc, lambda m: m.get("method") == "textDocument/publishDiagnostics")
    assert diag_ok["params"]["uri"] == uri
    print("PASS(lsp-diagnostics-open)")

    # hover on call site make_point
    send_message(proc, {
        "jsonrpc": "2.0",
        "id": 2,
        "method": "textDocument/hover",
        "params": {
            "textDocument": {"uri": uri},
            "position": {"line": 2, "character": 6},
        },
    })
    hover = read_until(proc, lambda m: m.get("id") == 2)
    hover_text = json.dumps(hover)
    assert "make_point" in hover_text or "fn i32" in hover_text
    print("PASS(lsp-hover)")

    # definition on call site
    send_message(proc, {
        "jsonrpc": "2.0",
        "id": 3,
        "method": "textDocument/definition",
        "params": {
            "textDocument": {"uri": uri},
            "position": {"line": 2, "character": 6},
        },
    })
    definition = read_until(proc, lambda m: m.get("id") == 3)
    assert definition["result"]["uri"] == uri
    assert definition["result"]["range"]["start"]["line"] == 0
    print("PASS(lsp-definition)")

    # completion near call site
    send_message(proc, {
        "jsonrpc": "2.0",
        "id": 4,
        "method": "textDocument/completion",
        "params": {
            "textDocument": {"uri": uri},
            "position": {"line": 2, "character": 7},
        },
    })
    completion = read_until(proc, lambda m: m.get("id") == 4)
    labels = [item.get("label") for item in completion["result"]["items"]]
    assert "make_point" in labels
    print("PASS(lsp-completion)")

    # references on make_point
    send_message(proc, {
        "jsonrpc": "2.0",
        "id": 5,
        "method": "textDocument/references",
        "params": {
            "textDocument": {"uri": uri},
            "position": {"line": 2, "character": 6},
            "context": {"includeDeclaration": True},
        },
    })
    refs = read_until(proc, lambda m: m.get("id") == 5)
    assert isinstance(refs["result"], list)
    assert len(refs["result"]) >= 2
    print("PASS(lsp-references)")

    # rename make_point -> make_point2
    send_message(proc, {
        "jsonrpc": "2.0",
        "id": 6,
        "method": "textDocument/rename",
        "params": {
            "textDocument": {"uri": uri},
            "position": {"line": 2, "character": 6},
            "newName": "make_point2",
        },
    })
    rename = read_until(proc, lambda m: m.get("id") == 6)
    changes = rename["result"]["changes"][uri]
    assert len(changes) >= 2
    assert all(edit["newText"] == "make_point2" for edit in changes)
    print("PASS(lsp-rename)")

    # didChange with invalid source should publish non-empty diagnostics.
    source_bad = "fn bad( -> i32 = 0\n"
    send_message(proc, {
        "jsonrpc": "2.0",
        "method": "textDocument/didChange",
        "params": {
            "textDocument": {"uri": uri, "version": 2},
            "contentChanges": [{"text": source_bad}],
            "text": source_bad,
        },
    })
    diag_bad = read_until(proc, lambda m: m.get("method") == "textDocument/publishDiagnostics")
    assert diag_bad["params"]["uri"] == uri
    assert len(diag_bad["params"]["diagnostics"]) > 0
    print("PASS(lsp-diagnostics-change)")

    # shutdown / exit
    send_message(proc, {"jsonrpc": "2.0", "id": 7, "method": "shutdown", "params": {}})
    _ = read_until(proc, lambda m: m.get("id") == 7)
    send_message(proc, {"jsonrpc": "2.0", "method": "exit", "params": {}})

except Exception as exc:
    print(f"FAIL(phase6-lsp): {exc}", file=sys.stderr)
    proc.kill()
    proc.wait(timeout=5)
    sys.exit(1)
finally:
    try:
        proc.terminate()
    except Exception:
        pass

print("phase6 lsp tests: PASS")
PY
