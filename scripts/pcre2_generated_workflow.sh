#!/bin/bash
# pcre2_generated_workflow.sh — check and promote migrated PCRE2 modules.
#
# Make targets own the lifecycle:
#   regex-migrate: with migrate -> out/pcre2_migrated
#   regex-build: copy/check/build -> out/pcre2_build
#   regex-promote: copy checked output -> lib/std/re

set -euo pipefail

CLEANUP_FILES=()
cleanup() { rm -f "${CLEANUP_FILES[@]+"${CLEANUP_FILES[@]}"}"; }
trap cleanup EXIT

CHECK_TIMEOUT_SECS="${PCRE2_CHECK_TIMEOUT_SECS:-180}"

die() {
    echo "error: $*" >&2
    exit 1
}

run_capture_with_timeout() {
    local timeout_secs="$1"
    local out_file="$2"
    shift 2

    if [ "$timeout_secs" -le 0 ]; then
        "$@" >"$out_file" 2>&1
        return $?
    fi

    local marker child watchdog rc
    marker="$(mktemp "${TMPDIR:-/tmp}/pcre2-check-timeout.XXXXXX")"
    rm -f "$marker"
    CLEANUP_FILES+=("$marker")

    "$@" >"$out_file" 2>&1 &
    child="$!"
    (
        sleep "$timeout_secs" &
        sleep_pid="$!"
        trap 'kill "$sleep_pid" 2>/dev/null || true; wait "$sleep_pid" 2>/dev/null || true; exit 0' TERM INT
        wait "$sleep_pid" 2>/dev/null || exit 0
        if kill -0 "$child" 2>/dev/null; then
            touch "$marker"
            kill -TERM "$child" 2>/dev/null || true
            sleep 2
            kill -KILL "$child" 2>/dev/null || true
        fi
    ) >/dev/null 2>&1 &
    watchdog="$!"

    wait "$child"
    rc="$?"
    kill "$watchdog" 2>/dev/null || true
    wait "$watchdog" 2>/dev/null || true

    if [ -f "$marker" ]; then
        return 124
    fi
    return "$rc"
}

ensure_generated_dependencies() {
    local generated_dir="$1"
    local compile_w="$generated_dir/pcre2_compile.w"
    if [ -f "$compile_w" ] && ! grep -Fq 'use std.re.pcre2_auto_possess' "$compile_w"; then
        local tmp
        tmp="$(mktemp "${TMPDIR:-/tmp}/pcre2-compile-imports.XXXXXX")"
        CLEANUP_FILES+=("$tmp")
        awk '
            NR == 2 && $0 == "use std.re.defs" {
                print
                print "use std.re.pcre2_auto_possess"
                print "use std.re.pcre2_chkdint"
                print "use std.re.pcre2_compile_cgroup"
                print "use std.re.pcre2_compile_class"
                print "use std.re.pcre2_find_bracket"
                print "use std.re.pcre2_newline"
                print "use std.re.pcre2_ord2utf"
                print "use std.re.pcre2_string_utils"
                print "use std.re.pcre2_study"
                print "use std.re.pcre2_valid_utf"
                next
            }
            { print }
        ' "$compile_w" > "$tmp"
        mv "$tmp" "$compile_w"
    fi

    local auto_possess_w="$generated_dir/pcre2_auto_possess.w"
    if [ -f "$auto_possess_w" ] && ! grep -Fq 'use std.re.pcre2_xclass' "$auto_possess_w"; then
        local auto_tmp
        auto_tmp="$(mktemp "${TMPDIR:-/tmp}/pcre2-auto-possess-imports.XXXXXX")"
        CLEANUP_FILES+=("$auto_tmp")
        awk '
            NR == 2 && $0 == "use std.re.defs" {
                print
                print "use std.re.pcre2_xclass"
                next
            }
            { print }
        ' "$auto_possess_w" > "$auto_tmp"
        mv "$auto_tmp" "$auto_possess_w"
    fi
}

module_defines_main() {
    grep -Eq '^[[:space:]]*fn[[:space:]]+main([[:space:]]|[(:{]|->|$)' "$1"
}

usage() {
    cat >&2 <<'EOF'
usage:
  pcre2_generated_workflow.sh check <with-bin> <generated-dir>
  pcre2_generated_workflow.sh promote <with-bin> <generated-dir> <dest-dir>
EOF
    exit 1
}

count_generated_errors() {
    local with_bin="$1"
    local generated_dir="$2"
    local total=0
    local ok=0

    [ -x "$with_bin" ] || die "missing compiler binary: $with_bin"
    [ -d "$generated_dir" ] || die "missing generated directory: $generated_dir"
    ensure_generated_dependencies "$generated_dir"

    local tf_base tf
    tf_base="$(mktemp "${TMPDIR:-/tmp}/pcre2-check.XXXXXX")"
    tf="${tf_base}.w"
    mv "$tf_base" "$tf"
    CLEANUP_FILES+=("$tf")

    local mod errs size check_out check_rc
    for mod in $(ls "$generated_dir"/*.w | sed "s|$generated_dir/||;s|\.w||" | sort); do
        [ "$mod" = "defs" ] && continue
        # defs.w contains the full preamble. For this synthetic single-file
        # check, strip module imports from the checked module body; otherwise
        # dependency imports pull std.re.defs back in and shadow the inlined
        # definitions. The promoted files keep their imports unchanged.
        [ -f "$generated_dir/defs.w" ] || die "missing generated defs.w in $generated_dir"
        cat "$generated_dir/defs.w" > "$tf"
        awk 'NR <= 2 { next } /^use std\.re\./ { next } { print }' "$generated_dir/$mod.w" >> "$tf"
        if ! module_defines_main "$generated_dir/$mod.w"; then
            printf '\nfn main { print("ok") }\n' >> "$tf"
        fi
        check_out="$(mktemp "${TMPDIR:-/tmp}/pcre2-check-output.XXXXXX")"
        CLEANUP_FILES+=("$check_out")
        set +e
        run_capture_with_timeout "$CHECK_TIMEOUT_SECS" "$check_out" "$with_bin" check "$tf"
        check_rc="$?"
        set -e
        if [ "$check_rc" -eq 124 ]; then
            die "generated module check timed out after ${CHECK_TIMEOUT_SECS}s: $mod"
        fi
        errs="$(grep -c 'error:' "$check_out" || true)"
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
    local generated_dir="$2"
    local dest_dir="$3"
    local summary total

    summary="$(count_generated_errors "$with_bin" "$generated_dir")"
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
            [ "$#" -eq 3 ] || usage
            count_generated_errors "$2" "$3"
            ;;
        promote)
            [ "$#" -eq 4 ] || usage
            promote_generated_tree "$2" "$3" "$4"
            ;;
        *)
            usage
            ;;
    esac
}

main "$@"
