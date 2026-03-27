# Operations, Security, and API Manager Checklist

This project now includes baseline implementation for:
- Scheduler-based operational heartbeat (`src/main/mule/ops.xml`)
- External logging plumbing (`external-logging-http-request-config` and JSON console logs)
- CloudHub Postman collection (`postman/american-airlines-info-api-cloudhub.postman_collection.json`)
- Transaction-aware log messages (`transactionId` propagation + structured logger messages)

## 1) Scheduler-based service

- Flow: `scheduledOperationalHeartbeat`
- Purpose:
  - Periodic DB health check (`select 1`)
  - Optional external log push
- Config keys:
  - `ops.heartbeat.enabled`
  - `ops.heartbeat.frequencySeconds`

## 2) External logging enablement

- `log4j2.xml` now writes:
  - Rolling file logs
  - JSON console logs (CloudHub-friendly for external observability forwarders)
- Optional outbound log sink via HTTP request config:
  - `external.logging.enabled`
  - `external.logging.protocol`
  - `external.logging.host`
  - `external.logging.port`
  - `external.logging.basePath`
  - `external.logging.apiKey` (secure properties file)

## 3) Postman collection for CloudHub app

- Import:
  - `postman/american-airlines-info-api-cloudhub.postman_collection.json`
- Defaults:
  - `baseUrl` points to deployed CloudHub URL
  - Includes placeholders for:
    - Basic auth policy validation
    - Client ID / Client Secret policy validation

## 4) Data privacy handling

- Sensitive values live in:
  - `config-<env>-secure.properties`
- Runtime Manager recommendation:
  - Mark sensitive runtime properties as **Secure** in the UI.
  - Avoid plain text secrets in deployment scripts/CLI history.
- Encryption helper:
  - `scripts/encrypt-secure-properties.ps1`
  - Use Mule Secure Properties Tool jar to generate encrypted values.

## 5) Proper loggers + transaction tracking

- `transactionId` is set at API entry and reused across flows.
- Loggers now include:
  - `txId`
  - Event name
  - Flight ID / destination where relevant

## 6) Git integration

Suggested commands from project root:

```bash
git init
git add .
git commit -m "Initialize Mule project with ops, logging, and security baseline"
```

If using remote:

```bash
git remote add origin <your-repo-url>
git branch -M main
git push -u origin main
```

## 7) Auto-discovery + API Manager policies + client apps/SLA/contracts

- Automation starter script:
  - `scripts/setup-api-manager.ps1`
- Script covers:
  - API instance creation from Exchange asset
  - Basic Authentication policy application
  - Bronze/Gold SLA tier creation
- After API instance creation:
  - Set API Autodiscovery ID in Runtime Manager app properties
  - Configure client apps and contracts in API Manager according to governance rules
  - Validate policy enforcement via CloudHub Postman collection

