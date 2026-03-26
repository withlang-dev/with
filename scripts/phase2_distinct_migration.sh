#!/bin/bash
# phase2_distinct_migration.sh — Migrate raw i32 IDs to distinct types.
#
# Usage:
#   ./scripts/phase2_distinct_migration.sh scan          # measure scope
#   ./scripts/phase2_distinct_migration.sh migrate FILE   # migrate one file
#   ./scripts/phase2_distinct_migration.sh verify         # build + fixpoint
#
# Strategy:
#   1. Run `scan` to see all sites
#   2. Run `migrate FILE` one file at a time, smallest first
#   3. Run `verify` after each file
#   4. Commit after each successful verify
#
# Migration order (smallest scope first):
#   1. src/Mir.w        — define the types, use BlockId in MirBody
#   2. src/MirLower.w   — BlockId in MirBuilder
#   3. src/AsyncMir.w   — BlockId references
#   4. src/Ast.w        — define NodeId, use in AstPool
#   5. src/Parser.w     — NodeId in parse functions
#   6. src/Sema.w       — NodeId + TypeId
#   7. src/Codegen.w    — NodeId + TypeId + BlockId
#   8. src/CCodegen.w   — same

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ─── SCAN ──────────────────────────────────────────────────────────────

scan() {
    echo "=== Phase 2: Distinct Type Migration Scope ==="
    echo ""

    echo "--- BlockId candidates (MIR basic block indices) ---"
    echo "Pattern: fn params named bb/cur_bb/target_bb/resume_bb etc."
    grep -rn '\bcur_bb\b\|_bb:\s*i32\|\bbb:\s*i32\|\bbb_id\b\|\bnew_bb\b\|\btarget_bb\b' \
        src/Mir.w src/MirLower.w src/AsyncMir.w src/Codegen.w src/CCodegen.w \
        2>/dev/null | wc -l
    echo ""

    echo "--- NodeId candidates (AST node indices) ---"
    echo "Pattern: fn params named node/expr/decl/stmt etc. typed i32"
    grep -rn '\bnode:\s*i32\|\bexpr:\s*i32\|\bdecl:\s*i32\|\bstmt:\s*i32\|\bfn_node\b\|\btype_node\b\|\blet_node\b' \
        src/Ast.w src/Parser.w src/Sema.w src/Codegen.w src/CCodegen.w src/MirLower.w \
        2>/dev/null | wc -l
    echo ""

    echo "--- TypeId candidates (sema type indices) ---"
    echo "Pattern: fn params named tid/type_id/sema_ty/ret_type etc."
    grep -rn '\btid:\s*i32\|\btype_id:\s*i32\|\bsema_ty\b\|\bret_type\b\|\bparam_type\b\|\bfield_tid\b\|\belem_ty\b.*i32' \
        src/Sema.w src/Codegen.w src/MirLower.w \
        2>/dev/null | wc -l
    echo ""

    echo "--- Detailed breakdown by file ---"
    for f in src/Mir.w src/MirLower.w src/AsyncMir.w src/Ast.w src/Parser.w src/Sema.w src/Codegen.w src/CCodegen.w; do
        if [ -f "$f" ]; then
            count=$(grep -c '\bcur_bb\b\|_bb:\s*i32\|\bbb:\s*i32\|\bnode:\s*i32\|\bexpr:\s*i32\|\bdecl:\s*i32\|\btid:\s*i32\|\btype_id:\s*i32\|\bsema_ty\b' "$f" 2>/dev/null || echo 0)
            printf "  %-30s %s sites\n" "$f" "$count"
        fi
    done
    echo ""

    echo "--- Boundary sites (need manual review: as i32 / as i64) ---"
    echo "Places where IDs are used as Vec indices, HashMap keys, or raw arithmetic:"
    grep -rn '\.get(\|\.push(\|\.set(\|\.insert(\|as i64\|as i32\|+ 1\|- 1\|+ 2' \
        src/Mir.w src/MirLower.w src/Sema.w src/Codegen.w \
        2>/dev/null | grep -i 'bb\|node\|tid\|type_id\|decl\|expr' | wc -l
    echo "(these need 'id as i64' or 'id as i32' wrappers)"
    echo ""
}

# ─── VERIFY ────────────────────────────────────────────────────────────

verify() {
    echo "=== Verifying Phase 2 changes ==="
    echo ""

    echo "Step 1: Build"
    if make build 2>&1 | tail -5; then
        echo -e "${GREEN}Build OK${NC}"
    else
        echo -e "${RED}Build FAILED${NC}"
        return 1
    fi
    echo ""

    echo "Step 2: Check"
    if ./out/bin/with-stage2 check src/main.w 2>&1; then
        echo -e "${GREEN}Check OK${NC}"
    else
        echo -e "${RED}Check FAILED${NC}"
        return 1
    fi
    echo ""

    echo "Step 3: Fixpoint"
    if make fixpoint 2>&1 | tail -3; then
        echo -e "${GREEN}Fixpoint OK${NC}"
    else
        echo -e "${RED}Fixpoint FAILED${NC}"
        return 1
    fi
    echo ""

    echo -e "${GREEN}All verification passed. Safe to commit.${NC}"
}

# ─── MAIN ──────────────────────────────────────────────────────────────

case "${1:-help}" in
    scan)
        scan
        ;;
    verify)
        verify
        ;;
    *)
        echo "Usage: $0 {scan|verify}"
        echo ""
        echo "  scan       — count all migration sites"
        echo "  verify     — build + check + fixpoint"
        echo ""
        echo "Workflow:"
        echo "  1. $0 scan"
        echo "  2. Manually migrate one file at a time"
        echo "  3. $0 verify"
        echo "  4. git commit"
        echo "  5. repeat for next file"
        ;;
esac
