# Summary — Issue #16: Pluggable Signal Source Connectors

## What changed and why

### 1. `connectors/CONNECTOR-INTERFACE.md` (new)
Documents the signal source interface: what signal categories exist (`sent_activity`, `flagged_items`, `saved_items`, `calendar`, `notifications`, `assigned_items`, `recent_docs`), the query contract each connector must satisfy, the normalized signal shape (with required `source_breadcrumb`), and how to declare a connector in `mcp.json` + `config.json`.

**PR review feedback (per-connector config + BYO skill):**
- Added a `config` sub-object per connector with standard field names (`usernames`, `username`, `project_filter`, `notification_reasons`, `issue_types`, `since_field`) for user identity scoping and query customization.
- Added a `skill` optional field enabling BYO skill: if declared, the COLLECT step invokes that skill instead of generic NL queries. Documents the skill's input/output contract.

Addresses acceptance criterion: *"Document signal source interface (what a connector must provide)"*.

### 2. `connectors/jira/README.md` (new)
Community connector example for Jira. Covers installation, `mcp.json` + `config.json` snippets, what signal categories it provides, and troubleshooting.

**PR review feedback:** Added a `config` block table documenting all Jira-specific options (`username`, `project_filter`, `notification_reasons`, `issue_types`). Added an "Advanced: BYO Skill" section showing how to declare `skill` and install a custom COLLECT skill.

Addresses acceptance criterion: *"At least one example community connector"*.

### 3. `config.example.json` (modified)
Added `connectors` array with `config` blocks on each default connector. The GitHub connector now shows `usernames` and `notification_reasons` as example config. Preserves backward compatibility — `connectors` absent falls back to built-in defaults.

### 4. `prompts/pm.md` — COLLECT step (modified)
Connector-agnostic COLLECT that reads `config.json → connectors`. **PR review feedback:** Added BYO skill dispatch (invoke `skill` if declared, skip generic queries for that connector) and `config` scoping (use `config.usernames`, `config.notification_reasons`, `config.project_filter` when querying).

Addresses acceptance criterion: *"Refactor COLLECT steps to be connector-agnostic"*.

### 5. `prompts/am.md` — COLLECT step (modified)
Same refactor and BYO skill + config scoping as pm.md.

### 6. `design.md` — Architecture section (modified)
Added §1a "Pluggable Signal Source Connectors" explaining the two-file declaration model (`mcp.json` + `config.json`) and how community connectors extend the system.

## Spec / design sections supporting the change

- **spec.md §5 Data Sources** — The spec already acknowledges M365 + GitHub as signal sources; this change makes that list extensible.
- **design.md §1 Architecture / §3 Plans** — The COLLECT step in PM and AM plans is the only component that varies by connector. Synthesis skills and memory are unchanged, consistent with the proposal: *"Core (memory, skills, prompts) stays unchanged — only the COLLECT step varies."*
