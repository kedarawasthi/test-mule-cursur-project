%dw 2.0
output application/json
---
{
  code: "BUSINESS_VALIDATION",
  message: error.description default "Cannot delete flight due to active bookings",
  activeBookings: vars.activeBookings default 0,
  flightId: vars.flightId default null,
  timestamp: now() as String
}
