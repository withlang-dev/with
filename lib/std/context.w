// std.context — conventional implicit execution context.

use std.alloc

pub type TraceId: Copy {
    value: i64,
}

pub type CancellationToken: Copy {
    cancelled: bool,
}

pub trait Logger:    fn info(self: &Self, message:
    str) -> Unit
    fn warn(self: &Self, message: str) -> Unit
    fn error(self: &Self, message: str) -> Unit

pub type NoopLogger {}

impl Logger for NoopLogger:    fn info(self: NoopLogger, message:
    str) -> Unit:
        let _ = self
        let _ = message
    fn warn(self: NoopLogger, message: str) -> Unit:
        let _ = self
        let _ = message
    fn error(self: NoopLogger, message: str) -> Unit:
        let _ = self
        let _ = message

pub type Context ephemeral {
    temp: TempArena,
    logger: NoopLogger,
    cancellation: CancellationToken,
    trace_id: TraceId,
}

pub fn default_context() -> Context:
    Context {
        temp: scratch_arena(),
        logger: NoopLogger {},
        cancellation: CancellationToken { cancelled: false },
        trace_id: TraceId { value: 0 },
    }

pub fn Context.with_temp(self: Context) -> Context:
    Context {
        temp: scratch_arena(),
        logger: self.logger,
        cancellation: self.cancellation,
        trace_id: self.trace_id,
    }
