#!/bin/bash
# LSP integration tests using expect for proper stdio interaction.
set -euo pipefail

WITH="${WITH:-./out/bin/with-stage2}"
PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

check() {
    local name="$1"
    local output="$2"
    local pattern="$3"
    if echo "$output" | grep -q "$pattern"; then
        PASS=$((PASS + 1))
        echo "  PASS: $name"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL: $name"
        echo "    expected: $pattern"
        echo "    got: $(echo "$output" | head -c 200)"
    fi
}

check_not() {
    local name="$1"
    local output="$2"
    local pattern="$3"
    if echo "$output" | grep -q "$pattern"; then
        FAIL=$((FAIL + 1))
        echo "  FAIL: $name (should NOT match)"
    else
        PASS=$((PASS + 1))
        echo "  PASS: $name"
    fi
}

# Send LSP messages and capture output. Uses python for correct JSON encoding.
lsp_test() {
    local text_file="$1"
    local request="$2"
    python3 -c "
import sys, json

text = open(sys.argv[1]).read()
request = sys.argv[2]

init = json.dumps({'jsonrpc':'2.0','id':1,'method':'initialize','params':{'capabilities':{}}})
didopen = json.dumps({'jsonrpc':'2.0','method':'textDocument/didOpen','params':{'textDocument':{'uri':'file:///tmp/lsp_test.w','languageId':'with','version':1,'text':text}}})

def frame(msg):
    return f'Content-Length: {len(msg)}\r\n\r\n{msg}'

sys.stdout.write(frame(init) + frame(didopen) + frame(request))
sys.stdout.flush()
" "$text_file" "$request" | timeout 10 "$WITH" lsp 2>/dev/null || true
}

echo "=== LSP Integration Tests ==="
echo ""

# ── Phase 2: Error-tolerant parser ──────────────────────────
echo "Phase 2: Error-tolerant parser"

for f in test/compile_errors/err_recovery_*.w; do
    name=$(basename "$f" .w)
    result=$(timeout 5 "$WITH" check "$f" 2>&1 || true)
    check "$name: error without crash" "$result" "error:"
    if echo "$result" | grep -qi "panic\|SIGSEGV\|abort"; then
        FAIL=$((FAIL + 1))
        echo "  FAIL: $name crashed!"
    fi
done

echo ""

# ── Phase 3: Scope-aware completion ─────────────────────────
echo "Phase 3: Scope-aware completion"

cat > /tmp/lsp_scope_test.w << 'EOF'
fn greet(name: str, age: i32):
    let greeting = "hello"
    var count = 0
    count

fn main:
    greet("hi", 5)
EOF

# Cursor at line 3, col 4 — inside greet(), on the line "    count"
req_comp='{"jsonrpc":"2.0","id":2,"method":"textDocument/completion","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":3,"character":4}}}'
output=$(lsp_test /tmp/lsp_scope_test.w "$req_comp")
check "params: name" "$output" '"label":"name"'
check "params: age" "$output" '"label":"age"'
check "binding: greeting" "$output" '"label":"greeting"'
check "binding: count" "$output" '"label":"count"'
check "keywords present" "$output" '"label":"fn"'

# Cursor in main — should NOT see greet's locals
req_main='{"jsonrpc":"2.0","id":2,"method":"textDocument/completion","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":6,"character":4}}}'
output_main=$(lsp_test /tmp/lsp_scope_test.w "$req_main")
check_not "no leak: greeting in main" "$output_main" '"label":"greeting"'
check_not "no leak: count in main" "$output_main" '"label":"count"'

# use std. module completion
cat > /tmp/lsp_use_test.w << 'EOF'
use std.

fn main:
    print("hi")
EOF

req_use='{"jsonrpc":"2.0","id":2,"method":"textDocument/completion","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":0,"character":8}}}'
output_use=$(lsp_test /tmp/lsp_use_test.w "$req_use")
check "use std. → collections" "$output_use" '"label":"collections"'
check "use std. → time" "$output_use" '"label":"time"'

