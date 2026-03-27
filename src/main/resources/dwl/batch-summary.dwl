%dw 2.0
output application/json
---
{
  requestId: vars.batchRequestId,
  totalRecords: (vars.totalRecords default 0) as Number,
  successCount: (vars.successCount default 0) as Number,
  failedCount: (vars.failedCount default 0) as Number,
  failedRecords: vars.failedRecords default []
}
