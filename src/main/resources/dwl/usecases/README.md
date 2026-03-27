# DataWeave Use Cases from "AI Prompts for Dataweave Generation"

This folder implements concrete DataWeave scripts aligned to the prompt categories in:
`airline-docs/DataWeave Parameters/AI Prompts for Dataweave Generation.docx`.

## Implemented scripts

- `simple-transformation-json-to-json.dwl`
  - JSON -> JSON
  - uppercase mapping
  - string cleanup (remove dashes)
  - add current timestamp field

- `complex-transformation-xml-to-json.dwl`
  - XML -> JSON
  - skip null handling
  - conditional tax update for Domestic category
  - filter by available seats
  - flatten nested options, extract IDs, count totals

- `multi-scenario-1-json-to-xml.dwl`
  - JSON -> XML
  - scenario-based mapping
  - conditional flag for business class
  - baggage partition by weight
  - date format conversion

- `multi-scenario-2-xml-to-json.dwl`
  - XML -> JSON
  - status-based filtering (skip cancelled)
  - data type conversion and formatting
  - source normalization (JFK mapping)
  - processed timestamp enrichment

## Runtime usage in core flows

Core implementation has been refactored to call reusable DW scripts for:

- flight read response mapping
- create/update response mapping
- validation error mapping
- batch summary mapping
- notification body mapping

This provides measurable evidence for Cursor efficiency in both:
- generating new transformation scripts, and
- operationalizing reusable DataWeave in production-like Mule flows.
