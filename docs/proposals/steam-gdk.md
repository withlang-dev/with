# The With Steam Game Development Kit

A proposal. It gathers three plans into one product and says what that
product is, for whom, and what it costs the compiler. The plans hold the
detail: `docs/plans/game-toolkit.md` (the `game` package and
`with init --type game`), `docs/plans/steam-dev.md` (the Deck loop) and
`docs/plans/incremental-compilation.md` (the rebuild). Where this document
and a plan disagree, the plan is more recent or more careful; fix this one.

## Summary

The Steam Game Development Kit (the GDK) is what a developer gets when they
choose With to write a game for Steam and the Steam Deck. It is one
toolchain, not a bundle: `with init --type game` creates a game that builds,
runs, saves, reads a controller and ships, and `with dev` takes that game
to a Deck on the desk, launches it where players run it, debugs it from the
developer's editor, shows its screen on the developer's machine, and reloads
it on save. The game's own code never contains `unsafe`, a stored reference,
or a platform `#if`.

Every claim below about what works was tried on a retail Steam Deck LCD
(SteamOS 3.8.28) from a Mac on 2026-10-18 and 10-19, with WIPE: SURVIVAL,
the With game that the kit is extracted from. The numbers are measured; the
unmeasured are named.

The pitch, in the words the kit should earn:

```text
with init my-game --type game --store steam
with dev pair                 # one tap on the Deck
with dev run deck             # on the Deck, in Game Mode, log in this terminal
with dev debug deck           # breakpoint in a .w file, from VS Code, Visual Studio or IDEA
with dev watch deck           # save a file, the Deck shows it
```

No engine ships this for a native language. Godot, Unity and Unreal have
pieces of it inside their editors; raylib, Bevy, Odin, Zig and Go have a
renderer or a template and leave the rest to the developer. Valve's own
devkit client pairs and uploads and stops there.

## Goals and non-goals

**Goals**

- A developer with a Deck and With, and nothing else installed, reaches a
  running game on the Deck in under a minute from `with init`, and keeps a
  build-run-see-fix loop under thirty seconds end to end.
- Everything the kit does is a `with` verb, so the same loop works from a
  terminal, VS Code, Visual Studio Professional and IntelliJ IDEA.
- The game is one build for every platform and store; the store SDK is
  inert without its client. A console is a slot that fails loudly until a
  private backend exists.
- The kit is honest: every step says what it did, every unsupported case
  is an error naming the fact, and no step produces a plausible wrong
  thing (mission rule 7).

**Non-goals**

- A renderer abstraction or an engine. Drawing is confined to one module
  the developer owns; a console port replaces that module.
- A hot reload that migrates live state across a changed layout. The kit
  reloads by restart and exact replay, which is correct by construction;
  in-process reload comes only if measurement asks for it.
- Transports Valve does not support. A direct USB-C link to the Deck is
  possible (the kernel has the gadget modules) but needs a BIOS switch and
  root; decided 2026-10-18, not this kit.
- Console backends in this proposal. Xbox, Switch and PlayStation come one
  at a time, after vendor access, each as its own plan.

## What exists, measured

| Piece | State on 2026-10-19 |
|---|---|
| The game plumbing (platform seam, Steam Input, achievements, atomic save, fixed-step clock, exact replay, packaging) | Built and shipped in WIPE: about 3,500 of its 11,000 lines; extraction into the `game` package is the toolkit plan's Milestone 1 |
| Pairing with a Deck | One tap on the Deck through Valve's Devkit Service (`POST :32000/register`, RSA keys only); no password, no Desktop Mode, no BIOS |
| Launching in Game Mode | From our own code over Steam's IPC pipe: `create-shortcut` answered in 0.5 s; launch 3.7 s the first time, **0.59 s** on relaunch |
| Building for the Deck | On the Deck: 66.8 s clean, 65.5 s after one edit. On the Mac (M5 Max): 20.4 s and 18.1 s. Cross-building from the Mac is blocked only by `c_import` under `--target`; Valve publishes the steamrt4 SDK sysroot (1.12 GB) with every library WIPE links |
| Debugging | DWARF on by default; at `-O0`, LLDB on the Mac through SteamOS's own `gdbserver` and an SSH forward stops at a `.w` line, prints locals and a backtrace. Nothing to install on the Deck |
| Seeing the screen | gamescope publishes its composited output as a PipeWire source; a 1080p screenshot in 0.48 s; live view at 60 fps as MJPEG (24 Mbit/s at 960×540) or hardware H.264 (10 Mbit/s at 1080p) |
| Replay | An 18-minute recording replays in 0.08 s |
| Editors | VS Code: `with-vscode` has language and grammar only. Visual Studio: Attach to Process over SSH with its GDB engine needs nothing from us but a working `with dev` on Windows. IDEA: a DAP run configuration through Red Hat's LSP4IJ, or CLion 2025.3's built-in DAP |
| The rebuild | Any edit rebuilds the whole executable. WIPE's 18 s: 52% Sema (every body checked twice, by design: D89/D93), 19% re-translating unchanged C headers, 20% LLVM, 1% link |

