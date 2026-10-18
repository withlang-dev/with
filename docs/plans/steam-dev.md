# Steam Dev: Deploy, Run, Debug and Reload on a Steam Deck

## Scope

One command loop takes a game from the developer's machine to a Steam Deck
on the desk and back:

```text
with dev pair deck                 # once: keys, tools, a name for the device
with dev run deck                  # build for the Deck, push, launch in Game Mode, stream its output
with dev debug deck                # the same, stopped at main under LLDB on the developer's machine
with dev watch deck                # edit, save, and the running game picks up the change
```

The link is a USB-C cable, a USB-C Ethernet adapter, or the local network;
the commands do not change with it. This is the development loop around the
game toolkit (`docs/plans/game-toolkit.md`), the part that Milestone 4 of
that plan ("the Deck, end to end") needs every day and that no native
language ships. Valve's SteamOS Devkit Client covers pairing and upload for
engines that integrate it; it has no notion of a With build, a With
recording or a With debugger session.

The shape is a device seam, like the toolkit's `Platform` seam: the Deck is
the first backend, a desktop Linux machine over SSH comes free with it, and
console devkits are slots that fail loudly until a vendor backend exists.

Eric asked for this on 2026-10-18. This is a plan, not a specification.
Paths are relative to the `with` repository unless they name WIPE.

## 1. What exists and what doesn't

### 1.1 In With today

