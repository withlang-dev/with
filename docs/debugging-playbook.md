# 10. Debugging Playbook (Stage2 on macOS ARM64)

Use this when `with-stage2` is hanging, crashing, or showing suspicious memory behavior.

## 10.1 Quick triage (repro + timing)

```bash
time ./with-stage2 check src/main.w --dump-resolved
```

If this is unexpectedly slow, keep the exact command line and use it for all tools below.

## 10.2 Crash triage with LLDB

```bash
lldb -- ./with-stage2 check src/main.w --dump-resolved
# inside lldb:
run
bt all
thread list
```

For repeated crashes, set a breakpoint in likely hot paths (resolver, parser, allocator wrappers) and rerun.

## 10.3 Heap corruption checks (fast, native)

```bash
MallocScribble=1 MallocGuardEdges=1 ./with-stage2 check src/main.w --dump-resolved
```

Add stack logging when needed:

```bash
MallocScribble=1 MallocGuardEdges=1 MallocStackLogging=1 ./with-stage2 check src/main.w --dump-resolved
```

## 10.4 Leak checks

Single-run leak report:

```bash
leaks --atExit -- ./with-stage2 check src/main.w --dump-resolved
```

If attaching to a live process is needed:

```bash
./with-stage2 check src/main.w --dump-resolved &
leaks $(pgrep -n with-stage2)
```

## 10.5 Instruments (`xctrace`) for deeper memory analysis

Record a Leaks trace:

```bash
xcrun xctrace record --template "Leaks" --output /tmp/with-stage2-leaks.trace --launch -- ./with-stage2 check src/main.w --dump-resolved
```

Optional export for inspection/diffing:

```bash
xcrun xctrace export --input /tmp/with-stage2-leaks.trace --output /tmp/with-stage2-leaks.json --format json
```

## 10.6 macOS debugger permissions (required once per binary/update)

If you see `not debuggable` or `Unable to acquire required task port`, re-sign `with-stage2` with debug entitlement:

```bash
cat > /tmp/debug.entitlements <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.get-task-allow</key>
    <true/>
</dict>
</plist>
EOF

codesign -s - --entitlements /tmp/debug.entitlements --force ./with-stage2
codesign -d --entitlements :- ./with-stage2
```

Enable developer debugging access (machine/user setup):

```bash
sudo DevToolsSecurity -enable
sudo dseditgroup -o edit -a "$USER" -t user _developer
```

## 10.7 Tool policy for this repo on ARM64

* Prefer: `lldb`, `MallocScribble`/`MallocGuardEdges`, `leaks`, `xctrace`.
* Avoid by default: Valgrind on ARM64 (VEX backend limits make it fragile and very slow for this workload).
* If Valgrind is absolutely required, expect heavy slowdown and use only as a last resort.
