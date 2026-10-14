# The Game Toolkit: `with init --type game`

## Scope

One command creates a game that builds, runs and ships on PC, Mac, Linux
and the Steam Deck:

```text
with init my-game --type game --template twin-stick --platforms pc,mac,linux,steam-deck --store steam
```

The project it writes has a title screen, settings, pause and results; a
save that survives restarts; controllers that speak the game's actions
with prompts named by the platform; Steam Input, achievements and the
overlay pause when the Steam client is running; a fixed-step simulation
with recording and replay; packaging; and a test suite that passes at
birth. It is the plumbing around a game, the part every game needs and no
native language ships. The game itself is the developer's.

Underneath the template is a library, `game`, fetched with `with get`.
Both ship inside the compiler, versioned with it, and run in the battery.

Consoles are in scope as a *shape*, not a promise: the `Platform` seam has
a slot per console that fails loudly until a backend package exists. The
backends are built one at a time, the hard way, after this plan: Xbox,
Switch, PlayStation 5, in whatever order partnership allows. Mobile comes
after that. Nothing in this plan precludes either; nothing in it pretends
to deliver them.

Everything here was first built and shipped in WIPE: SURVIVAL
(withlang-dev/wipe), a With + raylib + SDL3 twin-stick game that runs on
the Deck under Steam Input. Milestone 1 extracts it from there; WIPE then
depends on the package and must still pass its battery. That is the proof
the API is real.

Eric decided the direction on 2026-10-13. This is a plan, not a
specification. Paths in the `with` repository are relative to its root;
paths in WIPE are relative to that repository.

## 1. What exists and what doesn't

### 1.1 The survey

No native-language ecosystem ships the plumbing layer. Each has a renderer
or an engine, a scaffold at best, and third-party pieces for the rest.

| Ecosystem | Scaffold | Input as actions | Store | Save/settings | Consoles |
|---|---|---|---|---|---|
| raylib (C) | `raylib-game-template`: logo, title, options, gameplay, ending; a screen manager | No | No | No | No |
| Rust / Bevy | `bevy_quickstart` via `cargo generate` | Third party (`leafwing-input-manager`) | Third party, lags the engine | No | None official |
| Zig / Mach, raylib-zig | A shell script | No | No | No | No |
| Odin | A hot-reload template | No | No | No | No |
| Go / Ebitengine | Community jam template | No | A guide and a partial binding | No | Switch and Xbox, NDA-gated, via build tags |
| C# / MonoGame | `dotnet new mg*` | No | Community | No | Private repos per vendor, after vendor verification |
| Godot | None; `res://` and `ui_*` actions | Built in (`InputMap`) | Community (GodotSteam) | No | Licensed middleware (W4) |

Three observations drive the design:

