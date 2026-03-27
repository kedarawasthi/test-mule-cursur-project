%dw 2.0
output application/json skipNullOn="everywhere"
fun asArray(value) =
  if (value is Array) value
  else if (value == null) []
  else [value]
var flights = asArray(payload.flights.flight default [])
---
{
  flightIds: flatten(flights map ((f) -> asArray(f.options.option default []) map ((o) -> o.id as String))),
  totalOptionCount: sizeOf(flatten(flights map ((f) -> asArray(f.options.option default [])))),
  flights: flights
    filter ((f) -> (f.AvailableSeats default 0) as Number >= 1)
    map ((f) -> {
      FlightId: f.FlightId as String,
      DepartureCity: f.DepartureCity as String,
      ArrivalCity: f.ArrivalCity as String,
      category: f.category as String,
      price: if ((f.category default "") as String == "Domestic")
               ((f.price default 0) as Number) * 1.1
             else
               (f.price default 0) as Number
    })
}
