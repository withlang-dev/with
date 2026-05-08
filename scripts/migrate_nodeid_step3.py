#!/usr/bin/env python3
"""Step 3: Fix remaining errors across all files.

Patterns to fix:
1. 'return 0' in NodeId-returning functions → 'return NodeId(0)'
2. 'var x = 0' / 'var x: i32 = 0' where x holds nodes → NodeId init
3. Extra data push/get: nodes stored in extra pool as i32
4. Functions in other files that take node params
"""
import re
import subprocess
import sys

def get_errors():
    """Run make build and capture errors with file:line context."""
    result = subprocess.run(['make', 'build'], capture_output=True, text=True, timeout=300)
    output = result.stdout + result.stderr
    return output

def fix_parser_returns():
    """In Parser.w, fix 'return 0' and tail '0' in NodeId-returning fns."""
    with open('src/Parser.w', 'r') as f:
        lines = f.readlines()

    # Find all NodeId-returning functions
    in_nodeid_fn = False
    indent_level = 0
    new_lines = []

    for i, line in enumerate(lines):
        stripped = line.rstrip()

        # Detect NodeId-returning function
        if re.match(r'^fn Parser\.\w+\(.*\) -> NodeId:', stripped):
            in_nodeid_fn = True
            indent_level = 0
        elif re.match(r'^fn ', stripped) or re.match(r'^type ', stripped) or re.match(r'^enum ', stripped):
            in_nodeid_fn = False

        if in_nodeid_fn:
            # Fix "return 0" → "return NodeId(0)"
            if re.match(r'^(\s+)return 0\s*$', stripped):
                line = line.replace('return 0', 'return NodeId(0)')

            # Fix bare "0" as tail expression (last line before next fn)
            # Check if this line is just "    0" at function body indent
            if re.match(r'^    0\s*$', stripped):
                line = line.replace('    0', '    NodeId(0)')

            # Fix "return -1" etc — these are NOT node IDs
            # (find_fn_meta returns -1 as error, but that returns i32 not NodeId)
            # Skip these.

        new_lines.append(line)

    with open('src/Parser.w', 'w') as f:
        f.writelines(new_lines)
    print("Fixed Parser.w return types")


def fix_parser_node_vars():
    """Fix var/let declarations that hold nodes but initialize with 0."""
    with open('src/Parser.w', 'r') as f:
        content = f.read()

    # Common pattern: "var else_body = 0" where else_body is passed to add_node
    # These need: "var else_body: NodeId = NodeId(0)"
    # But we can't know all of them. Let's fix the known ones.

    # Pattern: "var X = 0" followed by "X = self.parse_..." or "X = self.pool.add_node"
    # These are node variables.
    node_vars = [
        'else_body', 'ret_type', 'label', 'body', 'default_value',
        'if_cond', 'then_body', 'else_branch', 'result',
    ]
    for var in node_vars:
        content = content.replace(
            f'var {var} = 0',
            f'var {var} = NodeId(0)'
        )

    # Fix comparison: "if node == 0" → "if (node as i32) == 0"
    # But only when node is a NodeId. Common pattern in Parser.w:
    # "if body == 0:" where body comes from parse_block_or_expr()
    # Since parse_block_or_expr now returns NodeId, body is NodeId.

    # Actually, the compiler should handle this. Let's not do bulk
    # replacement — it would break non-node comparisons.

    with open('src/Parser.w', 'w') as f:
        f.write(content)
    print("Fixed Parser.w node variables")


def fix_parser_add_extra():
    """Fix add_extra calls that push NodeId into i32 pool."""
    with open('src/Parser.w', 'r') as f:
        content = f.read()

    # Pattern: self.pool.add_extra(some_node)
    # where some_node is now NodeId but add_extra takes i32
    # Fix: self.pool.add_extra(some_node as i32)
    # But some add_extra calls push non-node values (counts, symbols).
    # We can't blindly convert all of them.

    # Let's not touch these — they'll be in the manual fix phase.

    with open('src/Parser.w', 'w') as f:
        f.write(content)


def fix_parser_comparisons():
    """Fix NodeId == 0 comparisons."""
    with open('src/Parser.w', 'r') as f:
        content = f.read()

    # Known node variables compared to 0:
    # "if node == 0:" "if body == 0:" "if lhs == 0:" etc.
    # These need: "if (node as i32) == 0:"

    # Common patterns that need fixing:
    patterns = [
        ('if name == 0:', 'if name == 0:'),  # name is a SYMBOL (i32), not a node — skip
        ('if body == 0:', 'if (body as i32) == 0:'),
        ('if lhs == 0:', 'if (lhs as i32) == 0:'),
        ('if node == 0:', 'if (node as i32) == 0:'),
        ('if node != 0:', 'if (node as i32) != 0:'),
        ('if decl == 0:', 'if (decl as i32) == 0:'),
        ('if decl != 0:', 'if (decl as i32) != 0:'),
        ('if arr == 0:', 'if (arr as i32) == 0:'),
        ('if result == 0:', 'if (result as i32) == 0:'),
    ]
    for old, new in patterns:
        content = content.replace(old, new)

    with open('src/Parser.w', 'w') as f:
        f.write(content)
    print("Fixed Parser.w comparisons")


if __name__ == '__main__':
    fix_parser_returns()
    fix_parser_node_vars()
    fix_parser_comparisons()
    print("Done. Run 'make build' to see remaining errors.")
