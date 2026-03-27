%dw 2.0
import * from dw::test::Asserts
---
payload must equalTo([
  {
    "ID": 10,
    "code": "eefd",
    "price": 900,
    "departureDate": "2016-01-15T05:30:00",
    "origin": "MUA",
    "destination": "LAX",
    "emptySeats": 100,
    "plane": {
      "type": "Boeing 777",
      "totalSeats": 300
    }
  }
])