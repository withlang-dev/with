#!/bin/bash
# Memory watchdog: kills child process if RSS exceeds limit
# Usage: ./memlimit.sh <max_mb> <command...>
# Example: ./memlimit.sh 8192 with compile rt/darwin_aarch64.w -O2

MAX_MB=${1:?Usage: memlimit.sh <max_mb> <command...>}
shift

"$@" &
PID=$!

PEAK_MB=0
while kill -0 "$PID" 2>/dev/null; do
    RSS_KB=$(ps -o rss= -p "$PID" 2>/dev/null | tr -d ' ')
    if [ -z "$RSS_KB" ]; then
        break
    fi
    RSS_MB=$((RSS_KB / 1024))
    if [ "$RSS_MB" -gt "$PEAK_MB" ]; then
        PEAK_MB=$RSS_MB
    fi
    if [ "$RSS_MB" -gt "$MAX_MB" ]; then
        echo "WATCHDOG: PID $PID exceeded ${MAX_MB}MB (at ${RSS_MB}MB). Killing." >&2
        kill -9 "$PID" 2>/dev/null
        wait "$PID" 2>/dev/null
        echo "WATCHDOG: Peak RSS was ${PEAK_MB}MB" >&2
        exit 137
    fi
    sleep 0.5
done

wait "$PID"
EXIT=$?
echo "WATCHDOG: Process exited with code $EXIT. Peak RSS: ${PEAK_MB}MB" >&2
exit $EXIT
