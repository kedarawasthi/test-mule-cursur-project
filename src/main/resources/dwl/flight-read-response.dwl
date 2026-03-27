%dw 2.0
output application/json
---
(payload default []) map (item) -> {
  ID: item.ID,
  code: item.code1 default item.code default "",
  price: (item.price default 0) as Number,
  departureDate: (item.takeOffDate default item.departureDate default "") as String,
  origin: item.fromAirport default item.origin default "",
  destination: item.toAirport default item.destination default "",
  emptySeats: (item.seatsAvailable default item.emptySeats default 0) as Number,
  plane: {
    "type": item.planeType default (item.plane."type" default ""),
    totalSeats: (item.totalSeats default item.plane.totalSeats default 0) as Number
  }
}
