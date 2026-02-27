#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "running phase3 milestone 138 groups: 25.8, 25.15, 25.16, 25.22, 25.97, 25.98..."

bash bootstrap/test/run_phase3_additional_collections_tests.sh
bash bootstrap/test/run_phase3_collection_combinator_tests.sh
bash bootstrap/test/run_phase3_generator_readiness_tests.sh
bash bootstrap/test/run_phase3_option_combinator_tests.sh
bash bootstrap/test/run_phase3_result_combinator_tests.sh
bash bootstrap/test/run_phase3_raw_ptr_as_option_tests.sh
bash bootstrap/test/run_phase3_hashmap_convenience_tests.sh

echo "phase3 milestone 138 tests: PASS"
