module nebula.main

// ===================================================================
// Nebula — Concurrent Telemetry Ingestion Daemon
//
// Demonstrates:
//   - Channels for cross-fiber communication
//   - select await for racing futures
//   - async scope for structured concurrency
//   - Error composition with `error ... from`
//   - Postfix await on task handles
//   - String interpolation
//   - defer for cleanup
//   - Channel ownership: dropping sender closes receiver
//   - with-blocks for scoped mutation
// ===================================================================

use std.channel
use std.time
use session.Session
use session.SessionError
use session.SessionStats
use session.handle_session
use session.compute_stats
use db.Database
use db.DbError
use schema.load_config
use schema.ServerConfig
use schema.build_test_batch

// --- Error Composition ---
//
// `from` generates a wrapper variant and a From impl per sub-error
// (§10.9), so `?` converts a DbError or SessionError into AppError.

error AppError from DbError, SessionError

// --- Entry Point ---

async fn main -> Result[Unit, AppError]:
    let config = load_config(None)

    // Open the database; `?` propagates a DbError as AppError.Db
    let db = Database.open(config.db_path.clone())?

    // Initialize the database schema
    db.init_schema()?

    print("=== Nebula Telemetry Daemon ===")
    print(f"Config: {config.host}:{config.port}, max_clients={config.max_clients}")

    // Channel for shutdown coordination.
    // Dropping the sender automatically closes the receiver.
    let (shutdown_tx, shutdown_rx) = chan[i32](1)

    // Channel for telemetry data flowing from sessions to the analyzer
    let (data_tx, data_rx) = chan[str](32)

    // --- Simulate Client Sessions ---
    //
    // In production, these would be spawned per TCP connection.
    // Here we demonstrate structured concurrency with async scope.

    let (session_tx1, session_rx1) = chan[str](8)
    let (session_tx2, session_rx2) = chan[str](8)

    // Feed test data to sessions
    session_tx1.send("sensor-alpha")
    session_tx1.send("sensor-beta")
    session_tx1.send("")  // signals end-of-session

    session_tx2.send("sensor-gamma")
    session_tx2.send("sensor-delta")
    session_tx2.send("")  // signals end-of-session

    // Structured concurrency: async scope guarantees all tracked
    // fibers complete or are cancelled before the scope exits, and
    // every tracked result is observed (§14.7).
    let packets = async scope s =>
        let first = s.track(handle_session(1, session_rx1))
        let second = s.track(handle_session(2, session_rx2))
        first.await? + second.await?

    print(f"\nAll sessions completed: {packets} packets.")

    // --- Test Batch Processing ---
    //
    // Build a test batch of telemetry records and insert them.

    let batch = build_test_batch(5)
    print(f"\nBatch of {batch.len()} telemetry records built.")
    db.insert_bulk(&batch)?

    // --- Select Await Demo ---
    //
    // Race a "data ready" signal against a "shutdown" signal.
    // Whichever completes first wins; the loser is cancelled at its next
    // suspension point (§14.10). The analyzer side sleeps before reading,
    // so the shutdown signal wins the race.

    shutdown_tx.send(1)

    let data_task = async:
        sleep(Duration.millis(300)).await
        data_rx.recv() ?? ""
    let shutdown_task = async:
        shutdown_rx.recv().unwrap()

    select await:
        _ = data_task =>
            print("\nData received before shutdown.")
        _ = shutdown_task =>
            print("\nShutdown signal received. Draining...")

    // --- Compute Final Stats ---

    let sessions = with Vec.new() as mut sessions:
        sessions.push(Session { id: 1, addr: "127.0.0.1", packets_received: 5 })
        sessions.push(Session { id: 2, addr: "127.0.0.2", packets_received: 3 })
    let stats = compute_stats(&sessions)
    print(f"\nFinal stats: {stats.active_count} active, {stats.total_packets} packets")

    print("\n=== Clean shutdown complete ===")
