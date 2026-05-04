// Tests for the Nebula telemetry daemon example


// --- Domain types (standalone for testing) ---

enum Status { Ok | Warning(str) | Fatal(code: i32) }

type Telemetry {
    device_id: str,
    temp: f64,
    status: Status,
}

enum Severity { Low | Medium | High | Critical }

type ServerConfig {
    host: str,
    port: i32,
    max_clients: i32,
    idle_timeout_secs: i32,
    db_path: str,
}

// --- Status helpers ---

fn is_fatal(s: Status) -> bool:
    match s:
        Fatal(_) => true
        _        => false

fn status_label(s: Status) -> i32:
    match s:
        Ok         => 0
        Warning(_) => 1
        Fatal(_)   => 2

// --- Temperature classification ---

fn classify_temp(temp: f64) -> i32:
    if temp > 100.0: 3      // Critical
    else if temp > 80.0: 2  // High
    else if temp > 60.0: 1  // Medium
    else: 0                      // Low

fn should_alert(severity: i32) -> bool:
    severity >= 2  // High or Critical

// --- Config defaults and record update ---

fn default_config -> ServerConfig:
    ServerConfig {
        host: "0.0.0.0",
        port: 8080,
        max_clients: 1000,
        idle_timeout_secs: 30,
        db_path: "telemetry.db",
    }

fn config_with_port(base: ServerConfig, port: i32) -> ServerConfig:
    ServerConfig {
        host: base.host,
        port,
        max_clients: base.max_clients,
        idle_timeout_secs: base.idle_timeout_secs,
        db_path: base.db_path,
    }

// --- Packet extraction helpers ---

fn count_nonempty_lines(lines: [5]i32, count: i32) -> i32:
    var result = 0
    for i in 0..count:
        if lines[i] > 0:
            result = result + 1
    result

// --- CSV field parsing helper ---

fn parse_field_count(field_lens: [4]i32, total: i32) -> i32:
    var valid = 0
    for i in 0..total:
        if field_lens[i] > 0:
            valid = valid + 1
    valid

// --- Batch builder ---

fn build_batch_status(index: i32) -> i32:
    if index % 10 == 0: 2     // Fatal
    else if index % 5 == 0: 1 // Warning
    else: 0                        // Ok

fn batch_temp(index: i32) -> f64:
    20.0 + (index as f64) * 0.5

// --- Session stats ---

type SessionStats {
    active_count: i32,
    total_packets: i32,
    total_bytes: i32,
}

fn aggregate_stats(counts: [3]i32, packets: [3]i32, bytes: [3]i32) -> SessionStats:
    var total_p = 0
    var total_b = 0
    var active = 0
    for i in 0..3:
        if counts[i] > 0:
            active = active + 1
        total_p = total_p + packets[i]
        total_b = total_b + bytes[i]
    SessionStats {
        active_count: active,
        total_packets: total_p,
        total_bytes: total_b,
    }

// --- Sliding window count ---

fn window_count(len: i32, size: i32) -> i32:
    if len >= size: len - size + 1 else: 0

// --- Tests ---

@[test]
fn test_nebula_example:
    // Test Status matching
    assert(is_fatal(Fatal(code: 42)))
    assert(not is_fatal(Ok))
    assert(not is_fatal(Warning("test")))

    // Test status_label
    assert(status_label(Ok) == 0)
    assert(status_label(Warning("oops")) == 1)
    assert(status_label(Fatal(code: 1)) == 2)

    // Test temperature classification
    assert(classify_temp(25.0) == 0)   // Low
    assert(classify_temp(65.0) == 1)   // Medium
    assert(classify_temp(85.0) == 2)   // High
    assert(classify_temp(105.0) == 3)  // Critical

    // Test should_alert
    assert(not should_alert(0))  // Low
    assert(not should_alert(1))  // Medium
    assert(should_alert(2))      // High
    assert(should_alert(3))      // Critical

    // Test default config
    let cfg = default_config()
    assert(cfg.port == 8080)
    assert(cfg.max_clients == 1000)
    assert(cfg.idle_timeout_secs == 30)

    // Test config with port override (record update)
    let custom = config_with_port(cfg, 9090)
    assert(custom.port == 9090)
    assert(custom.max_clients == 1000)  // Unchanged
    assert(custom.idle_timeout_secs == 30)  // Unchanged

    // Test packet line counting
    let lines: [5]i32 = [3, 0, 5, 2, 0]
    assert(count_nonempty_lines(lines, 5) == 3)
    assert(count_nonempty_lines(lines, 2) == 1)

    // Test field parsing
    let fields: [4]i32 = [5, 3, 0, 7]
    assert(parse_field_count(fields, 4) == 3)
    assert(parse_field_count(fields, 2) == 2)

    // Test batch status assignment
    assert(build_batch_status(0) == 2)   // 0 % 10 == 0 → Fatal
    assert(build_batch_status(5) == 1)   // 5 % 5 == 0 → Warning
    assert(build_batch_status(3) == 0)   // else: → Ok
    assert(build_batch_status(10) == 2)  // 10 % 10 == 0 → Fatal
    assert(build_batch_status(15) == 1)  // 15 % 5 == 0 → Warning
    assert(build_batch_status(7) == 0)   // else: → Ok

    // Test batch temperature
    assert(batch_temp(0) == 20.0)
    assert(batch_temp(10) == 25.0)
    assert(batch_temp(20) == 30.0)

    // Test session stats aggregation
    let counts: [3]i32 = [1, 1, 0]
    let packets: [3]i32 = [10, 20, 0]
    let bytes: [3]i32 = [100, 200, 0]
    let stats = aggregate_stats(counts, packets, bytes)
    assert(stats.active_count == 2)
    assert(stats.total_packets == 30)
    assert(stats.total_bytes == 300)

    // Test sliding window count
    assert(window_count(10, 3) == 8)
    assert(window_count(3, 3) == 1)
    assert(window_count(2, 3) == 0)
    assert(window_count(5, 1) == 5)
    assert(window_count(0, 1) == 0)
