#!/usr/bin/env python3
"""Step 2: Fix Parser.w — all parse functions return NodeId.

Pattern: fn Parser.parse_X(...) -> i32 that returns pool.add_node()
Fix: change -> i32 to -> NodeId, and add 'as i32' where NodeId is
used as a non-node value (comparisons with 0, stored in data fields).
"""
import re

def patch_parser():
    with open('src/Parser.w', 'r') as f:
        content = f.read()

    # Pattern 1: Parse functions that return nodes -> change to -> NodeId
    # These are: parse_*, desugar_*, build_*, parse_format_spec_text
    # But NOT: expect, expect_ident, intern_current, peek, advance,
    # current_start, current_end, compound_assign_op, infix_op,
    # scan_is_paren_closure, parse_param_attrs, parse_type_bound_symbol
    #
    # The safe approach: change ALL "fn Parser.X(...) -> i32:" to -> NodeId
    # EXCEPT functions that return non-node values.

    non_node_fns = {
        'expect', 'expect_ident', 'expect_ident_or_keyword',
        'expect_use_path_segment', 'intern_current',
        'peek', 'advance', 'current_start', 'current_end',
        'prev_start', 'prev_end', 'peek_past_newlines',
        'compound_assign_op', 'infix_op',
        'scan_is_paren_closure', 'parse_param_attrs',
        'parse_type_bound_symbol', 'parse_type_params',
        'parse_one_type_param', 'parse_param_list',
        'parse_one_param',
    }

    lines = content.split('\n')
    new_lines = []
    for line in lines:
        m = re.match(r'^fn Parser\.(\w+)\(.*\) -> i32:', line)
        if m and m.group(1) not in non_node_fns:
            line = line.replace(') -> i32:', ') -> NodeId:')
        new_lines.append(line)
    content = '\n'.join(new_lines)

    # Pattern 2: "return 0" in node-returning functions -> "return NodeId(0)"
    # This is tricky because some "return 0" are in non-node functions.
    # But since we changed the return type, the compiler will catch mismatches.
    # Let's fix the obvious ones:
    # - "return 0" at end of parse functions (after emit_error)
    # - bare "0" as tail expression in parse functions
    # These are already handled by poisoned_expr() for some,
    # but many still return raw 0.

    # Pattern 3: Variables that hold nodes need NodeId type
    # "let node = self.pool.add_node(...)" — node is now NodeId
    # "let decl = self.parse_decl()" — decl is now NodeId
    # These work automatically because type inference picks up NodeId.
    # But explicit "var x: i32 = 0" for node variables need fixing.
    # Let's not fix these yet — Script 3 will handle remaining errors.

    with open('src/Parser.w', 'w') as f:
        f.write(content)
    print("Patched src/Parser.w")


def patch_ast_remaining():
    """Fix remaining Ast.w issues — internal functions that return nodes."""
    with open('src/Ast.w', 'r') as f:
        content = f.read()

    # render functions and dump functions that take nodes
    # These are in Sema.w actually, not Ast.w. Skip for now.

    with open('src/Ast.w', 'w') as f:
        f.write(content)


def patch_other_files():
    """Fix functions in other files that accept/return nodes."""
    # render.w: render_decl, render_expr take node: i32 -> node: NodeId
    # Resolve.w: resolve_decl_name takes node
    # Frontend.w: various
    # These will be caught by Script 3 after Parser is fixed.

    for fname in ['src/render.w', 'src/Resolve.w', 'src/Sema.w',
                  'src/Codegen.w', 'src/CodegenDispatch.w',
                  'src/CodegenTraits.w', 'src/MirLower.w',
                  'src/compiler/Frontend.w', 'src/compiler/Backend.w',
                  'src/main.w', 'src/main_emit_temp.w']:
        try:
            with open(fname, 'r') as f:
                content = f.read()
            # No changes yet — let compile errors guide Script 3
            with open(fname, 'w') as f:
                f.write(content)
        except FileNotFoundError:
            pass


if __name__ == '__main__':
    patch_parser()
    print("Done. Run 'make build' to see remaining errors.")
