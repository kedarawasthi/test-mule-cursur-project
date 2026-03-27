%dw 2.0
import * from dw::test::Asserts
---
payload must equalTo([
  {
    "ID": 1,
    "code": "rree",
    "price": 541,
    "departureDate": "2016-01-20T05:30:00",
    "origin": "MUA",
    "destination": "LAX",
    "emptySeats": 0,
    "plane": {
      "type": "Boeing 787",
      "totalSeats": 200
    }
  },
  {
    "ID": 2,
    "code": "eefd",
    "price": 300,
    "departureDate": "2016-01-25T05:30:00",
    "origin": "MUA",
    "destination": "CLE",
    "emptySeats": 7,
    "plane": {
      "type": "Boeing 747",
      "totalSeats": 345
    }
  },
  {
    "ID": 3,
    "code": "ffee",
    "price": 300,
    "departureDate": "2016-01-20T05:30:00",
    "origin": "MUA",
    "destination": "LAX",
    "emptySeats": 0,
    "plane": {
      "type": "Boeing 777",
      "totalSeats": 300
    }
  },
  {
    "ID": 4,
    "code": "rree",
    "price": 200,
    "departureDate": "2016-01-20T05:30:00",
    "origin": "MUA",
    "destination": "CLE",
    "emptySeats": 5,
    "plane": {
      "type": "Boeing 737",
      "totalSeats": 150
    }
  },
  {
    "ID": 5,
    "code": "rree",
    "price": 142,
    "departureDate": "2016-02-11T05:30:00",
    "origin": "MUA",
    "destination": "SFO",
    "emptySeats": 1,
    "plane": {
      "type": "Boeing 737",
      "totalSeats": 150
    }
  },
  {
    "ID": 6,
    "code": "ffee",
    "price": 954,
    "departureDate": "2016-01-20T05:30:00",
    "origin": "MUA",
    "destination": "CLE",
    "emptySeats": 100,
    "plane": {
      "type": "Boeing 787",
      "totalSeats": 200
    }
  },
  {
    "ID": 7,
    "code": "eefd",
    "price": 676,
    "departureDate": "2016-01-01T05:30:00",
    "origin": "MUA",
    "destination": "SFO",
    "emptySeats": 0,
    "plane": {
      "type": "Boeing 777",
      "totalSeats": 300
    }
  },
  {
    "ID": 8,
    "code": "ffee",
    "price": 300,
    "departureDate": "2016-02-20T05:30:00",
    "origin": "MUA",
    "destination": "SFO",
    "emptySeats": 30,
    "plane": {
      "type": "Boeing 737",
      "totalSeats": 150
    }
  },
  {
    "ID": 9,
    "code": "eefd",
    "price": 900,
    "departureDate": "2016-02-01T05:30:00",
    "origin": "MUA",
    "destination": "SFO",
    "emptySeats": 0,
    "plane": {
      "type": "Boeing 737",
      "totalSeats": 150
    }
  },
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
  },
  {
    "ID": 11,
    "code": "rree",
    "price": 456,
    "departureDate": "2016-01-20T05:30:00",
    "origin": "MUA",
    "destination": "SFO",
    "emptySeats": 100,
    "plane": {
      "type": "Boeing 737",
      "totalSeats": 150
    }
  }
])