1. **Actions-not-buttons is the one feature with consensus** (Godot,
   Unity's Input System, Unreal's Enhanced Input, Bevy's standard crate)
   and nobody native-first ships it in the box.
2. **Consoles follow one model everywhere**: a public seam, private
   backend modules, access gated by the vendor. MonoGame and Ebitengine,
   the two that ship on consoles, both do exactly this.
3. **Scaffolds survive only inside the toolchain.** `rails generate`,
   `dotnet new`, `flutter create` live; Yeoman generators and GitHub
   templates drift behind their engines and die.

### 1.2 What WIPE already built

Roughly 3,500 of WIPE's 11,000 lines are toolkit, not game:

| Piece | WIPE file | Game-specific? |
|---|---|---|
| Platform seam: overlay pause, achievement mirror, controller, prompts | `src/platform.w` | No |
| Steam: Input manifest and layouts, achievements, manual callback dispatch, one-build rule | `src/steam.w`, `src/achievement_sync.w`, `assets/steam/` | The action names |
| Actions-not-buttons contract; keyboard sampled once into `Keys`; pure arbitration | `src/controls.w`, `src/keyboard.w`, `src/input.w` | The action list |
| SDL controllers: every pad open, last-used drives, Steam Controller lizard mode | `src/gamepads.w`, `src/sdl.w` | No |
| Atomic save with backup and newer-version refusal; settings; paths | `src/save.w`, `src/settings.w`, `src/paths.w` | The fields |
| Window, aspect-ratio view, fullscreen, vsync, frame limit, fixed-step loop | `src/run.w`, the step clock in `src/game.w` | No |
| Deterministic recording and exact replay | `src/record.w` | No |
| Resource lifecycle in drop order; audio bank | `src/devices.w`, `src/audio.w` | No |
| Packaging with an explicit allowlist; UAT harnesses; tour; gallery | `build.w`, `src/uat.w`, `src/tour.w`, `src/gallery.w` | The pattern |
| The game | `src/game.w`, `src/loadout.w`, `src/app.w`, `src/presentation.w` | Yes |

Three of these exist in no surveyed ecosystem and are the toolkit's
differentiators: the fixed-step clock with exact replay; prompts named by
the platform rather than hard-coded; one build with the store SDK inert
when the client is absent.

## 2. Design rules

1. **The game reads actions, never buttons.** Every controller path
   produces one `ActionFrame`; a port adds a producer, not a change to the
   game. Prompts come from the platform, because every console requires its
   own button names and art.
2. **One build per game.** The store SDK is linked everywhere and inert
   without its client. The game never relaunches itself through a store.
3. **One seam for platforms.** `trait Platform` is the whole surface a
   store or console presents to the game. Public backends (none, Steam)
   ship in the package; console backends are private packages implementing
   the same trait, distributed only to the vendor-verified, the MonoGame
   way. A generated console slot fails with `comptime_error` until its
   backend is present (mission rule 7: fail loudly, never produce a
   plausible wrong thing).
4. **Drawing is confined.** raylib is the desktop renderer. The template
   keeps every draw call in one module and says in its README that a
   console port replaces that module. The toolkit does not abstract the
   renderer; that would be an engine, and a promise it cannot keep.
5. **Fixed steps, exact replay.** The simulation advances in whole steps
   counted as integers; a recording replays bit-for-bit. Tests, trailers
   and bug reports come from it.
6. **Flags and prompts are one surface.** Every question has a flag; a
   prompt appears only for a question no flag answered; `--yes` takes
   defaults or the last answers. CI never sees a prompt.
7. **Generation is not one-shot.** Platforms and stores arrive after
   creation, so adding one is a command (`with add`), never a re-run of the
   wizard.
8. **No template language.** A template is real With files, included or
   excluded per choice. No Liquid, no Rhai, no `#if` inside sources. The
   choices become facts the generated `build.w` already states. Generated
   With uses braces.
9. **Templates live in the compiler and run in the battery.** Every
   template is generated, built and tested on every host the battery
   covers, for every platform and store combination it offers.

## 3. The command surface

### 3.1 `with init --type game`

```text
with init my-game --type game
```

asks only for what the flags did not answer, in this order:

```text
Template?    basic / twin-stick                 (default: basic)
Platforms?   pc, mac, linux, steam-deck         (multi-select; default: the host and steam-deck)
Store?       steam / none                       (default: steam)
Org?         com.example                        (save directory and bundle identifiers)
Use these defaults, customize, or reuse last time?
```

then runs `with get` for the dependencies, writes `.gitignore`, runs
`git init`, builds, and runs the tests. The project is green at birth or
the command fails and says why.

Every answer is a flag:

| Flag | Meaning |
|---|---|
| `--type game` | Joins the existing `app` and `lib` types. |
| `--template basic\|twin-stick` | The genre starting point (Unreal's model). `basic` is the screens with an empty play state; `twin-stick` is WIPE's skeleton. |
| `--platforms pc,mac,linux,steam-deck` | Additive; also accepted later by `with add platform` (Flutter's model). |
| `--store steam\|none` | The store backend; also `with add store`. |
| `--org com.example` | Reverse-domain identifier for the save directory and bundle IDs. |
| `--yes` | Defaults, or the last answers if `--reuse`. |
| `--reuse` | The answers from the previous run on this machine. |
| `--dry-run` | Print the file list and the choices; write nothing. |
| `--list-templates` | The templates this compiler ships, with the platforms and add-ons each supports. |
| `--example <git url>` | A community starting point, outside the versioned path and said to be. |
| `--skip-build` | Do not build and test after generation. |
| `--no-git` | Do not `git init`. |

### 3.2 `with add`

On an existing game project, additive and idempotent:

```text
with add platform steam-deck
with add platform switch       # the slot and the build target; refuses to build until platform.switch is installed
with add store steam
with add replay
with add achievements
with add audio
```

Each add-on is a named set of files, dependencies and `build.w` edits.
Adding one twice is a no-op. Removing is manual; the toolkit does not
guess which of the developer's files depend on it.

Whether `with add` is a top-level verb or `with init --add` is decided in
milestone 3; the plan's examples assume the verb.

### 3.3 Answers are typed

Platforms and stores are closed enumerations the compiler knows; an
unknown name is an error naming the known ones. `--org` is validated as a
reverse-domain identifier. There are no free-text placeholders.

## 4. The `game` package

Fetched with `with get game`; the template depends on it. Its modules, in
dependency order, each with the WIPE file it is extracted from:

| Module | From | Contents |
|---|---|---|
| `game.controls` | `controls.w` | `ActionFrame`, the action bits, `Keys` |
| `game.platform` | `platform.w` | `trait Platform`, `PlatformFrame`, `NoPlatform` |
| `game.input` | `input.w` | `Device`, `Prompts`, `MenuState`, stick deadzones, echo suppression |
| `game.keyboard` | `keyboard.w` | `sample_keys()`: the only raylib input call |
| `game.gamepads` | `gamepads.w`, `sdl.w` | The SDL producer, every pad open, last-used drives, lizard mode |
| `game.steam` | `steam.w`, `achievement_sync.w` | `SteamPlatform`: Input, achievements, overlay, manual dispatch |
| `game.save` | `save.w`, `settings.w`, `paths.w` | Atomic writes, backup, version refusal, the settings file, asset and data paths |
| `game.clock` | the step clock in `game.w` | `STEPS_PER_SECOND`, `simulation_steps`, elapsed derived from steps |
| `game.record` | `record.w` | Recording and exact replay |
| `game.window` | `run.w` | The aspect-ratio view, fullscreen, vsync, frame limit, the frame loop |
| `game.devices` | `devices.w` | Window, audio and renderer lifetimes in drop order |
| `game.audio` | `audio.w` | A sound bank with cue-on-event playback |
| `game.package` | `build.w` | Build actions: allowlist packaging, the Steam library beside the executable, the Steam Input assets |

What stays in the template, not the package: the action *list* (a game
names its own actions), the save *fields*, the screens, the Steam Input
manifest's action names and default layouts, and every draw call.

### 4.1 The action list is the game's

`game.controls` ships the frame and the bit mechanism; the template
declares the actions. The Steam Input manifest and the SDL layout are
generated from that one declaration, so the three never disagree:

```with
// src/actions.w, generated by the template, edited by the developer
actions Menu { confirm, back, up, down, left, right, pause }
actions Flight { pause }
analog Menu { navigate }
analog Flight { move, aim }
```

Whether this is a `comptime` declaration or a plain table the package
reads is decided in milestone 2. It must produce the `assets/steam/*.vdf`
files at build time, not by hand.

### 4.2 Console slots

`with add platform switch` writes `src/platform_switch.w`:

```with
// Nintendo Switch. The backend is the private package platform.switch,
// distributed to vendor-verified developers. Until it is installed this
// target refuses to build.
comptime_error("platform.switch is not installed; see docs/platforms.md")
```

and a `build.w` target that lists the toolchain and SDK paths it will
need. When the package exists, the slot becomes `use platform.switch` and
`impl Platform for SwitchPlatform` lives in the package. The game never
changes.

## 5. Milestones

### Milestone 1: extract, and WIPE still passes

1. Create `lib/game/` in the `with` repository with the modules of §4,
   moved from WIPE with their tests (`test/*_contracts.w`).
2. WIPE depends on `game` through `with get`; its own copies are deleted.
3. WIPE builds on Mac, Linux and Windows, and all its test files pass. The
   Steam UAT passes on a machine with Steam and a controller.
4. The package's tests join the battery.

This milestone ships no template. It ends when WIPE's `src/` holds only
the game.

### Milestone 2: the `basic` template

1. The screens: title, settings (volume, deadzone, fullscreen, vsync,
   frame limit), pause, results. An empty play state with the fixed-step
   loop and replay wired.
2. The action declaration of §4.1 and the generated Steam Input assets.
3. `build.w` with packaging, and `test/` with the contract tests.
4. A README that says what the project has, what a console port replaces,
   and the Deck Verified checklist.
5. The battery generates the template for every platform and store
   combination, builds it, and runs its tests on every host.

### Milestone 3: the command

1. `with init --type game` with the flags and prompts of §3.1.
2. `with add platform` and `with add store`, with `with add` or
   `--add` decided here.
3. `--dry-run`, `--list-templates`, `--reuse`.
4. The `twin-stick` template, cut from WIPE.

### Milestone 4: the Deck, end to end

1. A generated `twin-stick` project runs on a Steam Deck under Steam
   Input with its default layout, prompts named by Steam, achievements
   mirrored, the overlay pausing, and sleep and resume surviving.
2. The Deck Verified checklist in the template's tests reflects what was
   verified.

### After this plan

Console backends, one at a time: `platform.xbox`, `platform.switch`,
`platform.ps5`. Each is its own plan, begins with vendor access, and
replaces the drawing module of §2 rule 4 for its renderer. Then mobile.

## 6. Acceptance

- `with init demo --type game --template basic --platforms pc,mac,linux,steam-deck --store steam --org com.example --yes` produces a project that builds and passes its tests on Mac, Linux and Windows without further input.
- The same project, copied to a Deck and launched from Steam, plays with the Deck's controls and shows Steam's prompt names.
- `with add platform switch` on that project produces a target that fails to build with the message of §4.2 and does not affect the other targets.
- WIPE depends on `game` and passes its battery with no toolkit code left in `src/`.
- Every template and platform/store combination is generated and built in the battery; a template that cannot be built is a failed battery, not a warning.

## 7. Open questions

1. `with add` as a verb, or `with init --add`.
2. Whether `--org` is needed, or the save directory uses the project name.
3. The form of the action declaration (§4.1): `comptime` or a table.
4. Whether the `card` template is wanted by anyone; it is not planned
   until someone is.

## 8. Advice that does not apply

| Advice | Why not |
|---|---|
| "Abstract the renderer now so consoles are free later." | That is an engine. Bevy and Godot own their renderers and still have no console story; MonoGame and Ebitengine got consoles by doing each backend. Confine drawing and say so. |
| "Use a template language so files can be conditional." | Rule 8. The conditions are platforms and stores, which the generated `build.w` already states as facts; files are included or not. |
| "Let the community host templates." | Rule 9. Every out-of-toolchain template in the survey drifted. `--example` exists for community starting points and says it is off the versioned path. |
| "Ask the renderer or quality settings at creation." | Godot and Unreal do; neither question belongs to a project. |

## 9. References

- Flutter Casual Games Toolkit: templates `basic`, `card`, `endless_runner`; samples for ads and multiplayer. The framing this plan borrows: plumbing around the game, mobile-first there, console/PC-first here.
- WIPE: SURVIVAL, `docs/steam-and-steam-deck-support.md`, decisions 1–8.
- MonoGame console access and Ebitengine's `nintendosdk` / `microsoftgdk` build tags: the private-backend model.
- `create-next-app`, `flutter create --platforms .`, `sv add`, `dotnet new --dry-run`: the command surface.
