# Project Lifecycle and Service Workflows

## 1) Delivery Lifecycle Used

1. **Design**
   - RAML maintained under `src/main/resources/api`
   - Design Center project `american-airlines-info-api` synced from local RAML files
2. **Build**
   - Maven packaging with Mule Maven Plugin (`mule:deploy`)
   - Environment-scoped property model (`mule.env`)
3. **Deploy**
   - CloudHub 2 deployment via `scripts/deploy-cloudhub2.ps1`
4. **Operate**
   - Scheduler heartbeat for continuous DB health check
   - External logging integration (config-driven)
5. **Govern**
   - Exchange publication for API spec versions (latest published: `1.0.1`)
   - API Manager instances maintained separately for policy governance

## 2) Service Inventory

- **Interface Services**
  - `GET /api/flights`
  - `GET /api/flights/{ID}`
  - `POST /api/flights`
  - `PUT /api/flights/{ID}`
  - `DELETE /api/flights/{ID}`
  - `POST /api/flights/batch`
- **Transformation Services**
  - `POST /dw/simple`
  - `POST /dw/complex`
  - `POST /dw/multi1`
  - `POST /dw/multi2`
- **Operational Service**
  - `scheduledOperationalHeartbeat` (fixed-frequency scheduler)

## 3) Workflow Details

### 3.1 Request Processing Workflow

1. Incoming request reaches HTTP listener.
2. `transactionId` gets initialized (from `correlationId` or generated UUID where required).
3. APIKit routes to operation flow.
4. Implementation flow executes DB/business logic.
5. Optional outbound integration is called (notification/external logs).
6. Standardized response and status code are returned.

### 3.2 Batch Workflow

1. Batch request accepted.
2. Records are split and processed.
3. Per-record failures are captured for summary.
4. Consolidated outcome is returned to caller.

### 3.3 Heartbeat Workflow

1. Scheduler wakes up every configured interval.
2. Executes `select 1 as ok` against DB.
3. Logs success/failure with transaction context.
4. Sends operational log payload to external logging endpoint when enabled.

## 4) Runtime Validation Summary

- Actual CloudHub app: `american-airlines-info-app-dev` is `RUNNING`.
- Scheduler heartbeat logs are continuously emitted (`event=ops.heartbeat.success` observed across intervals).
- DataWeave endpoints verified with valid sample payloads:
  - `/dw/simple` -> 200
  - `/dw/complex` -> 200
  - `/dw/multi1` -> 200
  - `/dw/multi2` -> 200

## 5) Artifacts and Automation

- Deploy script: `scripts/deploy-cloudhub2.ps1`
- Exchange API spec publish: `scripts/publish-api-spec.ps1`
- API Manager bootstrap: `scripts/setup-api-manager.ps1`
- Secure property encryption helper: `scripts/encrypt-secure-properties.ps1`
