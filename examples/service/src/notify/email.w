module app.notify.email

use app.traits.NotificationService
use app.domain.{Notification, Priority}
use app.errors.NotifyError

type EmailNotifier = {
    smtp_host: str,
    smtp_port: u16 = 587,
    from_addr: str,
    rate_limit: RateLimiter,
}

impl NotificationService for EmailNotifier {
    async fn send(self: &EmailNotifier, notif: &Notification) -> Result[Unit, NotifyError] =
        if not self.rate_limit.try_acquire() then
            return Err(.RateLimited(Duration.seconds(60)))

        let email = with SmtpMessage.new() as mut msg:
            msg.from = self.from_addr.clone()
            msg.to = notif.recipient.clone()
            msg.subject = notif.subject.clone()
            msg.body = notif.body.clone()
            msg.priority = match notif.priority
                .Urgent -> 1
                .Normal -> 3
                .Low    -> 5

        let transport = SmtpTransport.connect(&self.smtp_host, self.smtp_port).await?
        transport.send(&email).await?
        Ok()
        // transport dropped here -> connection closed via Drop

    async fn send_batch(self: &EmailNotifier, notifs: &[Notification]) -> Result[i32, NotifyError] =
        var sent = 0
        for notif in notifs:
            match self.send(notif).await
                Ok() -> sent += 1
                Err(.RateLimited(d)) -> return Err(.RateLimited(d))
                Err(_) -> ()  // skip individual failures
        Ok(sent)
}
