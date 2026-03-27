# Deployment Next Steps (MUnit Skipped)

## 1) Pre-checks

- Ensure Java 17 is active.
- Ensure Connected App variables are set in the same terminal:
  - `ANYPOINT_CONNECTED_APP_CLIENT_ID`
  - `ANYPOINT_CONNECTED_APP_CLIENT_SECRET`

PowerShell:

```powershell
$env:ANYPOINT_CONNECTED_APP_CLIENT_ID="..."
$env:ANYPOINT_CONNECTED_APP_CLIENT_SECRET="..."
```

## 2) Package + Deploy to CloudHub 2.0

From project root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-cloudhub2.ps1
```

This runs:

- `mvn -s .\munit-settings.xml -Pcloudhub-dev clean package mule:deploy -DskipTests`
- injects:
  - `-Dmule.env=dev`
  - `-Dmule.key=cursur12345678`
  - Connected App values into Maven deploy command.

## 3) Check deployment health via CH2 APIs

Get org/env ids from Anypoint and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check-cloudhub2.ps1 `
  -OrgId "<org-guid>" `
  -EnvId "<env-guid>" `
  -AppName "american-airlines-info-app-dev"
```

This reports:

- deployment id
- status
- replicas/target/last update
- failure cause (if present)

## 4) Smoke tests after deploy

- `GET /api/flights`
- `GET /api/flights?destination=SFO`
- `DELETE /api/flights/{non-existing-id}` expects `404`
- selected DataWeave demo endpoints

## 5) MUnit (later, once EE repo auth is fixed)

Run:

```powershell
mvn -s .\munit-settings.xml test
```

Current known blocker is EE repo auth (`mulesoft-ee-releases` 401) for runtime BOM resolution.
