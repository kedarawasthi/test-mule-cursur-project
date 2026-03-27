%dw 2.0
output application/json
fun formatPrice(p) = ((p default 0) as Number) as String {format: "0.00"}
fun asArray(value) =
  if (value is Array) value
  else if (value == null) []
  else [value]
---
(asArray(payload.flights.flight default []))
  filter ((flight) -> (flight.status default "") as String != "CANCELLED")
  map ((flight) -> {
    flightId: flight.id as String,
    route: {
      origin: if ((flight.src default "") as String == "JFK") "John F. Kennedy" else "Other",
      destination: flight.dest as String
    },
    departureTime: if ((flight.deptTime default "") != "")
                    (flight.deptTime as LocalDateTime {format: "yyyy-MM-dd'T'HH:mm"})
                  else
                    null,
    price: formatPrice(flight.price),
    status: "Open",
    processedAt: now(),
    legacySource: "SOAP"
  })
