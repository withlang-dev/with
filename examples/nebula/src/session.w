module nebula.session

// ===================================================================
// Session — Fibers, Arenas, Pipelines & Generators
//
// Demonstrates:
//   - Generational arenas (SlotMap) with safe handle invalidation
//   - Generators (gen fn) as pull-based lazy sequences
//   - Pipeline operators (|>) for data transformation
//   - traverse() for bulk fallible operations
//   - let ... else for early exit from patterns
//   - Chained if let to avoid nested pyramids
//   - select await biased for priority-based multiplexing
//   - defer for guaranteed cleanup
//   - Disjoint field borrowing (buffer vs metadata)
//   - with blocks for scoped mutable access
//   - Field shorthand in struct literals
//   - The `in` operator in filter predicates
//   - Closure syntax and filter_map composition
// ===================================================================

use std.collections.SlotMap
use std.net.TcpStream
use std.sync.Arc
use nebula.schema.{Telemetry, Status}
use nebula.db.Database

// --- Session Types ---

pub type Session = {
    id: u64,
    addr: str,
    buffer: Vec[u8] = Vec.new(),
    packets_received: u64 = 0,
}

pub type SessionPool = Shared[SlotMap[Session]]

// --- Error Type ---

pub error SessionError =
    | ParseFailed(reason: str)
    | Disconnected
    | Timeout

// --- Generator: Packet Extractor ---
//
// `gen fn` compiles to a state machine struct, not a fiber.
// It's purely synchronous: the caller pulls values on demand.
// Captures &[u8] — the generator is ephemeral (cannot be stored
// beyond the lifetime of `data`).

gen fn extract_packets(data: &[u8]) -> str:
    let text = String.from_utf8_lossy(data)
    for line in text.split("\n"):
        let trimmed = line.trim()
        if trimmed.len() > 0 then yield trimmed.to_string()

// --- Generator: Sliding Window ---
//
// Yields overlapping windows of size N from a slice.
// Demonstrates generator composition and lazy evaluation.

gen fn sliding_window[T](items: &[T], size: usize) -> &[T]:
    if items.len() >= size:
        for i in 0..=(items.len() - size):
            yield &items[i..i + size]

// --- Telemetry Parser ---
//
// Tests chained `if let` (no pyramid of doom) and `??` default operator.

fn parse_telemetry(raw: &str) -> Option[Telemetry]:
    let parts = raw.split(",").collect[Vec]()

    // Chained if let: all patterns must match for the body to execute
    if let Some(dev_id) = parts.get(0),
       let Some(temp_str) = parts.get(1):

        let temp = temp_str.trim().parse_f64() ?? 0.0

        let status = if let Some(status_str) = parts.get(2):
            match status_str.trim()
                "ok"      -> .Ok
                "warning" -> .Warning("from device")
                "fatal"   -> .Fatal(code: 1)
                _         -> .Ok
        else:
            .Ok

        Some(Telemetry {
            device_id: dev_id.trim().to_string(),
            temp,
            status,
        })
    else:
        None

// --- Batch Parser with traverse ---
//
// Parses a list of raw strings into telemetry records.
// Uses traverse: map + collect-or-fail in a single pass.

fn parse_batch(lines: &[str]) -> Result[Vec[Telemetry], SessionError]:
    lines.traverse(|line|
        parse_telemetry(line)
            .ok_or(.ParseFailed(reason: "invalid: {line}"))
    )

// --- Client Connection Handler ---
//
// The main fiber for a TCP client. Demonstrates:
//   - SlotMap insert/remove with generational handles
//   - defer for guaranteed handle cleanup
//   - select await biased for priority multiplexing
//   - let ... else for early exit
//   - Pipeline operators for data transformation
//   - The `in` operator in filter predicates

pub async fn handle_client(
    stream: TcpStream,
    pool: SessionPool,
    db: Arc[Database],
) -> Result[Unit, SessionError]:

    // Insert session into the generational arena
    let handle = with pool.write() as mut map:
        map.insert(Session {
            id: Rng.new().next_u64(),
            addr: stream.peer_addr()?.to_string(),
        })

    // defer guarantees cleanup even if the fiber is cancelled
    // or an error propagates via ?
    defer with pool.write() as mut map:
        map.remove(handle)

    loop:
        var buf = Vec.filled(0, 1024)

        // select await biased: timeout arm has lower priority than IO
        select await biased
            bytes_read = stream.read(&mut buf) ->
                // let ... else for early exit on error or EOF
                let Ok(n) = bytes_read else break
                if n == 0 then break
                buf.truncate(n)

                // Update session buffer (disjoint field borrowing:
                // we borrow only `buffer` and `packets_received`)
                with pool.write() as mut map:
                    let Some(sess) = map.get_mut(handle) else break
                    sess.buffer.extend_from_slice(&buf)
                    sess.packets_received += 1

                // Pipeline: extract → parse → filter → collect
                let valid_packets = extract_packets(&buf)
                    |> filter_map(|s| parse_telemetry(&s))
                    |> filter(|p| p.status not in [.Fatal(code: 1), .Fatal(code: 2)])
                    |> collect[Vec]()

                // Bulk insert the valid telemetry records
                if not valid_packets.is_empty():
                    db.insert_bulk(&valid_packets)?

            _ = timeout(30.secs()) ->
                println("Session timeout for handle {handle}")
                break

// --- Session Stats ---
//
// Query the arena to compute aggregate statistics.
// Uses pipeline operators and with-block for read access.

pub type SessionStats = {
    active_count: usize,
    total_packets: u64,
    total_bytes: u64,
}

pub fn compute_stats(pool: &SessionPool) -> SessionStats:
    with pool.read() as map:
        let sessions = map.values().collect[Vec]()
        SessionStats {
            active_count: sessions.len(),
            total_packets: sessions.iter()
                |> map(|s| s.packets_received)
                |> sum(),
            total_bytes: sessions.iter()
                |> map(|s| s.buffer.len() as u64)
                |> sum(),
        }
