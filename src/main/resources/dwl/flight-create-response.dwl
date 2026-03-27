%dw 2.0
output application/json
---
{
  message: "Flight created successfully",
  id: attributes.uriParams.ID default payload.ID default null,
  operation: "CREATE",
  timestamp: now() as String
}