# Test: for-loop bindings visible inside loop
cat > /tmp/lsp_for_test.w << 'EOF'
fn main:
    for item in 0..10:
        let doubled = item * 2
        doubled
EOF
req_for='{"jsonrpc":"2.0","id":2,"method":"textDocument/completion","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":3,"character":8}}}'
out_for=$(lsp_test /tmp/lsp_for_test.w "$req_for")
check "for binding: item" "$out_for" '"label":"item"'
check "for binding: doubled" "$out_for" '"label":"doubled"'

# Test: scope boundary — inner not visible after if-block
cat > /tmp/lsp_scope_boundary.w << 'EOF'
fn main:
    let x = 10
    if x > 5:
        let inner = 42
        inner
    let y = 20
    y
EOF
req_scope='{"jsonrpc":"2.0","id":2,"method":"textDocument/completion","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":5,"character":4}}}'
out_scope=$(lsp_test /tmp/lsp_scope_boundary.w "$req_scope")
check "scope: x visible" "$out_scope" '"label":"x"'
check_not "scope: inner NOT visible" "$out_scope" '"label":"inner"'

echo ""

# ── Phase 4: Go-to-definition ──────────────────────────────
echo "Phase 4: Go-to-definition"

cat > /tmp/lsp_def_test.w << 'EOF'
fn helper() -> i32:
    42

fn main:
    let x = helper()
EOF

req_def='{"jsonrpc":"2.0","id":2,"method":"textDocument/definition","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":4,"character":12}}}'
output_def=$(lsp_test /tmp/lsp_def_test.w "$req_def")
check "def: line 0" "$output_def" '"line":0'
check "def: has URI" "$output_def" '"uri":'

# Unknown symbol
req_unk='{"jsonrpc":"2.0","id":2,"method":"textDocument/definition","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":4,"character":0}}}'
output_unk=$(lsp_test /tmp/lsp_def_test.w "$req_unk")
check "def: unknown → null" "$output_unk" '"result":null'

echo ""

# ── Phase 5: Signature help ────────────────────────────────
echo "Phase 5: Signature help"

cat > /tmp/lsp_sig_test.w << 'EOF'
fn greet(name: str, age: i32, active: bool):
    print(name)

fn main:
    greet("hi", 25, true)
EOF

# Param 0 (after opening paren)
req_s0='{"jsonrpc":"2.0","id":2,"method":"textDocument/signatureHelp","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":4,"character":10}}}'
out_s0=$(lsp_test /tmp/lsp_sig_test.w "$req_s0")
check "sig: param 0" "$out_s0" '"activeParameter":0'
check "sig: has label" "$out_s0" '"label":"fn greet'
check "sig: name param" "$out_s0" '"label":"name: str"'

# Param 1 (after first comma)
req_s1='{"jsonrpc":"2.0","id":2,"method":"textDocument/signatureHelp","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":4,"character":16}}}'
out_s1=$(lsp_test /tmp/lsp_sig_test.w "$req_s1")
check "sig: param 1" "$out_s1" '"activeParameter":1'

# Param 2 (after second comma)
req_s2='{"jsonrpc":"2.0","id":2,"method":"textDocument/signatureHelp","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":4,"character":20}}}'
out_s2=$(lsp_test /tmp/lsp_sig_test.w "$req_s2")
check "sig: param 2" "$out_s2" '"activeParameter":2'

# Outside call → null
req_sn='{"jsonrpc":"2.0","id":2,"method":"textDocument/signatureHelp","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":1,"character":4}}}'
out_sn=$(lsp_test /tmp/lsp_sig_test.w "$req_sn")
check "sig: null outside call" "$out_sn" '"result":null'

echo ""

# ── Phase 6: Dot completion ────────────────────────────────
echo "Phase 6: Dot completion"

# str methods
cat > /tmp/lsp_dot_str.w << 'EOF'
fn main:
    let name = "hello"
    name.
