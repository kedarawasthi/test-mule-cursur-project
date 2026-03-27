%dw 2.0
output application/json
---
{
  message: "Flight updated successfully",
  flightId: vars.flightId,
  notificationsQueued: true,
  targetedPassengers: sizeOf(vars.passengerEmails default []),
  operation: "UPDATE",
  timestamp: now() as String
}
