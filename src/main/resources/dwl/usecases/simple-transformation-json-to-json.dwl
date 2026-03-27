%dw 2.0
output application/json
var inbound = if (payload is String)
                (read((payload as String), "application/dw") default {})
              else
                (payload default {})
---
{
  Field2: upper((inbound.Field1 default "") as String),
  phoneNumber: ((inbound.phoneNumber default "") as String) replace "-" with "",
  bookingDate: now() as String {format: "yyyy-MM-dd'T'HH:mm:ssXXX"}
}
