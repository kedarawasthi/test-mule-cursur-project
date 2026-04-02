# Airline Code Review - Comments and Fixes Proposed

This review captures an unbiased coding-practice assessment of the current airline Mule codebase and proposes concrete remediation actions.

## 1) Review Summary

- Overall architecture and API organization are strong.
- Observability and operational readiness are above baseline.
- Security hygiene and contract-implementation alignment need targeted hardening.

## 2) Findings and Proposed Fixes

### High Priority

1. **Sensitive values committed in repository**
   - **Observed**:
     - Plaintext credentials/placeholders in runtime config and test fixtures.
     - Example: `src/main/resources/config-dev-secure.properties` and test attribute DWL files containing `client_secret`.
   - **Risk**:
     - Secret leakage, compliance violations, and audit failures.
   - **Proposed Fix**:
     - Remove all secrets from tracked files and rotate exposed credentials.
     - Keep only encrypted values in `config-${mule.env}-secure.properties`.
     - Use CI/CD secret injection and secure Runtime Manager properties.
     - Add secret-scanning pre-commit and CI checks.

2. **API contract mismatch for delete business validation**
   - **Observed**:
     - RAML advertises `409 Cannot delete flight with active bookings`.
     - `deleteFlightById` implementation currently validates existence only, then deletes.
   - **Risk**:
     - Contract drift, consumer trust erosion, and governance non-conformance.
   - **Proposed Fix**:
     - Before delete, query active bookings from `flight_bookings`.
     - Return business validation payload + HTTP 409 when active bookings exist.
     - Add regression tests for both `404` and `409` delete scenarios.

### Medium Priority

3. **Internal error details returned to API consumers**
   - **Observed**:
     - DB error path includes raw `error.description` in API response body.
   - **Risk**:
     - Information disclosure of internals and infrastructure details.
   - **Proposed Fix**:
     - Return standardized generic error externally.
     - Log detailed error internally with `transactionId` and `correlationId`.

4. **`select *` in main read queries**
   - **Observed**:
     - `getAllFlights` and `getFlightById` use `select *`.
   - **Risk**:
     - Fragility under schema evolution and unnecessary payload coupling.
   - **Proposed Fix**:
     - Use explicit column projection with aliasing aligned to response model.
     - Keep transformation mappings deterministic and contract-friendly.

5. **Update flow success path does not assert affected rows**
   - **Observed**:
     - `updateFlightById` does not validate update count prior to success path/notification.
   - **Risk**:
     - False-success response for non-existent IDs.
   - **Proposed Fix**:
     - Validate DB update result (`updatedRows > 0`).
     - Return 404-style payload when no row is updated.
     - Only trigger downstream notification for successful updates.

### Low Priority

6. **Configuration source overlap**
   - **Observed**:
     - `application.yaml` and env-property files both carry config patterns.
   - **Risk**:
     - Ambiguity and accidental fallback behavior.
   - **Proposed Fix**:
     - Keep one source-of-truth model (`config-${mule.env}.properties` + secure counterpart).
     - Retain only non-sensitive defaults in `application.yaml`, or remove duplicated keys.

## 3) Positive Practices Already Followed

- Environment-based property loading pattern is in place.
- APIKit listener and error mapping structure is organized and consistent.
- Circuit breaker design for DB resilience is implemented.
- Scheduler heartbeat with operational logging is present.
- Parameterized DB queries are used in CRUD operations.

## 4) Suggested Hardening Sequence

1. Secret remediation and credential rotation.
2. Delete-flow contract alignment (`409` for active bookings).
3. Error-response sanitization.
4. SQL projection cleanup and update-count guard.
5. Configuration source consolidation.

## 5) Definition of Done for Fix Cycle

- No plaintext credentials in repo.
- Delete API behavior fully aligned with RAML (`200/404/409` paths).
- No internal stack/error detail exposed to clients.
- `select *` removed from primary read paths.
- Regression tests updated for all corrected behavior.