| Need | State | Where |
|---|---|---|
| Source-level debug info | DWARF lines (Phase 1) and local and parameter variables (#1348) | `docs/completed/debug.md`, `test/behavior/behav_debug_info_variables.w` |
| Build for `linux_x86_64` from a Mac | **Not possible for a game.** `BuildTarget.linux_x86_64` exists, but `c_import` refuses to run under `--target` (it would parse the host's headers), Conan selection uses the host OS, and no Linux sysroot ships. `with build :cross` fails loudly. | `src/CImport.w`, `docs/spec/toolchain/with-build.md` §Cross-Platform Targets; WIPE `docs/steam-and-steam-deck-support.md` §8 |
| A Linux build that runs on the Deck | Proven by WIPE: built **on the Deck** with the Deck's own With install, `libsteam_api.so` beside the executable with an `$ORIGIN` rpath. This is the only deployment path used so far. | WIPE `build.w`, `docs/steam-and-steam-deck-support.md` §8 |
| Shared-library output and a loader | None | — |
| Hot reload | None. `docs/proposals/with-ui.md` proposes state-as-snapshot reload for UI; nothing is built. | — |
| Deterministic recording and exact replay | Proven in WIPE; becomes `game.record` | WIPE `src/record.w` |
| An editor integration | `with-vscode`, `with lsp` | `with-vscode/` |

### 1.2 On the Deck

- SteamOS is x86_64 Linux with a read-only root. Anything the toolchain
  installs lives under the `deck` user's home; nothing needs the root
  filesystem unlocked.
- SSH is off by default. Turning it on needs a password for `deck` and
  Desktop Mode once. Valve's Devkit Client does the same through its own
  service; this plan uses plain SSH so it works on a retail Deck without
  that service (community reports say the service's setup script refuses
  non-Manjaro hosts on a retail Deck; unverified here).
- Game Mode runs games under gamescope. A game launched over SSH into
  Desktop Mode is not the environment players get: Steam Input, the
  overlay and the 1280×800 gamescope output only exist in Game Mode. The
  launch path must therefore go through Steam (a non-Steam shortcut, or the
  app ID when Steamworks is set up), not `ssh deck ./game`.
- The USB-C port is a host port by default. A BIOS setting, *USB Dual Role
  Device* (Advanced → USB Configuration → DRD), lets it act as a USB
  device; community projects use it for HID gadgets. **Whether a CDC-NCM
  network gadget works from SteamOS to macOS is unverified** and is
  Milestone 0's spike.

### 1.3 What other toolchains do

| Toolchain | Deploy | Debug | Reload |
|---|---|---|---|
| SteamOS Devkit Client | Pair by mDNS + SSH key, rsync upload, register in Game Mode | Not a debugger | No |
| Godot DeployToSteamOS | Rides the Devkit Client's keys | No | No |
| Unreal / Unity | Their own device managers | Native remote debuggers | Live Coding (Unreal), domain reload (Unity) |
| Odin / Handmade Hero pattern | — | — | Game as a shared library, host keeps memory, `dlopen` on change |
| Xbox / PlayStation / Switch devkits | Vendor tool: pair, push, launch | Vendor debugger over the devkit link | Vendor-specific |

The consoles all present the same four verbs: pair, deploy, launch,
attach. That is the seam.

## 2. Design rules

1. **The transport is SSH; the cable is a detail.** Every verb is SSH,
   `rsync` over SSH, or a port forwarded through SSH. USB is a way to get
   an IP link (§3.4), never a second protocol. Nothing listens on the
   Deck's network unauthenticated.
2. **Run where players run.** `with dev run` launches through Steam in Game
   Mode. Desktop Mode is a flag (`--desktop`) for when gamescope is the
   suspect, and it says so in its output.
3. **The same binary.** What `with dev run` pushes is what `with build`
   packages: the allowlist of `game.package`, the Steam library beside the
   executable, the same rpath. A dev build differs only in debug info and
   the dev channel (§5), both stated in the build's output.
4. **No root, no residue.** The toolchain's files on the Deck live in
   `~/.local/share/with-dev/`. `with dev unpair` removes them and the
   Game Mode shortcut it made, and lists anything it could not remove.
5. **Fail loudly at the first wrong fact.** No device, wrong architecture,
   SSH off, Game Mode not running, a build that is not Linux x86_64: each
   is an error naming the fact and the fix, before anything is copied.
6. **Reload is correct or it is a restart.** A reload that keeps state
   whose layout changed is a plausible wrong thing (mission rule 7). Every
   reload path says which kind it did, and the fallback is always a clean
   restart.
7. **No `unsafe` in a game, still.** Toolkit rule 10 holds: the dev channel,
   the reload host and the device code live in the toolchain and the
   `game` package behind facades. A capability that needs `unsafe` in the
   developer's code is a compiler issue to file.
8. **Devices are typed.** `deck`, `linux`, and console slots are a closed
   enumeration; a device entry in `with.toml` names its kind. A console
   kind fails with `comptime_error`-style diagnostics until its private
   backend is installed, as in the toolkit's §4.2.

## 3. The command surface

### 3.1 Devices are project facts

```toml
# with.toml
[devices.deck]
kind = "steam-deck"
host = "steamdeck.local"     # or an address; written by `with dev pair`
user = "deck"
```

The key lives in `~/.config/with/dev/` on the developer's machine, never
in the project. A device named on the command line that is not in
`with.toml` is looked up in the user's paired devices.

### 3.2 The verbs

| Command | Does |
|---|---|
| `with dev pair <name> [--host H]` | Finds the Deck (mDNS, or `--host`), checks it is SteamOS on x86_64, installs an SSH key (asks for the `deck` password once), installs `lldb-server` and the dev agent into `~/.local/share/with-dev/`, records the device. Idempotent. |
| `with dev status <name>` | Reachable? Game Mode or Desktop? Free space, battery, the installed tool versions, the last build pushed. |
| `with dev deploy <name>` | Builds the Linux package (§4), `rsync`s it by content hash into `~/.local/share/with-dev/games/<project>/`, creates or updates the Game Mode shortcut. Prints bytes sent. |
| `with dev run <name> [-- args]` | `deploy`, then launches through Steam, then streams stdout, stderr and the game's log to the terminal until the game exits; Ctrl-C stops the game, not just the stream. Exit status is the game's. |
| `with dev debug <name>` | `run` with the game started under `lldb-server`, stopped before `main`; starts LLDB here connected through an SSH port forward, with the source map and symbols set (§6). `--attach` attaches to the running game instead. |
| `with dev watch <name>` | `run`, then watches sources and assets; on save, reloads by the strongest correct tier (§7) and prints which one it used. |
| `with dev logs <name>` | Re-attaches the stream to a running game. |
| `with dev shell <name>` | SSH into the device in the game's directory. |
| `with dev pull <name> <what>` | Copies back saves, recordings, crash dumps, screenshots. `with dev pull deck recording` is how a Deck-only bug becomes a desktop replay. |
| `with dev unpair <name>` | Rule 4. |

`with dev` is a new top-level verb beside `run` and `test`. Whether it
should instead be `with run --device deck` is open question 1; the verbs
`pair`, `debug`, `watch`, `pull` have no home in `run`, which argues for
the verb.

### 3.3 The Game Mode launch

The shortcut runs a launcher script the toolchain owns
(`~/.local/share/with-dev/launch.sh <project>`). Steam starts the script
inside gamescope with Steam Input and the overlay; the script reads a
per-launch file the developer's side wrote (arguments, whether to start
under `lldb-server`, the dev channel port) and `exec`s the game. The
shortcut never changes between runs, so Steam's controller configuration
for it persists.

How the toolchain creates the shortcut and asks Steam to launch it, from
SSH, without the Devkit Service, is Milestone 0's second spike. The
candidates, in order of preference: the `steam://` URL handler invoked in
the Game Mode session; the Devkit Service's helper scripts where present;
writing `shortcuts.vdf` with Steam closed (the fallback, and it restarts
Steam, which the command must say). If no candidate works on a retail
Deck, `with dev run` requires the Devkit Service and says so at `pair`.

### 3.4 The link

| Link | How | State |
|---|---|---|
| Wi-Fi / LAN | mDNS `steamdeck.local` | Works today |
| USB-C Ethernet adapter or dock, cable to the Mac | Link-local IPv6 / mDNS on the direct link | Works with standard hardware; to verify end to end |
| USB-C cable, Deck as a USB network device | BIOS DRD on; a CDC-NCM gadget configured through configfs by `with dev pair --usb` (needs `sudo` once); macOS's built-in CDC-NCM driver on the other side | **Unverified.** Milestone 0, spike 1. If it fails, "over USB" means the adapter row, and the plan says so. |

All three appear to the toolchain as an address. `with dev status` names
which link it is on and its measured throughput, because a 2 GB asset
push over Wi-Fi is a different afternoon.

## 4. Building for the Deck

`with dev deploy` needs a Linux x86_64 package. Today With cannot produce
one from a Mac for a game that `c_import`s raylib and SDL (§1.1), but the
Deck can build it itself. The plan uses the Deck and files cross-building.

### 4.1 Now: build on the Deck

Eric's Deck already has With installed and builds WIPE there; that has been
the only deployment path so far. So the default builder is the device
itself, and the tool's job is to automate what is done by hand today.

`[devices.deck]` takes `build = "<builder>"`, one of:

- **`device`** (default): `rsync` the project's sources and assets (not
  `out/` or `.with/`) to `~/.local/share/with-dev/src/<project>/`, run
  `with build` there over SSH, and run the result in place. Nothing built
  is copied, so there is no deploy step separate from the build. `pair`
  checks the Deck's `with version` against the developer's and warns on a
  mismatch; `with dev pair --update-compiler` installs the matching one
  under `~`. The Deck's `.with/deps` and build cache stay between builds.
