module notify.email

use traits.*
use domain.*

// --- Email Notifier ---
//
// Demonstrates:
//   - Trait implementation for NotificationService
//   - Pattern matching on enum variants
//   - Default field values
//   - Mutable variables (var)

type EmailNotifier {
    smtp_host: str,
    smtp_port: u16 = 587,
    from_addr: str,
    max_per_minute: i32 = 100,
}

extend EmailNotifier:
    fn new(host: str, from: str) -> EmailNotifier:
        EmailNotifier {
            smtp_host: host,
            from_addr: from,
        }

impl NotificationService for EmailNotifier:    async fn send(self: &EmailNotifier, notif:
    Notification) -> bool:
        let priority_num = match notif.priority:
            .Urgent => 1
            .Normal => 3
            .Low    => 5

        // In production: connect to SMTP, build message, send
        print(f"Sending email to {notif.recipient} (priority={priority_num})")
        true

    async fn send_batch(self: &EmailNotifier, notifs: Vec[Notification]) -> i32:
        var sent = 0
        // In production: batch send with rate limiting
        sent
