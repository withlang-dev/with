module nebula.session

// ===================================================================
// Session — Fibers, Generators, Channels & Async Patterns
//
// Demonstrates:
//   - Generators (gen fn) as pull-based lazy sequences
//   - Async functions and .await
//   - Channels for cross-fiber communication
//   - select await for racing futures
//   - async scope for structured concurrency
//   - defer for guaranteed cleanup
//   - if let for optional pattern matching
//   - with blocks for scoped mutable access
//   - Field shorthand in struct literals
//   - Error types and Result propagation
// ===================================================================

use std.channel
use schema.Telemetry
use schema.Status
use db.Database

// --- Session Types ---

pub type Session {
    id: i32,
    addr: str,
    packets_received: i32 = 0,
}

// --- Error Type ---

pub error SessionError =
    | ParseFailed(str)
    | Disconnected
    | Timeout

// --- Generator: Packet Extractor ---
//
// `gen fn` compiles to a state machine struct, not a fiber.
// It's purely synchronous: the caller pulls values on demand.

gen fn extract_packets(count: i32) -> Telemetry:
    for i in 0..count:
        yield Telemetry {
            device_id: f"dev-{i}",
            temp: 20.0 + (i as f64) * 0.5,
        }

// --- Generator: Range Stepper ---
//
// Yields values from start to end with a given step size.
// Demonstrates generator composition and lazy evaluation.

gen fn step_range(start: i32, end: i32, step: i32) -> i32:
    var i = start
    while i < end:
        yield i
        i = i + step

// --- Telemetry Parser ---
//
// Uses `if let` for optional pattern matching and match expressions.

fn parse_telemetry(raw: str) -> Option[Telemetry]:
    if raw.len() == 0:
        return None

    Some(Telemetry {
        device_id: raw,
        temp: 0.0,
        status: .Active,
    })

// --- Batch Parser ---
//
// Parses a list of raw strings into telemetry records.
// Uses a with-block for scoped mutable access to the result Vec.

fn parse_batch(lines: Vec[str]) -> Result[Vec[Telemetry], SessionError]:
    with Vec.new() as mut results:
        for line in lines:
            match parse_telemetry(line):
                Some(t) => results.push(t)
                None    => return Err(.ParseFailed("invalid input"))

// --- Async Session Handler ---
//
// Demonstrates:
//   - Async functions and channel recv
//   - defer for guaranteed cleanup
//   - Match on Option for message handling
//   - Result propagation

async fn handle_session(id: i32, rx: Receiver[str]) -> Result[i32, SessionError]:
    var session = Session { id, addr: "127.0.0.1" }
    defer: print(f"[session {id}] cleanup")

    loop:
        let msg = rx.recv()
        if msg.len() == 0:
            break
        session.packets_received = session.packets_received + 1
        match parse_telemetry(msg):
            Some(t) => print(f"[session {id}] got: {t.device_id} temp={t.temp}")
            None    => print(f"[session {id}] parse failed")
    session.packets_received

// --- Multi-Session Handler with Select ---
//
// Races two channels using select await.
// Demonstrates priority-based multiplexing.

async fn handle_priority(
    primary: Receiver[str],
    secondary: Receiver[str],
) -> str:
    let primary_task = async:
        primary.recv()
    let secondary_task = async:
        secondary.recv()

    select await:
        msg = primary_task =>
            f"primary: {msg}"
        msg = secondary_task =>
            f"secondary: {msg}"

// --- Session Stats ---
//
// Query sessions to compute aggregate statistics.
// Uses with-block for building the result.

pub type SessionStats {
    active_count: i32,
    total_packets: i32,
}

pub fn compute_stats(sessions: &Vec[Session]) -> SessionStats:
    var total: i32 = 0
    for s in sessions:
        total = total + s.packets_received
    SessionStats {
        active_count: sessions.len32(),
        total_packets: total,
    }

// --- Structured Concurrency Demo ---
//
// Uses async scope to run multiple session handlers concurrently.
// The scope guarantees all tracked tasks complete before exiting.

async fn run_sessions(db: &Database):
    let (tx1, rx1) = chan[str](8)
    let (tx2, rx2) = chan[str](8)

    // Send test data to channels
    tx1.send("sensor-alpha")
    tx1.send("sensor-beta")
    tx1.send("")  // signals end

    tx2.send("sensor-gamma")
    tx2.send("")  // signals end

    // Structured concurrency: all tracked tasks complete
    // before the scope exits
    async scope s =>
        s.track(handle_session(1, rx1))
        s.track(handle_session(2, rx2))

    print("all sessions completed")
