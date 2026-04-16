#!/bin/bash
# pcre2_generated_workflow.sh — check and promote migrated PCRE2 modules.
#
# The prepare step (raw → generated) is now a simple copy handled by the
# Makefile. This script provides check (compilation error counting) and
# promote (copy to lib/std/re after zero-error gate).

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
  pcre2_generated_workflow.sh check <with-bin> <raw-dir> <generated-dir>
  pcre2_generated_workflow.sh promote <with-bin> <raw-dir> <generated-dir> <dest-dir>
EOF
    exit 1
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
        # so skip the import header (lines 1-2) and concat directly after defs.
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
