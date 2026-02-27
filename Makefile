.PHONY: bootstrap stage1 stage2 test-bootstrap test-stage1 test-stage2 test clean

# Build bootstrap compiler (Zig -> bootstrap/zig-out/bin/with)
bootstrap:
	cd bootstrap && zig build

# Stage 1: bootstrap compiler builds self-hosted compiler
stage1: bootstrap
	./bootstrap/zig-out/bin/with build src/main.w
	cp .with/build/main ./with-stage1
	cp .with/build/main ./with

# Stage 2: stage1 compiler builds itself
stage2: stage1
	./with-stage1 build src/main.w -o .with/build/with-stage2
	cp .with/build/with-stage2 ./with-stage2

# Bootstrap compiler test run
test-bootstrap: bootstrap
	./bootstrap/zig-out/bin/with test test/cases/
	./bootstrap/zig-out/bin/with test bootstrap/test/cases/

# Stage1 compiler sanity check
test-stage1: stage1
	./with-stage1 check src/main.w

# Stage2 compiler sanity check
test-stage2: stage2
	./.with/build/with-stage2 version

# Full verification: bootstrap suites + stage2 self-host check
test: test-bootstrap test-stage2

clean:
	rm -f with with-stage1 with-stage2 with-stage3
	rm -rf .with/build/
	cd bootstrap && rm -rf zig-out .zig-cache