EOF
req_ds='{"jsonrpc":"2.0","id":2,"method":"textDocument/completion","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":2,"character":9}}}'
out_ds=$(lsp_test /tmp/lsp_dot_str.w "$req_ds")
check "dot str: len" "$out_ds" '"label":"len"'
check "dot str: slice" "$out_ds" '"label":"slice"'
check "dot str: contains" "$out_ds" '"label":"contains"'

# Struct fields
cat > /tmp/lsp_dot_struct.w << 'EOF'
type Point {
    x: i32,
    y: i32,
    name: str,
}

fn main:
    let p = Point { x: 1, y: 2, name: "origin" }
    p.
EOF
req_dp='{"jsonrpc":"2.0","id":2,"method":"textDocument/completion","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":8,"character":6}}}'
out_dp=$(lsp_test /tmp/lsp_dot_struct.w "$req_dp")
check "dot struct: x" "$out_dp" '"label":"x"'
check "dot struct: y" "$out_dp" '"label":"y"'
check "dot struct: name" "$out_dp" '"label":"name"'

# Vec methods
cat > /tmp/lsp_dot_vec.w << 'EOF'
fn main:
    let v = Vec.new()
    v.
EOF
req_dv='{"jsonrpc":"2.0","id":2,"method":"textDocument/completion","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":2,"character":6}}}'
out_dv=$(lsp_test /tmp/lsp_dot_vec.w "$req_dv")
check "dot vec: push" "$out_dv" '"label":"push"'
check "dot vec: len" "$out_dv" '"label":"len"'
check "dot vec: get" "$out_dv" '"label":"get"'

# Parameter with type annotation
cat > /tmp/lsp_dot_param.w << 'EOF'
type User {
    name: str,
    age: i32,
}

fn greet(u: User):
    u.
EOF
req_du='{"jsonrpc":"2.0","id":2,"method":"textDocument/completion","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":6,"character":6}}}'
out_du=$(lsp_test /tmp/lsp_dot_param.w "$req_du")
check "dot param: name" "$out_du" '"label":"name"'
check "dot param: age" "$out_du" '"label":"age"'

echo ""

# ── Phase 7: Find references ───────────────────────────────
echo "Phase 7: Find references"

cat > /tmp/lsp_refs_test.w << 'EOF'
fn helper(x: i32) -> i32:
    x * 2

fn main:
    let a = helper(1)
    let b = helper(2)
    let c = helper(a + b)
    print(c)
EOF

# References for 'helper' — should find 4 (def + 3 calls)
req_ref='{"jsonrpc":"2.0","id":2,"method":"textDocument/references","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":0,"character":3},"context":{"includeDeclaration":true}}}'
out_ref=$(lsp_test /tmp/lsp_refs_test.w "$req_ref")
# Count occurrences of "range" in the result (one per reference)
ref_count=$(echo "$out_ref" | grep -o '"range"' | wc -l | tr -d ' ')
if [ "$ref_count" -ge 4 ]; then
    PASS=$((PASS + 1))
    echo "  PASS: helper has 4+ references"
else
    FAIL=$((FAIL + 1))
    echo "  FAIL: helper references (expected 4+, got $ref_count)"
fi

# References for 'x' parameter — should find 2 (param + usage)
req_ref_x='{"jsonrpc":"2.0","id":2,"method":"textDocument/references","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":0,"character":10},"context":{"includeDeclaration":true}}}'
out_ref_x=$(lsp_test /tmp/lsp_refs_test.w "$req_ref_x")
ref_count_x=$(echo "$out_ref_x" | grep -o '"range"' | wc -l | tr -d ' ')
if [ "$ref_count_x" -ge 2 ]; then
    PASS=$((PASS + 1))
    echo "  PASS: x has 2+ references"
else
    FAIL=$((FAIL + 1))
    echo "  FAIL: x references (expected 2+, got $ref_count_x)"
fi

