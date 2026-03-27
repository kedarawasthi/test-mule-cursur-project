%dw 2.0
output application/xml
var baggage = payload.baggage default []
var normalBaggage = baggage filter ((b) -> (b.weight default 0) as Number <= 30)
var heavyBaggage = baggage filter ((b) -> (b.weight default 0) as Number > 30)
---
pnrData: {
  passengerName: payload.passengerName default "",
  flightNumber: payload.flightNumber default "",
  travelDate: if ((payload.travelDate default "") != "")
                ((payload.travelDate as Date {format: "MM/dd/yyyy"}) as String {format: "yyyy-MM-dd"})
              else
                "",
  specialAssistance: ((payload.flightClass default "") as String) == "Business",
  baggage: {
    normalBaggage: normalBaggage map ((b) -> {
      id: b.id,
      weightKg: (b.weight default 0) as Number
    }),
    heavyBaggage: heavyBaggage map ((b) -> {
      id: b.id,
      weightKg: (b.weight default 0) as Number
    })
  }
}
