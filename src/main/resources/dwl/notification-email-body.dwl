%dw 2.0
output application/json
---
{
  from: p("notification.email.from"),
  to: p("notification.email.to"),
  subject: "Flight batch summary - " ++ (vars.batchRequestId default "unknown"),
  body: payload
}
