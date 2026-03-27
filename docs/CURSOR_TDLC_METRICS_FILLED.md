# Cursor TDLC Metrics (Filled from Attached Matrix)

This sheet fills the attached TDLC capability/task matrices for **Cursor AI** based on the actual execution outcomes in this delivery.

## A) Comparative Analysis - TDLC Capabilities (Cursor AI Filled)

Scale used from attached sheet: `0-4` (higher is stronger).

| Capability | Parameter | Cursor AI Score (0-4) | Evidence in this project |
|---|---|---:|---|
| Requirement Generation | Epic Generation | 3 | Converted high-level asks into phased execution backlog and concrete implementation steps |
| Requirement Generation | Features Generation | 4 | Delivered scheduler, external logging, DW endpoints, deployment automation, docs |
| Requirement Generation | User Stories Generation | 3 | Derived testable stories from iterative prompts and validated via endpoint checks |
| Design Document Generation | Functional Design Generation | 4 | Produced service-level behavior docs and Exchange-facing overview |
| Design Document Generation | Technical Design Generation | 4 | Produced HLD/LLD with component-level architecture and workflow details |
| Build | API Level | 4 | Implemented and maintained APIKit + RAML-driven routes and DW demos |
| Build | Code Generation | 4 | End-to-end Mule XML, DW, scripts, and operational configs |
| Build | Code Review | 3 | Repeated troubleshooting and targeted fixes with runtime evidence |
| Test Case Generation | Functional (Manual) Test Cases | 4 | Endpoint smoke/regression and negative-path validations |
| Test Case Generation | Test Automation Scripts (MUnits) | 2 | MUnit artifacts exist; repository/auth blockers reduced full execution throughput |
| Test Case Generation | Test Data Generation Based on Tests | 3 | Generated representative payloads for DW and API test paths |
| Deployment | Able to validate/deploy components | 4 | Repeated CloudHub2 deploy + health checks + post-deploy logs |
| Platform | Exchange Integration | 4 | Published API spec (`1.0.1`) and Exchange docs |
| Platform | API Manager and Runtime Operations | 3 | Full runtime ops achieved; APIM registration deferred per latest direction |

## B) Comparative Analysis - TDLC Capabilities wrt Current Approach (Cursor AI Filled)

Scale used from attached sheet: `0-4`.

| Capability | Parameter | Cursor AI Score (0-4) | Effort Reduction with current approach |
|---|---|---:|---:|
| Requirement Generation | Epic Generation | 3 | 30% |
| Requirement Generation | Features Generation | 4 | 40% |
| Requirement Generation | User Stories Generation | 3 | 30% |
| Design Document Generation | Functional Design Generation | 4 | 50% |
| Design Document Generation | Technical Design Generation | 4 | 55% |
| Build | API Level | 4 | 45% |
| Build | Code Generation | 4 | 50% |
| Build | Code Review | 3 | 25% |
| Test Case Generation | Functional (Manual) Test Cases | 4 | 40% |
| Test Case Generation | Test Automation Scripts (MUnits) | 2 | 20% |
| Test Case Generation | Test Data Generation Based on Test Cases | 3 | 30% |
| Deployment | Able to validate/deploy components | 4 | 45% |
| Platform | Exchange Integration | 4 | 50% |
| Platform | API Manager and Runtime Operations | 3 | 30% |

## C) TDLC Evaluation - Task Level Metrics (1/2) - Cursor AI

Scale used from attached sheet: `1-10`.

### Requirement

| Assessment Metric | Cursor Score | Effort Reduction |
|---|---:|---:|
| Requirement (Epic/Feature/User Story) analysis | 8 | 35% |
| Architecture Diagram | 8 | 45% |
| Functional Design Document / Technical Design | 9 | 55% |
| Fragment Creation | 8 | 40% |
| Request Response Data Type Creation | 8 | 40% |
| RAML Creation/Review | 9 | 50% |

### Build

| Assessment Metric | Cursor Score | Effort Reduction |
|---|---:|---:|
| API level: API Template create/update | 9 | 45% |
| API level: API Flow Creation | 9 | 50% |
| API level: API Development | 8 | 45% |
| API level: Error Handling Creation | 8 | 40% |
| Code Development: DataWeave Creation Complexity | 8 | 45% |
| Code Development: Batch Processing | 8 | 40% |
| Code Development: Scatter Gather | 7 | 30% |
| Code Development: Real time processing | 8 | 35% |
| Code Development: Salesforce Connector | 5 | 10% |
| Code Development: DB Connector (Mongo) | 6 | 15% |
| Code Review | 7 | 25% |
| Security: Data privacy handling | 8 | 35% |
| Security: Code exposure risk | 7 | 20% |

## D) TDLC Evaluation - Task Level Metrics (2/2) - Cursor AI

### Governance

| Assessment Metric | Cursor Score | Effort Reduction |
|---|---:|---:|
| Policy enforcement | 6 | 20% |
| Code validation | 8 | 35% |

### Testing

| Assessment Metric | Cursor Score | Effort Reduction |
|---|---:|---:|
| Mock service creation | 7 | 30% |
| MUnit test suite creation | 6 | 20% |
| Postman Collection | 9 | 55% |

### Deployment

| Assessment Metric | Cursor Score | Effort Reduction |
|---|---:|---:|
| Application Deployment | 9 | 50% |
| Git Integration | 8 | 40% |
| External Logging Enablement | 8 | 35% |

### Platform

| Assessment Metric | Cursor Score | Effort Reduction |
|---|---:|---:|
| Exchange Operations | 9 | 55% |
| API Manager Operations | 6 | 20% |
| Runtime Manager Operations | 8 | 40% |
| Manage Schedulers | 9 | 50% |

## E) Notes

- Scores are grounded in executed outcomes for this project, not generic model benchmarks.
- API Manager score is intentionally conservative because registration stabilization remains a deferred item by current direction.
- Deployment/Exchange/Design documentation scores are high due to completed and verified outcomes.
