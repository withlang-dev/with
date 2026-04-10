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

is_excluded() {
    case "$1" in
        pcre2test.w|pcre2demo.w|pcre2grep.w|pcre2posix_test.w|\
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
    local clean_tmp="${TMPDIR:-/tmp}/pcre2_clean.$$"
    CLEANUP_FILES+=("$body_tmp" "$clean_tmp")

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
        # Forward-declare opaque PCRE2 internal struct types
        printf '\n// Opaque PCRE2 internal types (forward declarations)\n'
        printf '%s\n' 'type pcre2_real_general_context_8 = opaque'
        printf '%s\n' 'type pcre2_real_compile_context_8 = opaque'
        printf '%s\n' 'type pcre2_real_match_context_8 = opaque'
        printf '%s\n' 'type pcre2_real_convert_context_8 = opaque'
        printf '%s\n' 'type pcre2_real_code_8 = opaque'
        printf '%s\n' 'type pcre2_real_match_data_8 = opaque'
        printf '%s\n' 'type pcre2_real_jit_stack_8 = opaque'
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

    for dst in "$generated_dir"/*.w; do
        grep -v 'pcre2_.*_16\b\|pcre2_.*_32\b\|PCRE2_UCHAR16\|PCRE2_UCHAR32\|PCRE2_SPTR16\|PCRE2_SPTR32' "$dst" > "$clean_tmp" || true
        mv "$clean_tmp" "$dst"
        perl -0pi -e 's/\(\(0 as \*mut c_void\)\)/null/g' "$dst"
        # Expand XSTRING macros in pcre2_config (stringify version strings)
        if [ "$(basename "$dst")" = "pcre2_config.w" ]; then
            perl -pi -e 's/XSTRING\(PCRE2_MAJOR\.PCRE2_MINOR PCRE2_DATE\)/"10.48 2025-10-21"/g' "$dst"
            perl -pi -e 's/XSTRING\(PCRE2_MAJOR\.PCRE2_MINOR\) XSTRING\(PCRE2_PRERELEASE PCRE2_DATE\)/"10.48-DEV 2025-10-21"/g' "$dst"
            perl -pi -e 's/XSTRING\(PCRE2_MAJOR\.PCRE2_MINOR\)/"10.48"/g' "$dst"
            perl -pi -e 's/XSTRING\(PCRE2_PRERELEASE PCRE2_DATE\)/"-DEV 2025-10-21"/g' "$dst"
        fi
    done

    # Default context vars need extern (storage provided by pcre2_context_init.c)
    for dst in "$generated_dir"/*.w; do
        perl -pi -e 's/^var (_pcre2_default_\w+_context_8:)/extern var $1/' "$dst"
    done

    # Concatenate adjacent string literals: "foo" "bar" → "foobar"
    # Cast with_alloc to *mut c_void (returns *i8 but often assigned to void*)
    for dst in "$generated_dir"/*.w; do
        perl -pi -e 's/"([^"]*)" "([^"]*)"/"$1$2"/g' "$dst"
        perl -pi -e 's/(?<!fn )with_alloc\(([^)]+)\)/(with_alloc($1) as *mut c_void)/g' "$dst"
    done
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

    local tf
    tf="$(mktemp "${TMPDIR:-/tmp}/pcre2-check.XXXXXX.w")"
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
