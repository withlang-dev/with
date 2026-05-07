//! skip: non-executable spec sketch for Section 14.10 — Fair Select Await (formerly 25.72); contains pseudo-code for unimplemented feature work
// Spec test: Section 14.10 — Fair Select Await (formerly 25.72)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: fair select (default — random among ready branches)
loop:
    select await
        data = fast_stream.recv() => handle(data)
        _ = shutdown.recv() => break    // will eventually fire

// PASS: biased select (explicit — top-to-bottom priority)
select await biased
    urgent = priority_rx.recv() => handle_urgent(urgent)
    normal = normal_rx.recv() => handle_normal(normal)