# References for unknown identifier — should return empty
req_ref_none='{"jsonrpc":"2.0","id":2,"method":"textDocument/references","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":7,"character":0},"context":{"includeDeclaration":true}}}'
out_ref_none=$(lsp_test /tmp/lsp_refs_test.w "$req_ref_none")
check "refs: empty for non-ident" "$out_ref_none" '"result":\[\]'

# Extend block methods
cat > /tmp/lsp_dot_extend.w << 'EOF'
type Point {
    x: i32,
    y: i32,
}

extend Point:
    fn distance(self: Point) -> i32:
        self.x + self.y

    fn translate(self: Point, dx: i32) -> Point:
        Point { x: self.x + dx, y: self.y }

fn main:
    let p = Point { x: 1, y: 2 }
    p.
EOF
req_de='{"jsonrpc":"2.0","id":2,"method":"textDocument/completion","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":14,"character":6}}}'
out_de=$(lsp_test /tmp/lsp_dot_extend.w "$req_de")
check "dot extend: x field" "$out_de" '"label":"x"'
check "dot extend: y field" "$out_de" '"label":"y"'
check "dot extend: distance" "$out_de" '"label":"distance"'
check "dot extend: translate" "$out_de" '"label":"translate"'

echo ""

# ── Phase 8: Rename symbol ────────────────────────────────
echo "Phase 8: Rename symbol"

cat > /tmp/lsp_rename_test.w << 'EOF'
fn helper(x: i32) -> i32:
    x * 2

fn main:
    let a = helper(1)
    let b = helper(2)
EOF
req_rename='{"jsonrpc":"2.0","id":2,"method":"textDocument/rename","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":0,"character":3},"newName":"util"}}'
out_rename=$(lsp_test /tmp/lsp_rename_test.w "$req_rename")
# Should return a WorkspaceEdit with TextEdit entries
rename_count=$(echo "$out_rename" | grep -o '"newText":"util"' | wc -l | tr -d ' ')
if [ "$rename_count" -ge 3 ]; then
    PASS=$((PASS + 1))
    echo "  PASS: rename helper→util ($rename_count edits)"
else
    FAIL=$((FAIL + 1))
    echo "  FAIL: rename (expected 3+ edits, got $rename_count)"
    echo "    output: $(echo "$out_rename" | head -c 300)"
fi

# Rename on non-ident should return null
req_rename_none='{"jsonrpc":"2.0","id":2,"method":"textDocument/rename","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":5,"character":0},"newName":"foo"}}'
out_rename_none=$(lsp_test /tmp/lsp_rename_test.w "$req_rename_none")
check "rename: null for non-ident" "$out_rename_none" '"result":null'

# Rename with invalid identifier should return error
req_rename_bad='{"jsonrpc":"2.0","id":2,"method":"textDocument/rename","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":0,"character":3},"newName":"123bad"}}'
out_rename_bad=$(lsp_test /tmp/lsp_rename_test.w "$req_rename_bad")
check "rename: invalid ident error" "$out_rename_bad" '"error"'

echo ""

# ── Doc comments on hover ────────────────────────────────
echo "Doc comments on hover"

cat > /tmp/lsp_doc_test.w << 'EOF'
/// Adds two numbers together.
/// Returns the sum.
fn add(a: i32, b: i32) -> i32:
    a + b

fn main:
    add(1, 2)
EOF
req_doc='{"jsonrpc":"2.0","id":2,"method":"textDocument/hover","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":6,"character":4}}}'
out_doc=$(lsp_test /tmp/lsp_doc_test.w "$req_doc")
check "hover: has fn name" "$out_doc" 'fn add'
check "hover: has doc comment" "$out_doc" 'Adds two numbers'

echo ""

# ── Prelude completions ──────────────────────────────────
echo "Prelude completions"

cat > /tmp/lsp_prelude_test.w << 'EOF'
fn main:
    pri