## Developer experience

A walk through the kit as a developer meets it. Each step names the verb,
what it shows, and what it refuses.

1. **Create.** `with init my-game --type game --template twin-stick
   --platforms pc,mac,linux,steam-deck --store steam --org com.example`.
   Prompts only for what the flags left out; `--yes` takes defaults. The
   project builds and its tests pass before the command returns, or it
   fails and says why. `with add steam --sdk steamworks_sdk_165.zip` later
   does the same for a project created without a store, because Valve's
   terms let us redistribute `libsteam_api` and nothing else.
2. **Pair.** `with dev pair`. Finds every Deck advertising
   `_steamos-devkit._tcp`; if none, says exactly where the Deck's toggle is
   (Settings → System → Developer Mode, then Developer → Pair new host).
   Prints "Approve the pairing on your Deck" and waits for the tap. A
   second run on a paired Deck is silent.
3. **Run.** `with dev run deck`. Builds (on the Mac once cross-building
   lands, on the Deck until then), syncs by content hash, registers or
   updates the Game Mode shortcut, launches, and streams the game's log
   into the terminal until it exits. Ctrl-C stops the game. Exit status is
   the game's.
4. **See.** `with dev screenshot deck` writes the frame players see, overlay
   included. `with dev view deck` opens a 60 fps window; in an editor, the
   same stream fills a panel.
5. **Debug.** `with dev debug deck` builds `-O0`, launches under
   `gdbserver`, forwards the port, and starts LLDB with the source map set,
   stopped before `main`. `--dap` prints the editor's attach configuration
   as JSON. `--attach` joins a running game. A crash without a debugger
   leaves a core that `with dev pull deck crash` opens locally.
6. **Reload.** `with dev watch deck`. A changed asset is pushed and swapped
   live. A changed source is rebuilt and the game relaunched into the same
   simulation step by replaying its own recording; the terminal says which
   tier ran. In-process code swap is a later tier, gated on measurement.
7. **Ship.** `with build :package` writes the allowlisted depot with the
   Steam library beside the executable and the Steam Input assets generated
   from the game's own action declaration. The release package cannot
   contain the dev channel; packaging refuses it.

What the developer never does: write `unsafe`, store a reference, edit a
`.vdf` by hand, enter a password, change a BIOS setting, install anything
on the Deck, or write an editor's debug configuration.

## Architecture

Five parts, each usable alone.

### The `game` package

Fetched with `with get game`, versioned with the compiler, run in the
battery. Modules in dependency order: `controls`, `platform`, `input`,
`keyboard`, `gamepads`, `steam`, `save`, `clock`, `record`, `window`,
`devices`, `audio`, `package`, and `dev` (the dev channel, excluded from
release builds). Each is cut from a named WIPE file with its tests. The
game keeps its action list, its save fields, its screens and every draw
call; the package keeps the mechanism.

Three pieces exist in no surveyed ecosystem and are the differentiators:
the fixed-step clock with exact replay; prompts named by the platform;
one build with the store SDK inert when the client is absent.

### The platform seam

`trait Platform` is the whole surface a store or console presents to the
game: overlay pause, achievement mirror, controller, prompts. Public
backends (`none`, `steam`) ship in the package. A console backend is a
private package implementing the same trait, distributed the MonoGame way
to the vendor-verified; the generated slot is a `comptime_error` until it
is installed.

### The device seam

`with dev` speaks to a device kind: `steam-deck`, `linux`, and console
slots. For the Deck it is Valve's pairing, then SSH and content-addressed
sync, then Steam's pipe for the Game Mode launch, then `gdbserver` and the
PipeWire screen. Long-running work (launch, build, timing) runs detached
on the device with its output in a file, because SSH sessions drop; the
tool reattaches. `with dev status` names what it sees: band and bit rate,
power saving, Game Mode or Desktop, and the one network state it cannot
fix, a router that knows the Deck while no packet reaches it (client
isolation; a `bore` tunnel gets through).

### The dev channel

A dev build opens one TCP port on the Deck's loopback, reached through the
SSH forward, carrying `log`, `step`, `pause`/`resume`/`step N`,
`snapshot`/`restore`, `record`, `reload asset`, and `screenshot`. It is
`game.dev`, a module the release build does not link.

### The editors

The CLI is the one implementation; an editor is a thin client with three
things: a way to run the verbs, a debugger speaking to the Deck's
`gdbserver`, and a panel for the screen.

