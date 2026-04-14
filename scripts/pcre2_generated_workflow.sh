#!/bin/bash

set -euo pipefail

CLEANUP_FILES=()
cleanup() { rm -f "${CLEANUP_FILES[@]+"${CLEANUP_FILES[@]}"}"; }
trap cleanup EXIT

die() {
    echo "error: $*" >&2
    exit 1
}

usage() {
    cat >&2 <<'EOF'
usage:
  pcre2_generated_workflow.sh prepare <raw-dir> <generated-dir>
  pcre2_generated_workflow.sh check <with-bin> <raw-dir> <generated-dir>
  pcre2_generated_workflow.sh promote <with-bin> <raw-dir> <generated-dir> <dest-dir>
EOF
    exit 1
}

externize_shared_vars_except_owner() {
    local generated_dir="$1"
    local owner_file="$2"
    local pattern="$3"
    local dst

    for dst in "$generated_dir"/*.w; do
        [ "$(basename "$dst")" = "$owner_file" ] && continue
        perl -pi -e 's/^var ('"$pattern"': [^=]+?) = .*$/extern var $1/; s/^var ('"$pattern"': )/extern var $1/' "$dst"
    done
}

hoist_shared_lets_to_defs() {
    local generated_dir="$1"
    python3 - "$generated_dir" <<'PY'
from __future__ import annotations

import collections
import re
import sys
from pathlib import Path

generated_dir = Path(sys.argv[1])
defs_path = generated_dir / "defs.w"
module_paths = sorted(path for path in generated_dir.glob("*.w") if path.name != "defs.w")
decl_pattern = re.compile(r"^let\s+[A-Za-z_][A-Za-z0-9_]*(?:\s*:|\s*=)")

occurrences: collections.OrderedDict[str, list[Path]] = collections.OrderedDict()
for module_path in module_paths:
    for line in module_path.read_text().splitlines():
        if decl_pattern.match(line):
            occurrences.setdefault(line, []).append(module_path)

duplicate_lines = [line for line, owners in occurrences.items() if len(owners) >= 2]
if not duplicate_lines:
    raise SystemExit(0)

defs_lines = defs_path.read_text().splitlines()
defs_seen = set(defs_lines)
if defs_lines and defs_lines[-1] != "":
    defs_lines.append("")
for line in duplicate_lines:
    if line not in defs_seen:
        defs_lines.append(line)
        defs_seen.add(line)
defs_path.write_text("\n".join(defs_lines) + "\n")

duplicate_set = set(duplicate_lines)
for module_path in module_paths:
    kept_lines = []
    for line in module_path.read_text().splitlines():
        if decl_pattern.match(line) and line in duplicate_set:
            continue
        kept_lines.append(line)
    module_path.write_text("\n".join(kept_lines) + "\n")
PY
}

prune_width_family_decls() {
    local generated_dir="$1"
    python3 - "$generated_dir" <<'PY'
from __future__ import annotations

import re
import sys
from pathlib import Path

generated_dir = Path(sys.argv[1])
decl_pattern = re.compile(r"^(?:extern fn|fn|extern var|var|extern let|let|type)\b")
attr_pattern = re.compile(r"^@\[[^]]+\]$")
width_token_pattern = re.compile(
    r"\b(?:PCRE2_UCHAR16|PCRE2_UCHAR32|PCRE2_SPTR16|PCRE2_SPTR32|[A-Za-z_][A-Za-z0-9_]*_(?:16|32))\b"
)


def is_top_level(line: str) -> bool:
    return len(line) == 0 or line[0] not in " \t"


def is_decl_start(line: str) -> bool:
    return is_top_level(line) and decl_pattern.match(line) is not None


def is_attr_line(line: str) -> bool:
    return is_top_level(line) and attr_pattern.match(line) is not None


def next_decl_boundary(lines: list[str], start: int, is_fn_block: bool) -> int:
    if not is_fn_block:
        return start + 1
    i = start + 1
    while i < len(lines):
        line = lines[i]
        if len(line) > 0 and line[0] in " \t":
            i += 1
            continue
        if line == "":
            i += 1
            continue
        break
    return i


for module_path in sorted(generated_dir.glob("*.w")):
    lines = module_path.read_text().splitlines()
    kept: list[str] = []
    i = 0
    while i < len(lines):
        if is_attr_line(lines[i]):
            attrs: list[str] = []
            while i < len(lines) and is_attr_line(lines[i]):
                attrs.append(lines[i])
                i += 1
            if i < len(lines) and is_decl_start(lines[i]):
                header = lines[i]
                end = next_decl_boundary(lines, i, header.startswith("fn "))
                if width_token_pattern.search(header) is None:
                    kept.extend(attrs)
                    kept.extend(lines[i:end])
                i = end
                continue
            kept.extend(attrs)
            continue

        if is_decl_start(lines[i]):
            header = lines[i]
            end = next_decl_boundary(lines, i, header.startswith("fn "))
            if width_token_pattern.search(header) is None:
                kept.extend(lines[i:end])
            i = end
            continue

        kept.append(lines[i])
        i += 1

    module_path.write_text("\n".join(kept) + ("\n" if len(kept) > 0 else ""))
PY
}

is_excluded() {
    case "$1" in
        pcre2test.w|pcre2demo.w|pcre2grep.w|pcre2posix.w|pcre2posix_test.w|\
        pcre2_jit_test.w|pcre2_jit_compile.w|pcre2_dftables.w|\
        pcre2_fuzzsupport.w)
            return 0
            ;;
    esac
    return 1
}

prepare_generated_tree() {
    local raw_dir="$1"
    local generated_dir="$2"
    local body_tmp="${TMPDIR:-/tmp}/pcre2_body.$$"
    CLEANUP_FILES+=("$body_tmp")

    [ -d "$raw_dir" ] || die "missing raw migration directory: $raw_dir"

    rm -rf "$generated_dir"
    mkdir -p "$generated_dir"

    for src in "$raw_dir"/*.w; do
        [ -e "$src" ] || continue
        local base
        base="$(basename "$src")"
        if is_excluded "$base"; then
            continue
        fi
        cp "$src" "$generated_dir/$base"
    done

    local preamble_start
    preamble_start="$(grep -n -m1 'type BOOL\|type PCRE2_UCHAR8' "$generated_dir/pcre2_tables.w" | cut -d: -f1)"
    [ -n "$preamble_start" ] || die "could not find PCRE2 preamble start in $generated_dir/pcre2_tables.w"
    local preamble_end=$((preamble_start - 1))
    {
        printf '%s\n' '// std.re.defs — shared type aliases for migrated PCRE2'
        sed -n "2,${preamble_end}p" "$generated_dir/pcre2_tables.w"
        # Note: pcre2_real_*_8 struct types are defined in their respective
        # modules (pcre2_context.w, pcre2_compile.w, etc.), NOT as opaque
        # forward declarations here. Opaque decls prevent field access.
        # Cross-module extern declarations
        printf '\n// Cross-module extern symbols (only those not emitted by migrator)\n'
        # STRING_* constants from pcre2_internal.h
        printf '\n// PCRE2 string constants (from pcre2_internal.h macros)\n'
        printf '%s\n' 'let STRING_MARK: *const u8 = "MARK"'
        printf '%s\n' 'let STRING_DEFINE: *const u8 = "DEFINE"'
        printf '%s\n' 'let STRING_VERSION: *const u8 = "VERSION"'
        printf '%s\n' 'let STRING_WEIRD_STARTWORD: *const u8 = "[:<:]]"'
        printf '%s\n' 'let STRING_WEIRD_ENDWORD: *const u8 = "[:>:]]"'
        # Helper function for strchr mapping
        printf '\n// strchr mapping (migrator emits string_find_char for strchr)\n'
        printf '%s\n' 'fn string_find_char(s: *const i8, c: i32) -> *const i8: (memchr((s as *const c_void), c, strlen(s)) as *const i8)'
    } > "$generated_dir/defs.w"

    local dst line
    for dst in "$generated_dir"/*.w; do
        [ "$(basename "$dst")" = "defs.w" ] && continue
        line="$(grep -n -m1 'type BOOL\|type PCRE2_UCHAR8' "$dst" 2>/dev/null | cut -d: -f1 || true)"
        [ -n "$line" ] || continue
        tail -n +"$line" "$dst" > "$body_tmp"
        {
            printf '%s\n' '// Migrated from PCRE2'
            printf '%s\n\n' 'use std.re.defs'
            cat "$body_tmp"
        } > "$dst"
    done

    prune_width_family_decls "$generated_dir"

    for dst in "$generated_dir"/*.w; do
        perl -0pi -e 's/\(\(0 as \*mut c_void\)\)/null/g' "$dst"
        # Expand XSTRING macros in pcre2_config (stringify version strings)
        if [ "$(basename "$dst")" = "pcre2_config.w" ]; then
            perl -pi -e 's/XSTRING\(PCRE2_MAJOR\.PCRE2_MINOR PCRE2_DATE\)/"10.48 2025-10-21"/g' "$dst"
            perl -pi -e 's/XSTRING\(PCRE2_MAJOR\.PCRE2_MINOR\) XSTRING\(PCRE2_PRERELEASE PCRE2_DATE\)/"10.48-DEV 2025-10-21"/g' "$dst"
            perl -pi -e 's/XSTRING\(PCRE2_MAJOR\.PCRE2_MINOR\)/"10.48"/g' "$dst"
            perl -pi -e 's/XSTRING\(PCRE2_PRERELEASE PCRE2_DATE\)/"-DEV 2025-10-21"/g' "$dst"
        fi
    done

    # Keep migrated initializers intact. The raw migrate step must succeed
    # semantically; prepare should not silently delete owners or data.
    for dst in "$generated_dir"/*.w; do
        # Array dimension assigned to array var in goto body
        # These are re-declarations of hoisted array vars where the migrator
        # emitted the dimension as an assignment value
        perl -pi -e 's/^(\s+)(temp|null_str|stack_groupinfo|stack_parsed_pattern|named_groups|backref_cache) = \[?\d+\]?$/$1\/\/ $2 re-declared (skipped)/' "$dst"
    done

    # Default context vars keep their var definitions (storage from With code).
    # The pcre2_context_init.c workaround is no longer needed since #100/#101.

    # The migrator re-emits PCRE2 header globals into every translation unit.
    # Keep one real definition per shared symbol and make all other modules
    # reference it with extern var.
    externize_shared_vars_except_owner \
        "$generated_dir" \
        "pcre2_tables.w" \
        '_pcre2_(?!posix_class_maps8)\w+'
    externize_shared_vars_except_owner \
        "$generated_dir" \
        "pcre2_compile.w" \
        '_pcre2_posix_class_maps8'

    # Concatenate adjacent string literals: "foo" "bar" → "foobar"
    # The `with_alloc(X) → (with_alloc(X) as *mut c_void)` rewrite
    # used to live here but is now emitted inline by
    # ci_map_libc_call — the perl regex was paren-unaware and
    # corrupted arg texts with nested parens.
    for dst in "$generated_dir"/*.w; do
        perl -pi -e 's/"([^"]*)" "([^"]*)"/"$1$2"/g' "$dst"
    done

    # -1 in unsigned assignment context (PCRE2_UNSET = ~(size_t)0 = ULONG_MAX)
    # Only replace (-1) when preceded by = (assignment/binding), not in match arms
    for dst in "$generated_dir"/*.w; do
        perl -pi -e 's/= \(-1\b/= ((0 -% 1)/g' "$dst"
        perl -pi -e 's/else: \(-1\b/else: ((0 -% 1)/g' "$dst"
    done

    # Fix pointer-typed p used as integer index in pcre2_compile's recurse_cache binary search
    if [ -f "$generated_dir/pcre2_compile.w" ]; then
        perl -pi -e 's/recurse_cache\)\[p\]/recurse_cache)[(p as c_int)]/g' "$generated_dir/pcre2_compile.w"
        # Adjacent string-literal macros: `STR_Q STR_BACKSLASH STR_E` should
        # concatenate after preprocessing, but the migrator emits them as
        # bare identifiers. Replace the one occurrence with the literal.
        perl -pi -e 's/\(\(&STR_Q STR_BACKSLASH STR_E\[0\] as \*mut c_char\) as \*const i8\)/("Q\\\\E" as *const i8)/g' "$generated_dir/pcre2_compile.w"
    fi

    hoist_shared_lets_to_defs "$generated_dir"
}

count_generated_errors() {
    local with_bin="$1"
    local raw_dir="$2"
    local generated_dir="$3"
    local total=0
    local ok=0

    [ -x "$with_bin" ] || die "missing compiler binary: $with_bin"
    [ -d "$raw_dir" ] || die "missing raw migration directory: $raw_dir"
    [ -d "$generated_dir" ] || die "missing generated directory: $generated_dir"

    local tf_base tf
    tf_base="$(mktemp "${TMPDIR:-/tmp}/pcre2-check.XXXXXX")"
    tf="${tf_base}.w"
    mv "$tf_base" "$tf"
    CLEANUP_FILES+=("$tf")

    local mod errs size
    for mod in $(ls "$generated_dir"/*.w | sed "s|$generated_dir/||;s|\.w||" | sort); do
        [ "$mod" = "defs" ] && continue
        head -48 "$raw_dir/pcre2_tables.w" > "$tf"
        # Append shared defs (opaque types, extern symbols)
        if [ -f "$generated_dir/defs.w" ]; then
            tail -n +2 "$generated_dir/defs.w" >> "$tf"
        fi
        tail -n +3 "$generated_dir/$mod.w" >> "$tf"
        printf '\nfn main: print("ok")\n' >> "$tf"
        errs="$("$with_bin" check "$tf" 2>&1 | grep -c 'error:' || true)"
        if [ "$errs" -eq 0 ]; then
            ok=$((ok + 1))
        else
            size="$(wc -c < "$generated_dir/$mod.w")"
            printf '%s %s %s\n' "$mod" "$errs" "$size"
            total=$((total + errs))
        fi
    done

    printf 'OK=%s TOTAL_ERRORS=%s\n' "$ok" "$total"
}

promote_generated_tree() {
    local with_bin="$1"
    local raw_dir="$2"
    local generated_dir="$3"
    local dest_dir="$4"
    local summary total

    summary="$(count_generated_errors "$with_bin" "$raw_dir" "$generated_dir")"
    printf '%s\n' "$summary"
    total="$(printf '%s\n' "$summary" | awk -F'TOTAL_ERRORS=' '/TOTAL_ERRORS=/{print $2}' | tail -1)"
    [ -n "$total" ] || die "failed to compute generated error count"
    if [ "$total" -ne 0 ]; then
        die "refusing to promote generated PCRE2 with $total remaining errors"
    fi

    mkdir -p "$dest_dir"
    rm -f "$dest_dir"/*.w
    local src
    for src in "$generated_dir"/*.w; do
        [ -e "$src" ] || continue
        cp "$src" "$dest_dir/"
    done
    echo "promoted $(ls "$generated_dir"/*.w | wc -l | tr -d ' ') generated modules into $dest_dir"
}

main() {
    local cmd="${1:-}"
    case "$cmd" in
        prepare)
            [ "$#" -eq 3 ] || usage
            prepare_generated_tree "$2" "$3"
            ;;
        check)
            [ "$#" -eq 4 ] || usage
            count_generated_errors "$2" "$3" "$4"
            ;;
        promote)
            [ "$#" -eq 5 ] || usage
            promote_generated_tree "$2" "$3" "$4" "$5"
            ;;
        *)
            usage
            ;;
    esac
}

main "$@"
