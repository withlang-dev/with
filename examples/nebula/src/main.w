module nebula.main

// ===================================================================
// Nebula — Concurrent Telemetry Ingestion Daemon
//
// Demonstrates:
//   - OS threads vs lightweight fibers (thread.spawn_os vs async)
//   - Channels for cross-thread communication
//   - select await for racing futures
//   - async scope for structured concurrency
//   - Signal handling (SIGINT graceful shutdown)
//   - Error composition with `error ... from`
//   - Arc for thread-safe shared ownership
//   - Postfix await on task handles
//   - String interpolation in println
//   - defer for cleanup
//   - Channel ownership: dropping sender closes receiver
// ===================================================================

use std.net.TcpListener
use std.signal.{on_signal, Signal}
use std.sync.Arc
use std.time.Duration
use nebula.session.{handle_client, SessionPool, compute_stats}
use nebula.db.Database
use nebula.schema.{load_config, ServerConfig}

// --- Error Composition ---
//
// `error ... from` generates wrapper variants + From impls automatically.
// `IoError` becomes variant `Io(IoError)`, etc. The `?` operator uses
// the generated `From` impls for automatic conversion across boundaries.

error AppError =
    Io(IoError)
    | Db(nebula.db.DbError)
    | Session(nebula.session.SessionError)

// --- Entry Point ---

fn main:
    let config = load_config(std.process.env("PORT")?.parse_u16().ok())

    // Thread-safe generational arena for concurrent sessions
    let pool = SessionPool.new(SlotMap.new())
    let db = Arc.new(Database.open(&config.db_path).expect("failed to open database"))

    // Initialize the database schema
    db.init_schema().expect("failed to initialize schema")

    print("=== Nebula Telemetry Daemon ===")
    print("Config: {config.host}:{config.port}, max_clients={config.max_clients}")

    // Channel for shutdown coordination.
    // Dropping the sender automatically closes the receiver.
    let (shutdown_tx, shutdown_rx) = chan[Unit](1)

    // Register SIGINT handler — dropping the sender signals shutdown
    on_signal(.SIGINT, () => drop(shutdown_tx))

    // --- OS Thread: Background Analyzer ---
    //
    // CPU-bound work runs on a dedicated OS thread, not a fiber.
    // Fibers should never block on CPU work. The compiler prevents
    // calling .await inside non-async functions.

    let _worker = thread.spawn_os(() => background_analyzer(db.clone(), pool.clone()))

    // --- Fiber Runtime: Async Server ---
    //
    // Enter the async world. The `async:` block creates an inline future.

    let server_task = async:
        let listener = TcpListener.bind("{config.host}:{config.port}").await?
        print("Listening on {config.host}:{config.port}")

        // Structured concurrency: async scope guarantees all tracked
        // fibers complete or are cancelled before the scope exits.
        async scope s =>
            loop:
                // Fair select await: races new connections vs shutdown.
                select await
                    conn_res = listener.accept() =>
                        let Ok(stream) = conn_res else continue

                        // Track the new fiber — it inherits cancellation
                        // from the enclosing scope.
                        s.track(handle_client(stream, pool.clone(), db.clone()))

                    _ = shutdown_rx.recv() =>
                        print("\nSIGINT received. Draining connections...")
                        break

        // Scope guarantees: all spawned fibers have completed or
        // been cancelled. Destructors have run. Resources are freed.
        let stats = compute_stats(&pool)
        print("Final stats: {stats.active_count} active, {stats.total_packets} packets")

    // Postfix await blocks the main thread until the server completes.
    match server_task.await:
        Ok()   => print("Clean shutdown complete.")
        Err(e) => eprint("Fatal error: {e}")

// --- Background Analyzer ---
//
// Runs on a raw OS thread. Cannot use `.await` — the compiler
// enforces this because the function is not marked `async`.
// If we tried to .await inside insert_bulk's lock, the compiler
// would catch the @[no_await_guard] violation.

fn background_analyzer(db: Arc[Database], pool: SessionPool):
    loop:
        thread.sleep(Duration.seconds(60))

        // Snapshot session stats from the arena
        let stats = compute_stats(&pool)
        if stats.total_packets > 0:
            print("[analyzer] {stats.active_count} sessions, {stats.total_packets} packets ingested")

        // Periodic maintenance — blocking is safe on OS threads
        match db.execute("DELETE FROM telemetry WHERE ts < strftime('%s','now') - 86400"):
            Ok()   => ()
            Err(e) => eprint("[analyzer] cleanup error: {e}")
