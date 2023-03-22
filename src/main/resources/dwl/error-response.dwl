%dw 2.0
output application/json
---
{
  "timestamp": now(),
  "api": app.name,
  "code": vars.httpStatus,
  "message": error.errorType.identifier,
  "details": error.detailedDescription
}