- **`container`**: the Steam Linux Runtime 4 SDK image (`steamrt4`) on the
  developer's machine, then push. On Apple Silicon this runs under x86_64
  emulation; its build time is unmeasured. Worth having when the Deck is
  slower than the emulated container, or for CI.
- **`ssh:<host>`**: any Linux x86_64 machine, then push.

Every builder runs `with build` on a synced copy, so `build.w` is the same
program everywhere. Eric has said cross-building and building on the Deck
are equally acceptable (2026-10-18); the device builder is first because it
works today.

Two consequences of building on the device:

- **Debug paths.** The DWARF names Deck paths. §6's source map maps
  `~/.local/share/with-dev/src/<project>` back to the local checkout, and
  the unstripped executable is pulled back once per debug session (or LLDB
  reads it remotely through `lldb-server platform`).
- **Reload speed.** Tier 2 of §7 costs a Deck build. Milestone 0 measures a
  one-file-change rebuild of WIPE on the Deck; that number decides whether
  `watch` should prefer the container.

### 4.2 The real road: cross-building

The compiler work, filed as issues, not done in this plan:

1. `c_import` under `--target` reads a target sysroot's headers
   (`--sysroot`, or the SDK's) instead of refusing.
2. Conan dependency selection takes the target, and `.with/deps/c/` gains
   a target key.
3. A Linux x86_64 sysroot is a fetchable artifact (extracted from
   `steamrt4`), named in `with.toml`, not an environment variable.
4. The link step uses `ld.lld` with that sysroot, so no Linux `cc` is
   needed on a Mac.

When these land, `build = "cross"` is available, and becomes the default
only if Milestone 0's numbers show it beats building on the Deck. Each is a With gap this toolkit found; that is the
point of building it.

## 5. The dev channel

A dev build of a toolkit game opens one TCP port on the Deck's loopback
only, reached through the SSH forward. It carries a small framed protocol
owned by `game.dev`:

| Message | Use |
|---|---|
| `log` (game → host) | Structured log lines, so `with dev run` does not depend on Steam capturing stdout |
| `step` (game → host) | The simulation step and frame time, for `with dev status` and the watch HUD |
| `pause` / `resume` / `step N` | Freeze the fixed-step clock, advance exactly N steps |
| `snapshot` / `restore` | Tier 2 of §7 |
| `record start` / `stop` / `pull` | Recordings without touching the game's menus |
| `reload asset <path>` | Tier 1 of §7 |
| `screenshot` | The frame as the player sees it, gamescope included |

A release build does not contain `game.dev`: the module is excluded by the
build, not disabled by a flag, and the packaging step refuses a release
package that links it.

## 6. Debugging

- **The server**: `lldb-server` for Linux x86_64 from the LLVM release the
  compiler already uses, installed by `pair` into the device directory. One
  LLVM version on both ends.
- **The session**: `with dev debug` forwards the server's port over SSH,
  then runs LLDB here with `platform select remote-linux`, the executable
  with its DWARF, and `settings set target.source-map <builder path>
  <project path>` so a container or remote build still shows local files.
- **Symbols**: the dev package is stripped for the push; the unstripped
  executable stays on the developer's machine and LLDB loads it by build
  ID. The push stays small and the debugger has everything.
- **The editor**: `with-vscode` gains a launch configuration that calls
  `with dev debug --dap`, which serves `lldb-dap` instead of the LLDB REPL.
  Breakpoints set in the editor survive a `watch` restart (§7, tier 3).
- **What With must provide**: Phase 1 debug info covers lines and locals.
  Struct and enum type graphs, `Option`/`Result` and slice pretty-printing
  are not built. Inspecting a `Handle[T]` or a `Vec[T]` usefully needs
  them, and LLDB data formatters shipped with the toolchain. Each missing
  piece found while debugging WIPE on the Deck is an issue.
- **Crashes without a debugger**: the launcher enables core dumps into the
  device directory; `with dev pull deck crash` brings the core and LLDB
  opens it against the local symbols.

## 7. Hot reload

Three tiers, strongest correct one first. `watch` decides per change and
prints its decision.

### Tier 1: assets (always correct)

A changed file under the package's asset allowlist is pushed, then
`reload asset <path>` tells `game.audio` and the texture loader to replace
it. A game opts a loader in by giving it a reload hook; an asset with no
hook falls to tier 3.

### Tier 2: code, by restart and replay (correct by construction)

The toolkit already has what makes this sound: a fixed-step simulation and
exact replay. On a code change:

1. The running game records continuously in dev builds (`game.record`).
2. The new build is pushed and launched.
3. The new process replays the old process's recording headless to the
   same step, then hands control to the pad.

If the change did not touch the simulation, the replay lands in the same
state and the developer sees their edit at the moment they left. If it did,
the replay runs the new rules over the same inputs, which is the honest
answer to "what would have happened". The state is never copied across a
layout change, so rule 6 holds without schema migration. `snapshot` /
`restore` shortens long sessions when the snapshot's type hash matches;
otherwise replay from the start, and say so.

Costs to measure in Milestone 3, none known now: build time on the chosen
builder; Steam relaunch time in Game Mode; replay speed for a ten-minute
session.

### Tier 3: code, in process (later, and only if tier 2 is too slow)

The Handmade Hero shape: a host executable owns the window, devices and
memory; the game is a shared library loaded with `dlopen` and replaced on
change, keeping the process, the Steam session and the debugger attached.
It needs With to:

1. Emit a shared library with a stated, versioned entry ABI.
2. Load one through a facade, so the host has no `unsafe` (rule 7).
3. Refuse a reload whose state types' layouts differ, by a type hash the
   compiler emits, falling to tier 2.

None of this exists. It is listed so the plan does not pretend tier 2 is
the ceiling, and it is not scheduled until tier 2's measured loop is too
slow to use.

## 8. Milestones

### Milestone 0: spikes, answered on a real Deck

1. USB network gadget (§3.4): does a CDC-NCM gadget from SteamOS with DRD
   enabled come up on macOS, and at what throughput? Record the answer and
   the commands.
2. Launching from SSH (§3.3): which candidate creates a shortcut and
   starts it in Game Mode on a retail Deck without the Devkit Service?
3. `lldb-server` from the compiler's LLVM release runs from `~` on SteamOS
   and LLDB on a Mac attaches to a WIPE Linux build through an SSH forward,
   with source lines.
4. Build time for WIPE on the Deck: clean, and after a one-file change.
   The same in the `steamrt4` container on Apple Silicon, for comparison.

Each answer is written into this plan before Milestone 1 begins; a "no"
changes the plan, not the code.

### Milestone 1: deploy and run

1. `with dev pair`, `status`, `deploy`, `run`, `logs`, `shell`, `unpair`
   for `kind = "steam-deck"` and `kind = "linux"`.
2. The `device` builder; then `container` and `ssh:`.
3. WIPE runs on the Deck in Game Mode from `with dev run deck` on a Mac,
   with its output in the Mac's terminal.
4. Tests: a fake device (a Linux container with SSH) in the battery, so
   every verb runs without hardware; the Deck acceptance is a UAT.

### Milestone 2: debug

1. `with dev debug`, `--attach`, crash pull, the source map.
2. The `with-vscode` launch configuration over `lldb-dap`.
3. WIPE: a breakpoint in `src/game.w` hit on the Deck, a local variable
   printed, a step over, from the Mac. Every value LLDB cannot show
   usefully is filed.

### Milestone 3: the dev channel and reload tiers 1 and 2

1. `game.dev` in the `game` package, excluded from release packages.
2. `with dev watch` with asset reload and restart-and-replay.
3. The three costs of §7 tier 2, measured on WIPE and written here.

### Milestone 4: cross-building

The four issues of §4.2, when the compiler takes them up. The plan's
acceptance does not wait on them; the default builder changes when they
land.

### After this plan

Tier 3 reload, if Milestone 3's numbers ask for it. Console device kinds,
each a private backend implementing the same four verbs.

## 9. Acceptance

- On a Mac with a paired retail Deck, `with dev run deck` in a project
  generated by `with init --type game` builds, pushes and launches the game
  in Game Mode with Steam Input, and its log appears in the Mac's terminal.
- `with dev debug deck` stops at `main`; a breakpoint set in the editor on
  a line of `src/` is hit on the Deck and shows locals.
- Under `with dev watch deck`, saving a texture changes it in the running
  game without a restart; saving a source file brings the game back at the
  same simulation step it left, and the terminal says which tier ran.
- `with dev pull deck recording` followed by a desktop replay reproduces
  the Deck session exactly.
- `with dev unpair deck` leaves nothing of the toolchain on the Deck.
- A release package built by the same project contains no `game.dev`.
- Every verb runs in the battery against the fake device.

## 10. Open questions

1. `with dev <verb>` or `with run --device` plus separate verbs.
2. Require Valve's Devkit Service (its pairing, its launch path), or keep
   plain SSH as the baseline. Depends on Milestone 0, spike 2.
3. Whether `[devices]` belongs in `with.toml` (shared with the team) or
   only in the user's config (addresses are personal). The proposal keeps
   the kind in the project and the address in the user's config.
4. Recording always on in dev builds: memory and disk on a long session.
5. Whether the dev channel should be the toolkit's or the compiler's (a
   general `with run --remote` for any program).

## 11. Advice that does not apply

| Advice | Why not |
|---|---|
| "Launch over SSH into Desktop Mode, it's simpler." | Not where players run (rule 2): no Steam Input layout, no overlay, no gamescope. Available as `--desktop`, labeled. |
| "Copy the state across a reload and hope the layout matches." | Rule 6. Restart-and-replay is correct by construction because the toolkit has exact replay. |
| "Run `gdbserver` from the SteamOS repositories." | The root is read-only and the package manager is off by default; `lldb-server` from the compiler's own LLVM installs under `~` and matches the LLDB on the other end. |
| "Expose a debug port on the network for convenience." | Rule 1. Everything rides the SSH connection the developer authenticated. |

## 12. References

- `docs/plans/game-toolkit.md`: the `game` package, `game.record`,
  `game.package`, the `Platform` seam this plan's device seam mirrors.
- WIPE: SURVIVAL `docs/steam-and-steam-deck-support.md` §8 (the Linux build)
  and §9 (the Verified checklist).
- Valve, SteamOS Devkit Client and Service (open source, GitLab); Steamworks
  partner docs, "Loading and running games on Steam Deck".
- DeckJoy (Lucaber/deckjoy): DRD mode used for a USB gadget.
- Godot DeployToSteamOS: a third-party deploy riding the Devkit Client.