EOF
req_prelude='{"jsonrpc":"2.0","id":2,"method":"textDocument/completion","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":1,"character":7}}}'
out_prelude=$(lsp_test /tmp/lsp_prelude_test.w "$req_prelude")
check "prelude: print" "$out_prelude" '"label":"print"'
check "prelude: Vec" "$out_prelude" '"label":"Vec"'
check "prelude: Option" "$out_prelude" '"label":"Option"'
check "prelude: assert" "$out_prelude" '"label":"assert"'

echo ""

# ── Trait method completion ──────────────────────────────
echo "Trait method completion"

cat > /tmp/lsp_trait_test.w << 'EOF'
trait Drawable =
    fn draw(self) -> str
    fn area(self) -> i32

type Circle {
    radius: i32,
}

impl Drawable for Circle =
    fn draw(self: Circle) -> str:
        "circle"
    fn area(self: Circle) -> i32:
        self.radius * self.radius

fn main:
    let c = Circle { radius: 5 }
    c.
EOF
req_trait='{"jsonrpc":"2.0","id":2,"method":"textDocument/completion","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":16,"character":6}}}'
out_trait=$(lsp_test /tmp/lsp_trait_test.w "$req_trait")
check "trait: radius field" "$out_trait" '"label":"radius"'
check "trait: draw method" "$out_trait" '"label":"draw"'
check "trait: area method" "$out_trait" '"label":"area"'

# ── Scope-aware references (item 2) ──────────────────────
echo "Scope-aware references"

# Local variable 'x' in one function should NOT find 'x' in another function
cat > /tmp/lsp_scope_refs.w << 'EOF'
fn foo():
    let x = 1
    print(x)

fn bar():
    let x = 2
    print(x)
EOF
# References for 'x' at line 1 (inside foo) — should find 2 (def + use in foo), NOT 4
req_scope_ref='{"jsonrpc":"2.0","id":2,"method":"textDocument/references","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":1,"character":8},"context":{"includeDeclaration":true}}}'
out_scope_ref=$(lsp_test /tmp/lsp_scope_refs.w "$req_scope_ref")
# Extract only the refs response (contains "id":2), count ranges in it
scope_refs_response=$(echo "$out_scope_ref" | tr '\n' ' ' | grep -o '"id":2[^}]*\[.*\]' | head -1)
scope_ref_count=$(echo "$scope_refs_response" | grep -o '"range"' | wc -l | tr -d ' ')
if [ "$scope_ref_count" -ge 1 ] && [ "$scope_ref_count" -le 3 ]; then
    PASS=$((PASS + 1))
    echo "  PASS: local x scoped to foo ($scope_ref_count refs)"
else
    FAIL=$((FAIL + 1))
    echo "  FAIL: local x scope (got $scope_ref_count refs, expected 1-3)"
fi

echo ""

# ── Slow-tier type inference (item 3) ────────────────────
echo "Slow-tier type inference"

# Type inferred from function return value — fast tier can't resolve this,
# but slow tier's typed_expr_types should provide the type.
cat > /tmp/lsp_slow_type.w << 'EOF'
type Widget {
    name: str,
    width: i32,
}

fn make_widget() -> Widget:
    Widget { name: "btn", width: 100 }

fn main:
    let w = make_widget()
    w.
EOF
req_slow='{"jsonrpc":"2.0","id":2,"method":"textDocument/completion","params":{"textDocument":{"uri":"file:///tmp/lsp_test.w"},"position":{"line":10,"character":6}}}'
out_slow=$(lsp_test /tmp/lsp_slow_type.w "$req_slow")
# Fast tier can't resolve make_widget() return type. Slow tier should.
# At minimum, extend methods (Widget.xxx) should appear from fast tier.
# If slow tier works, we get struct fields too.
check "slow type: name field" "$out_slow" '"label":"name"'
check "slow type: width field" "$out_slow" '"label":"width"'

echo ""

# ── Summary ─────────────────────────────────────────────────
echo "=== Results: $PASS passed, $FAIL failed ==="
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
