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

    [ -d "$raw_dir" ] || die "missing raw migration directory: $raw_dir"

    rm -rf "$generated_dir"
    mkdir -p "$generated_dir"

    # Copy non-excluded files from raw migration output.
    # defs.w, preamble stripping, shared-let hoisting, and var externization
    # are now handled by the compiler (C1 ownership + C3 --shared-defs).
    for src in "$raw_dir"/*.w; do
        [ -e "$src" ] || continue
        local base
        base="$(basename "$src")"
        if is_excluded "$base"; then
            continue
        fi
        cp "$src" "$generated_dir/$base"
    done

    # Remaining text rewrites (C4 scope — will move to compiler lowering).
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

    # Concatenate adjacent string literals: "foo" "bar" → "foobar"
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
        # defs.w contains the full preamble (C3); module starts with `use std.re.defs`
        # so skip that import line (line 2) and the comment (line 1) and concat directly.
        if [ -f "$generated_dir/defs.w" ]; then
            cat "$generated_dir/defs.w" > "$tf"
        else
            head -48 "$raw_dir/pcre2_tables.w" > "$tf"
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
