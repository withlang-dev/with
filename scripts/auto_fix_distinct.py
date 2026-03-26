#!/usr/bin/env python3
"""Auto-fix distinct type migration errors.

Reads compiler error output, parses file:line:col and error type,
applies mechanical fixes:
- "return type mismatch" with "actual type: NodeId" → change fn return to NodeId
- "wrong argument type" with "expects NodeId, got i32" → wrap in NodeId(...)
- "wrong argument type" with "expects i32, got NodeId" → add as i32
- "type mismatch in assignment" → add as i32 or NodeId(...)
- "arithmetic operator requires numeric operands" → add as i32

Usage:
    python3 scripts/auto_fix_distinct.py <error_file> [--dry-run]

    # Generate errors:  make build 2>&1 > /tmp/errors.txt
    # Apply fixes:      python3 scripts/auto_fix_distinct.py /tmp/errors.txt
    # Rebuild and repeat until zero errors
"""
import re
import sys
from collections import defaultdict

def parse_errors(error_file):
    """Parse compiler error output into structured fixes."""
    fixes = []  # (file, line, col, fix_type, detail)

    with open(error_file) as f:
        lines = f.readlines()

    i = 0
    while i < len(lines):
        line = lines[i].strip()

        # Pattern: "error: return type mismatch"
        # Followed by: "src/File.w:LINE:COL"
        if line == 'error: return type mismatch':
            if i + 1 < len(lines):
                loc = lines[i + 1].strip()
                m = re.match(r'(src/\S+\.w):(\d+):(\d+)', loc)
                if m:
                    fixes.append((m.group(1), int(m.group(2)), int(m.group(3)), 'return_type', ''))

        # Pattern: "error: wrong argument type in call to 'XXX'"
        # Followed by location, then "actual type: NodeId" or similar
        if 'wrong argument type' in line:
            if i + 1 < len(lines):
                loc = lines[i + 1].strip()
                m = re.match(r'(src/\S+\.w):(\d+):(\d+)', loc)
                if m:
                    # Look for "expects i32" / "expects NodeId" in nearby lines
                    detail = ''
                    for j in range(i + 2, min(i + 8, len(lines))):
                        if 'expects i32' in lines[j] and 'actual type: NodeId' in lines[j]:
                            detail = 'nodeid_to_i32'
                        elif 'expects i32' in lines[j] and 'actual type: BlockId' in lines[j]:
                            detail = 'blockid_to_i32'
                        elif 'expects NodeId' in lines[j]:
                            detail = 'i32_to_nodeid'
                        elif 'actual type: NodeId' in lines[j]:
                            detail = 'nodeid_to_i32'
                        elif 'actual type: BlockId' in lines[j]:
                            detail = 'blockid_to_i32'
                    fixes.append((m.group(1), int(m.group(2)), int(m.group(3)), 'arg_type', detail))

        # Pattern: "error: type mismatch in assignment"
        if 'type mismatch in assignment' in line:
            if i + 1 < len(lines):
                loc = lines[i + 1].strip()
                m = re.match(r'(src/\S+\.w):(\d+):(\d+)', loc)
                if m:
                    fixes.append((m.group(1), int(m.group(2)), int(m.group(3)), 'assign', ''))

        # Pattern: "error: arithmetic operator requires numeric operands"
        if 'arithmetic operator requires numeric operands' in line:
            if i + 1 < len(lines):
                loc = lines[i + 1].strip()
                m = re.match(r'(src/\S+\.w):(\d+):(\d+)', loc)
                if m:
                    fixes.append((m.group(1), int(m.group(2)), int(m.group(3)), 'arithmetic', ''))

        # "struct type has no default display"
        if 'struct type has no default display' in line:
            if i + 1 < len(lines):
                loc = lines[i + 1].strip()
                m = re.match(r'(src/\S+\.w):(\d+):(\d+)', loc)
                if m:
                    fixes.append((m.group(1), int(m.group(2)), int(m.group(3)), 'display', ''))

        i += 1

    return fixes

def apply_return_type_fix(filepath, line_no, lines):
    """Change -> i32 to -> NodeId on the function declaration at or above line_no."""
    # Search upward for the function declaration
    for i in range(line_no - 1, max(line_no - 20, -1), -1):
        if '-> i32:' in lines[i] and ('fn ' in lines[i] or lines[i].strip().endswith('-> i32:')):
            lines[i] = lines[i].replace('-> i32:', '-> NodeId:')
            return True
    return False

def group_by_file(fixes):
    """Group fixes by file for batch processing."""
    by_file = defaultdict(list)
    for f in fixes:
        by_file[f[0]].append(f)
    return by_file

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 scripts/auto_fix_distinct.py <error_file> [--dry-run]")
        sys.exit(1)

    error_file = sys.argv[1]
    dry_run = '--dry-run' in sys.argv

    fixes = parse_errors(error_file)
    print(f"Parsed {len(fixes)} errors")

    # Count by type
    by_type = defaultdict(int)
    for f in fixes:
        by_type[f[3]] += 1
    for t, c in sorted(by_type.items(), key=lambda x: -x[1]):
        print(f"  {t}: {c}")

    if dry_run:
        for f in fixes:
            print(f"  {f[0]}:{f[1]}:{f[2]} -> {f[3]} {f[4]}")
        return

    # Apply return type fixes
    by_file = group_by_file(fixes)
    total_fixed = 0

    for filepath, file_fixes in by_file.items():
        with open(filepath) as f:
            lines = f.readlines()

        fixed = 0
        for _, line_no, col, fix_type, detail in sorted(file_fixes, key=lambda x: -x[1]):
            if fix_type == 'return_type':
                if apply_return_type_fix(filepath, line_no, lines):
                    fixed += 1

        if fixed > 0:
            with open(filepath, 'w') as f:
                f.writelines(lines)
            print(f"  {filepath}: {fixed} return type fixes")
            total_fixed += fixed

    print(f"Total: {total_fixed} fixes applied")
    print("Rebuild and run again to fix remaining errors")

if __name__ == '__main__':
    main()
