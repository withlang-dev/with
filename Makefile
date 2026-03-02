.PHONY: bootstrap stage1 stage2 gate-stage0 test-bootstrap test-stage1 test-stage2 test clean

# Build bootstrap compiler (Zig -> bootstrap/zig-out/bin/with)
bootstrap:
	cd bootstrap && zig build

# Stage 1: bootstrap compiler builds self-hosted compiler
stage1: bootstrap
	./scripts/rebuild_selfhost.sh stage1

# Stage 2: stage1 compiler builds itself
stage2: bootstrap
	./scripts/rebuild_selfhost.sh stage2

# Stage 0 bootstrap contract gate (safe subset + expected fails)
gate-stage0: bootstrap
	./scripts/gate_stage0_subset.sh

# Bootstrap compiler test run
test-bootstrap: bootstrap
	./bootstrap/zig-out/bin/with test test/cases/
	./bootstrap/zig-out/bin/with test bootstrap/test/cases/

# Stage1 compiler sanity check
test-stage1: stage1
	./with-stage1 check src/main.w

# Stage2 compiler sanity check
test-stage2: stage2
	cp ./with-stage2 /tmp/with-stage2-check
	chmod +x /tmp/with-stage2-check
	/tmp/with-stage2-check version
	rm -f /tmp/with-stage2-check

# Full verification: bootstrap suites + stage2 self-host check
test: test-bootstrap test-stage2

clean:
	rm -f with with-stage1 with-stage2 with-stage3
	rm -rf .with/build/
	cd bootstrap && rm -rf zig-out .zig-cache