| Editor | Run | Debug | Screen |
|---|---|---|---|
| VS Code | tasks over `with dev` | a `with` debug type on `lldb-dap` (LLVM 22.1.6, the compiler's own) attaching through the forward | webview on `with dev view --port` |
| Visual Studio Professional | `with dev` from the Developer PowerShell; a VSIX later for colouring | built in: Attach to Process over SSH, Native (GDB), driving the Deck's gdb 16.3; DWARF is what it reads | its own window |
| IntelliJ IDEA | run configurations over `with dev` | LSP4IJ's DAP configuration on `lldb-dap`, or CLion 2025.3's built-in DAP | a tool window on the MJPEG stream |

`with dev debug --dap` emits the configuration, so none is hand-written.
Visual Studio imposes the one hard requirement: `with dev` runs on Windows
without `rsync`.

## Language and compiler work

The kit is also the list of what it needs from With. Each item is an issue
to file, and each was found by trying, not by reasoning.

| Need | Why | Where it stands |
|---|---|---|
| `c_import` under `--target` | The one blocker for building the Deck's binary on the Mac; the link stage already takes a sysroot and the bundled `ld.lld` | `src/CImport.w:754` refuses; the steamrt4 sysroot is published by Valve |
| Target-keyed C dependencies and a fetched sysroot | Conan selection uses the host; `.with/deps/c/` has no target key; the sysroot is an environment variable | Not started |
| Facade coverage for Steamworks | Rule 10: no `unsafe` in a game. 22 sites in WIPE's binding; all but the callback pump map onto facade clauses that exist | Pump waits on withlang-dev/with#2425; the `steam_api.json` facade generator is the toolkit plan's §3.2.1 |
| Incremental compilation | Every edit costs a full rebuild; the Deck loop is the build and nothing else | Three measured stages in `docs/plans/incremental-compilation.md`: stop repeating work (the `c_import` disk cache for several imports, confining the D89/D93 second Sema pass, `-O0` for dev), reuse per codegen unit, re-analyze only what an edit affects |
| Debug-info type graphs | Lines and locals work; `Handle[T]`, `List[T]`, `Option` and `Result` need DI types and LLDB formatters to read usefully | Found while debugging WIPE on the Deck |
| Shared-library output and a loader facade | Only for in-process reload (tier 3), and only if tier 2's measured loop is too slow | Not scheduled |

## Risks

- **Steam's devkit protocol is undocumented.** Everything the kit does
  with the pipe was read from Valve's open-source client and verified on
  one SteamOS version. A client update can change it. Mitigation: the
  protocol lives in one module with a conformance test against a real
  Deck in the UAT, and `with dev` reports Steam's own error text.
- **Networks.** Wi-Fi throughput varied from 0.8 to 3.7 MB/s on one
  network, and a second network isolated clients entirely. The kit cannot
  fix either; it can name them and keep pushes content-addressed.
- **The rebuild.** At 18 s on a fast Mac and 65 s on the Deck, the loop is
  the build. Stage 1 of the incremental plan removes up to 8.8 s of
  repeated work for WIPE; the rest is real compiler work.
- **Editors.** Visual Studio and IDEA are described from their
  documentation, not yet from a test. Milestone 2 of the Deck plan runs
  both and records what does not work.
- **Scope.** The kit is three plans; the order below keeps each step
  shippable on its own.

## Roadmap

1. **The loop, as it is.** `with dev pair`, `run`, `logs`, `screenshot`,
   `view`, `shell`, `unpair` for the Deck and plain Linux, building on the
   Deck. WIPE runs on the Deck from a Mac terminal. The fake device
   (a Linux container) in the battery. Alongside: Stage 1 of incremental
   compilation, starting with the `c_import` cache.
2. **Debug and see from the editors.** `with dev debug`, `--dap`, crash
   pull; the VS Code debug type, tasks and screen panel; the Visual Studio
   and IDEA tests with results recorded.
3. **The package.** `lib/game/` extracted from WIPE; WIPE depends on it
   and passes its battery with no toolkit code left in `src/`.
4. **Cross-building.** `c_import` under `--target`, target-keyed
   dependencies, the fetched sysroot; the default builder moves to the
   developer's machine.
5. **Reload.** `game.dev`, `with dev watch`, asset reload and
   restart-and-replay, with the loop's cost measured and written down.
6. **The template and the command.** `with init --type game`, `with add
   platform` and `with add steam` with the facade generator; the `basic`
   and `twin-stick` templates in the battery for every platform and store
   combination.
7. **The Deck, end to end.** A generated project on a Deck under Steam
   Input, achievements mirrored, overlay pausing, sleep and resume
   surviving; the Deck Verified checklist reflecting what was verified.

After this: console backends, one at a time; in-process reload if
measurement asks; mobile last.

## Open questions

1. `with dev <verb>` or `with run --device`, and `with add` as a verb or a
   flag of `init` (both plans, both open).
2. Where device addresses live: the kind in `with.toml`, the address in
   the user's config, is the proposal.
3. Whether the dev channel belongs to the toolkit or the compiler (a
   general `with run --remote`).
4. Recording always on in dev builds: memory and disk over a long session.
5. The name. "GDK" collides with nothing of Valve's (theirs is the
   Steamworks SDK) but with Microsoft's Game Development Kit; the kit may
   want its own word.

## References

- `docs/plans/game-toolkit.md`, `docs/plans/steam-dev.md`,
  `docs/plans/incremental-compilation.md`: the plans this proposal gathers,
  with every measurement, source and decision date.
- WIPE: SURVIVAL (withlang-dev/wipe), `docs/steam-and-steam-deck-support.md`.
- Valve: SteamOS Devkit Client and Service (open source), Steamworks
  partner documentation, Steam Linux Runtime 4 images.
