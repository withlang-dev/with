# With Language — Implementation Roadmap

- Language: D22 uniform keyed-map views + transparent origins + contextual Copy
  (**accepted 2026-07-23; implementation in progress;
  `docs/d22-Eric-Ruling.md` is canonical, and
  `docs/d22-implementation-plan.md` is the conforming execution plan**)

- App: Crux
- App: Weld (depends on Crux)
- App: Smallhold
- Migrate: Zlib
- Migrate: jq
- Migrate: SQLite
- Migrate: minicoro
- Feature: harden async engine (depends on minicoro)
- Feature: From Query Expressions (depends on JQ + SQLite)
