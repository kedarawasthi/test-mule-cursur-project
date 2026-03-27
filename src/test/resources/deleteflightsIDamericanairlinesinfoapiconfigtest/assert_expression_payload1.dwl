%dw 2.0
import * from dw::test::Asserts
---
payload must equalTo({
  "message": "Flight deleted by ID (but not really"
})