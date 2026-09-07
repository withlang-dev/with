# - conc.w: await_all(with_concurrency(build_tasks(1100), 1)) does NOT compile:
#   return-type mismatch at task.w:232-233 + no-matching-overload at call site.
#   Upgrades #981 (stub is unusable, not merely ignored).
# - hangres.w: Result-await_all over 1100 all-Ok tasks HANGS (60s timeout,
#   zero output). Second failure mode of #995 (commented).
