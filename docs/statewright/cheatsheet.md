# Statewright — Compact API Cheatsheet

> Task 1.1 deliverable for the `statewright-workflow-layer` OpenSpec change.
> Sources: [statewright/statewright](https://github.com/statewright/statewright) `main` @ 2026-09-11.
> Verbatim field names quoted from `crates/engine/src/types.rs`,
> `crates/mcp-gateway/src/custom_tools.rs`, `crates/mcp-gateway/src/config.rs`,
> `crates/cli/src/events.rs`, `crates/tui/src/main.rs`, and the repo README.
> Anything not confirmed in-source is marked `⚠️ UNVERIFIED`.

---

## 0. Binaries at a glance

| Binary | Crate | Purpose |
|---|---|---|
| `statewright-gateway` | `crates/mcp-gateway` | MCP proxy + hook HTTP server. Enforces per-state guardrails at the tool-call layer. Owns session state in memory. |
| `sw-agent` | `crates/cli` (bin) | Direct-to-Ollama constrained agent executor. Runs whole workflow or a single state (`--state`), streams JSONL events (`--json-events`). |
| `statewright` | `crates/tui` (bin) | Ratatui TUI. Spawns `sw-agent` as a subprocess, renders its JSONL event stream. |

Workspace: `edition = "2024"`, `resolver = "2"`, license Apache-2.0 / FSL-1.1-ALv2 (gateway).
Crates: `engine`, `agent`, `cli`, `tui`, `mcp-gateway`.

No `rust-toolchain.toml` / `rust-toolchain` file in the repo (`⚠️ UNVERIFIED` minimum rustc — edition 2024 implies **rustc ≥ 1.85**).

---

## 1. Workflow JSON — top-level keys

Source: `crates/engine/src/types.rs :: MachineDefinition`.

```rust
pub struct MachineDefinition {
    pub id: String,                                 // required
    pub initial: String,                            // required — name of starting state
    pub context: serde_json::Value,                 // default: null; free-form context blob
    pub states: BTreeMap<String, StateDef>,         // required — map of state name → StateDef
    pub guards: BTreeMap<String, GuardDef>,         // default: {}
    pub meta: Option<MachineMeta>,                  // default: None
    pub interrupts: BTreeMap<String, InterruptDef>, // default: {}
}
```

| Key | Type | Default | Notes |
|---|---|---|---|
| `id` | string | required | Machine ID, e.g. `"bug-fix"`, `"nine-seconds"`. |
| `initial` | string | required | Name of the state the machine starts in. Must be a key of `states`. |
| `context` | any JSON | `null` (via `#[serde(default)]`) | Initial context blob available to guards and merged with transition `data`. |
| `states` | object<name, StateDef> | required | See §2. |
| `guards` | object<name, GuardDef> | `{}` | See §4. |
| `meta` | object (MachineMeta) | omitted | See §5. |
| `interrupts` | object<name, InterruptDef> | `{}` | See §6. |

⚠️ **There is no top-level `schema_version` field** in `MachineDefinition`. The docs mention a JSON schema at `https://statewright.ai/workflow-schema.json` but the deserialised struct has no version key. Downstream code that wants versioning should put it in `meta.extra`.

Nor are there top-level `transitions`, `allowed_tools`, `on_enter`, `on_exit`, or `requires_human_approval` keys — those live on individual `StateDef` / `TransitionDef` (§2, §3) or on `meta.requires_human_approval` (§5). `⚠️ UNVERIFIED`: no `on_enter` / `on_exit` hooks were found on `StateDef` in the source — task-2 authors should not assume they exist.

### Full-machine JSON example (from `templates/bugfix/config.json`)

```json
{
  "definition": {
    "id": "bug-fix",
    "initial": "localizing",
    "states": {
      "localizing":   { "allowed_tools": [], "instructions": "PROGRAMMATIC: grep + extract relevant code sections.",
                        "on": { "LOCALIZED": "planning", "FAIL": "failed" } },
      "planning":     { "allowed_tools": ["Read","Grep","Glob","LS","Bash"],
                        "instructions": "Read relevant files and plan your fix. Do NOT edit anything yet.",
                        "max_iterations": 5, "safe_next": "implementing",
                        "on": { "PLAN_READY": "implementing", "FAIL": "failed" } },
      "implementing": { "allowed_tools": ["Read","Grep","Edit","Write","Bash"],
                        "instructions": "Implement the fix. Make targeted, minimal edits.",
                        "max_iterations": 8,
                        "on": { "DONE": "testing", "FAIL": "failed" } },
      "testing":      { "allowed_tools": ["Read","Bash"],
                        "allowed_commands": ["*test*"],
                        "instructions": "Run the tests. If they fail, use TESTS_FAIL to go back and fix.",
                        "max_iterations": 3,
                        "on": { "TESTS_PASS": "completed", "TESTS_FAIL": "implementing", "FAIL": "failed" } },
      "completed":    { "type": "final" },
      "failed":       { "type": "final" }
    },
    "guards": {}
  },
  "upstream_servers": []
}
```

Note the enveloping `{ "definition": ..., "upstream_servers": [...] }` — that shape is a **gateway config file**, not the raw `MachineDefinition`. See §8.

---

## 2. `StateDef` — state object shape

Source: `crates/engine/src/types.rs :: StateDef`.

```rust
pub struct StateDef {
    pub on: BTreeMap<String, TransitionDef>,        // event name → transition
    #[serde(rename = "type")]
    pub state_type: Option<StateType>,              // "final" | "parallel"
    pub allowed_tools: Option<Vec<String>>,         // whitelist
    pub disallowed_tools: Option<Vec<String>>,      // blacklist; takes precedence if both set
    pub instructions: Option<String>,
    pub max_iterations: Option<u32>,
    pub safe_next: Option<String>,                  // fallback target for unknown events
    pub max_edit_lines: Option<u32>,
    pub allowed_commands: Option<Vec<String>>,      // prefix / glob command allow-list
    pub allowed_commands_tool: Option<String>,      // default "Bash"
    pub max_files_per_state: Option<u32>,
    pub context_budget_bytes: Option<u64>,
    #[serde(alias = "deny_env")]
    pub blocked_env: Option<Vec<String>>,
    #[serde(alias = "env")]
    pub env_overrides: Option<BTreeMap<String, String>>,
    pub model: Option<String>,
    pub thinking_level: Option<String>,             // "high" | "medium" | "low" | "off"
    pub direct_execution: Option<bool>,             // TUI delegates to sw-agent
    pub model_ladder: Option<Vec<serde_json::Value>>,
}
```

| Field | Type | Default | Behaviour |
|---|---|---|---|
| `on` | object<EVENT, TransitionDef> | `{}` | Event→transition. Event names conventionally UPPER_SNAKE (`DONE`, `FAIL`, `TESTS_PASS`, `PLAN_READY`, `FORK`, `BRANCH_DONE:lint`). See §3. |
| `type` | `"final"` \| `"parallel"` | absent | `final` makes state terminal; further transitions return an error. |
| `allowed_tools` | string[] | `null` (= unrestricted `⚠️ UNVERIFIED`) | Tool whitelist. Empty array = block everything. |
| `disallowed_tools` | string[] | `null` | Blacklist. **Takes precedence over `allowed_tools`** per source comment. |
| `instructions` | string | absent | Injected into the model prompt / surfaced by `statewright_get_state`. |
| `max_iterations` | u32 | absent | Cap agent iterations in this state. |
| `safe_next` | string | absent | Target state when the model emits an **unrecognised** event. FAIL and known events unaffected. |
| `max_edit_lines` | u32 | absent | Edit-guard: reject diffs exceeding N lines. |
| `allowed_commands` | string[] | absent | Prefix / glob allow-list for the `Bash` tool (e.g. `["pytest", "cargo test", "*test*"]`). |
| `allowed_commands_tool` | string | `"Bash"` | Which tool the command allow-list applies to. |
| `max_files_per_state` | u32 | absent | Cap distinct files edited in this state. |
| `context_budget_bytes` | u64 | absent | Cap agent context accumulation. |
| `blocked_env` | string[] | absent | Env vars stripped from `Bash` commands. `alias = "deny_env"`. |
| `env_overrides` | object<string,string> | absent | Env vars injected as context (advisory). `alias = "env"`. |
| `model` | string | absent | Per-state model routing (e.g. `"claude-haiku-4-5-20251001"`, `"anthropic/claude-opus-4-6"`). Falls back to `meta.default_model`. |
| `thinking_level` | `"high"` \| `"medium"` \| `"low"` \| `"off"` | absent | Reasoning effort. Hosts that don't support it treat as advisory. |
| `direct_execution` | bool | `false` | When true, orchestrating TUI delegates the state to `sw-agent`. |
| `model_ladder` | any[] | absent | Model escalation ladder for `direct_execution` states. `⚠️ UNVERIFIED` inner element shape — declared as `Vec<serde_json::Value>`. |

`StateType`:

```rust
#[serde(rename_all = "snake_case")]
pub enum StateType { Final, Parallel }   // → "final" | "parallel"
```

⚠️ No `on_enter` / `on_exit` action hooks are declared on `StateDef`. Downstream tasks (Nix packaging, JSON Schema authoring) should not assume they exist.

---

## 3. `TransitionDef` — transition object shape

Source: `crates/engine/src/types.rs :: TransitionDef` — an **untagged enum** with 5 variants.

```rust
#[serde(untagged)]
pub enum TransitionDef {
    Simple(String),
    Full {
        target: String,
        guard: Option<String>,
        guards: Option<Vec<String>>,
        requires_approval: Option<bool>,
        approval_message: Option<String>,
    },
    Guarded(Vec<GuardedTransition>),
    Fork  { fork: ForkDef },
    Invoke {
        invoke: String,          // sub-machine name
        on_complete: String,
        on_fail: Option<String>,
        input: Option<serde_json::Value>,
    },
}
```

### 3.1 Simple — plain target string

```json
{ "on": { "DONE": "testing" } }
```

### 3.2 Full — target + guard(s) + approval gate

```json
{
  "on": {
    "APPROVED": {
      "target": "execute_fix",
      "requires_approval": true,
      "approval_message": "Review the proposed fix before allowing execution."
    }
  }
}
```

| Field | Type | Notes |
|---|---|---|
| `target` | string | Required. Destination state. |
| `guard` | string | Optional single guard name (must exist in top-level `guards`). |
| `guards` | string[] | Optional list of guard names (AND semantics `⚠️ UNVERIFIED` — inferred from code that concatenates both). |
| `requires_approval` | bool | Default false. When true, transition parks in `pending_approval` and surfaces `approval_message`. |
| `approval_message` | string | Optional prompt shown to the reviewer. |

### 3.3 Guarded — conditional array, first-match wins

```json
{
  "on": {
    "CHECK": [
      { "target": "completed",    "guard": "tests_passed" },
      { "target": "implementing", "guard": "tests_failed" }
    ]
  }
}
```

`GuardedTransition`:

```rust
pub struct GuardedTransition {
    pub target: String,
    pub guard: Option<String>,
    pub guards: Option<Vec<String>>,
}
```

### 3.4 Fork — parallel branches with join

Source: `crates/engine/src/types.rs :: ForkDef`, `BranchDef`, `JoinStrategy`. See also `docs/guides/fork-join.md`.

```json
{
  "on": {
    "FORK": {
      "fork": {
        "branches": {
          "lint": { "initial": "implementing", "terminal": "branch-done" },
          "test": { "initial": "implementing", "terminal": "branch-done" },
          "docs": { "initial": "implementing", "terminal": "branch-done" }
        },
        "join": "all",
        "on_complete": "review",
        "on_fail": "failed"
      }
    }
  }
}
```

```rust
pub struct ForkDef {
    pub branches: BTreeMap<String, BranchDef>,
    #[serde(default = "default_join")]
    pub join: JoinStrategy,        // default: All
    pub on_complete: String,
    pub on_fail: Option<String>,
}
pub struct BranchDef {
    pub initial: String,
    pub terminal: String,
}
#[serde(rename_all = "snake_case")]
pub enum JoinStrategy { All, Any }   // → "all" | "any"
```

`BRANCH_DONE` event format: **`BRANCH_DONE:<branch_name>`** (colon-suffixed).

### 3.5 Invoke — delegate to a sub-machine

```json
{
  "on": {
    "START_VALIDATION": {
      "invoke": "validation-machine",
      "on_complete": "next-step",
      "on_fail": "recovery",
      "input": { "target_file": "src/foo.rs" }
    }
  }
}
```

| Field | Type | Notes |
|---|---|---|
| `invoke` | string | Sub-machine name (must exist in registry). |
| `on_complete` | string | Parent state to resume on success. |
| `on_fail` | string | Optional parent state to resume on failure. |
| `input` | any JSON | Optional initial context for the sub-machine. |

**Important**: on an invoke transition, the parent state does **not** advance until the sub-machine completes (per `custom_tools::handle_transition` comment).

---

## 4. `GuardDef` — declarative predicates

Source: `crates/engine/src/types.rs`.

```rust
pub struct GuardDef {
    pub field: String,
    pub op: GuardOp,
    pub value: serde_json::Value,   // default null
}

#[serde(rename_all = "snake_case")]
pub enum GuardOp {
    Eq, Neq, Gt, Gte, Lt, Lte,
    Exists, NotExists,
    In, Contains,
}
```

Serialised operator strings: `"eq"`, `"neq"`, `"gt"`, `"gte"`, `"lt"`, `"lte"`, `"exists"`, `"not_exists"`, `"in"`, `"contains"`.

Example:

```json
"guards": {
  "tests_passed": { "field": "test_result", "op": "eq",  "value": "pass" },
  "coverage_ok":  { "field": "coverage",    "op": "gte", "value": 80 }
}
```

Guards evaluate against the machine's `context` blob. Transitions with a failing guard return a `GuardFailed { guard }` error surfaced to the caller as *"Transition '\<event\>' from state '\<state\>' was blocked by a guard condition."*

---

## 5. `MachineMeta` — machine-level metadata

Source: `crates/engine/src/types.rs :: MachineMeta`.

```rust
pub struct MachineMeta {
    pub task_type: Option<String>,
    pub estimated_steps: Option<u32>,
    pub danger_level: Option<DangerLevel>,          // "safe"|"moderate"|"dangerous"
    pub requires_human_approval: Option<bool>,
    pub capture_output: Option<bool>,
    pub default_model: Option<String>,
    pub workspace: Option<WorkspacePolicy>,
    pub preview: Option<PreviewPolicy>,
    pub promotion: Option<PromotionPolicy>,
    #[serde(flatten)]
    pub extra: BTreeMap<String, serde_json::Value>, // forward-compat catch-all
}
```

The README also documents `meta.approval_mode` (`"local"` default vs `"external"`) and `meta.debug` (gates `statewright_force_state`) — these ride in `extra` because they are **not typed fields** in the source (`⚠️ UNVERIFIED` as structural fields; verified as behavioural knobs referenced by the gateway).

### 5.1 `WorkspacePolicy`

```rust
pub struct WorkspacePolicy {
    pub version: u32,
    pub mode: WorkspaceMode,       // "git_worktree"
    pub required: bool,             // default false
    pub cleanup: WorkspaceCleanup,  // "never" | "after_promoted"
}
```

### 5.2 `PreviewPolicy`

```rust
pub struct PreviewPolicy {
    pub version: u32,
    pub mode: PreviewMode,          // "taskfile"
    pub required: bool,             // default false
    pub prepare_state: String,
    pub deploy_state: String,
    pub validate_state: String,
}
```

### 5.3 `PromotionPolicy`

```rust
pub struct PromotionPolicy {
    pub version: u32,
    pub mode: PromotionMode,        // "manual" | "squash"
    pub required: bool,             // default false
    pub promote_state: String,
    pub teardown_on_final: bool,    // default false
}
```

### 5.4 Enum wire strings

| Enum | Wire values |
|---|---|
| `DangerLevel` | `"safe"`, `"moderate"`, `"dangerous"` |
| `WorkspaceMode` | `"git_worktree"` |
| `WorkspaceCleanup` | `"never"`, `"after_promoted"` |
| `PreviewMode` | `"taskfile"` |
| `PromotionMode` | `"manual"`, `"squash"` |

---

## 6. `InterruptDef` — reactive auto-transitions

Source: `crates/engine/src/types.rs`.

```rust
pub struct InterruptDef {
    pub trigger: InterruptTrigger,
    pub target: String,
}
pub struct InterruptTrigger {
    pub file_pattern: String,       // glob
}
```

```json
"interrupts": {
  "on-config-edit": {
    "trigger": { "file_pattern": "**/*.toml" },
    "target": "validate-config"
  }
}
```

Interrupts use the **History State** pattern: current state stashed under `context._interrupt_return`; when the handler completes, use the `$return` event to resume. `get_state` surfaces this as `interrupt_handler: { return_state, message }`.

---

## 7. MCP tools — exact names, descriptions, JSON Schemas

Source: `crates/mcp-gateway/src/custom_tools.rs :: custom_tool_definitions()`. Transport is **JSON-RPC 2.0 over MCP** (methods `initialize`, `tools/list`, `tools/call`). Server name in `initialize` result: `"statewright-gateway"`.

### 7.1 `statewright_transition`

> Transition the state machine to a new state by emitting an event.

```json
{
  "type": "object",
  "properties": {
    "event": { "type": "string",
               "description": "The transition event name (e.g., DONE, FAIL, PLAN_READY)" },
    "data":  { "type": "object",
               "description": "Optional context data merged after the transition completes. Available for guard evaluation on subsequent transitions, not the current one." }
  },
  "required": ["event"]
}
```

**Response shape** (from `handle_transition`):

```json
{
  "transitioned": true,
  "from": "planning",
  "to": "implementing",
  "requires_approval": false,
  "approval_message": null,
  "transition_count": 3,
  "usage": { "transitions": 3, "limit": 200, "remaining": 197,
             "warning": "…"  /* optional */ },
  "fork":   { /* only on fork transitions */ },
  "invoke": { /* only on invoke transitions */ }
}
```

### 7.2 `statewright_get_state`

> Get the current state machine state, available tools, transitions, and iteration count.

Input schema: `{ "type":"object", "properties":{} }` (no args).

**Response shape** (from `handle_get_state`):

```json
{
  "state": "implementing",
  "is_final": false,
  "allowed_tools": ["Read","Edit","Write","Bash"],
  "transitions": [ { "event": "DONE", "target": "testing" }, ... ],
  "iteration": 2,
  "max_iterations": 8,
  "instructions": "…",
  "model": "claude-sonnet-4-20250514",
  "default_model": "claude-sonnet-4-20250514",
  "thinking_level": null,
  "transition_count": 3,
  "blocked_env": null,
  "env_overrides": null,
  "context": { /* current context blob */ },
  "guards": { /* guards referenced by outgoing transitions */ },
  "meta":   { /* MachineMeta */ },
  "allowed_commands": ["pytest","cargo test"],
  "disallowed_tools": null,
  "direct_execution": false,
  "model_ladder": null,
  "interrupts": { /* if any defined */ },
  "pending_approval": {                        /* optional */
    "approval_id": "…",
    "event": "APPROVED",
    "from_state": "approve_fix",
    "to_state":   "execute_fix",
    "message":    "Review the proposed fix …"
  },
  "interrupt_handler": {                       /* optional */
    "return_state": "planning",
    "message": "You are in an interrupt handler. …"
  }
}
```

### 7.3 `statewright_get_usage`

> Get state-level provider token usage, tool-result estimates, and non-tool overhead. Values identify whether they are exact or estimated.

Input schema: `{ "type":"object", "properties":{} }`.

### 7.4 `statewright_list_workflows`

> List all available named workflows and which one is currently active.

Input schema: `{ "type":"object", "properties":{} }`.

### 7.5 `statewright_load_workflow`

> Load a named workflow, resetting the state machine to the workflow's initial state.

```json
{
  "type": "object",
  "properties": {
    "name":       { "type": "string",  "description": "The workflow name to load (e.g., bugfix, etl-pipeline)" },
    "session_id": { "type": "string",  "description": "Client session identifier for per-session state isolation" },
    "project_id": { "type": "string",  "description": "Project identifier (cwd hash) for per-project run scoping" },
    "resume":     { "type": "boolean", "description": "Resume from the last paused run of this workflow instead of starting fresh" },
    "branch":     { "type": "string",  "description": "Connect to a specific fork branch session (for parallel sub-agents)" }
  },
  "required": ["name"]
}
```

### 7.6 `statewright_pause`

> Pause the current workflow. State and context are saved. Resume later with statewright_load_workflow(name, resume=true).

Input schema: `{ "type":"object", "properties":{} }`.

### 7.7 `statewright_deactivate`

> Deactivate workflow enforcement. All tools pass through without restriction.

Input schema: `{ "type":"object", "properties":{} }`.

### 7.8 `statewright_get_status`

> Get gateway status: active workflow, current state, available workflows.

Input schema: `{ "type":"object", "properties":{} }`.

### 7.9 `statewright_create_workflow`

> Create a new workflow from a JSON definition. Schema at https://statewright.ai/workflow-schema.json

```json
{
  "type": "object",
  "properties": {
    "name":       { "type": "string",  "description": "Workflow name (lowercase, hyphens, e.g. 'data-pipeline')" },
    "definition": { "type": "object",  "description": "Full workflow definition matching the schema at /workflow-schema.json" },
    "overwrite":  { "type": "boolean", "description": "If true, overwrite an existing workflow with the same name" }
  },
  "required": ["name", "definition"]
}
```

### 7.10 `statewright_run_agent`

> Run a state-machine-constrained agent to fix bugs or build features. Spawns the Rust agent executor and streams progress.

```json
{
  "type": "object",
  "properties": {
    "task":     { "type": "string", "description": "What to fix or build" },
    "model":    { "type": "string", "description": "Ollama model to use (default: gemma4:31b)" },
    "workflow": { "type": "string", "description": "State machine workflow name (default: bugfix-v2)" },
    "workdir":  { "type": "string", "description": "Working directory (default: current directory)" }
  },
  "required": ["task"]
}
```

### 7.11 `statewright_get_model_traits`

> Get model behavioral traits from the registry.

```json
{
  "type": "object",
  "properties": {
    "model": { "type": "string",
               "description": "Model tag (e.g., qwen3:8b, devstral-small-2:24b). If omitted, returns the full registry." }
  }
}
```

### 7.12 `statewright_force_state` (debug-only)

Only registered when `meta.debug == true`. Not present in the default `tools/list`.

```json
{
  "type": "object",
  "properties": {
    "state":   { "type": "string", "description": "Target state name to jump to" },
    "context": { "type": "object", "description": "Optional context to set (merged with existing context)" }
  },
  "required": ["state"]
}
```

### 7.13 Hidden adapter RPCs (not in `tools/list`)

Called by native host hooks (Claude Code, Codex, OMX, Pi, opencode, Cursor), never by the model:

- `statewright_adapter_pre_tool`
- `statewright_adapter_post_tool`
- `statewright_adapter_stop`
- `statewright_report_runtime_usage`

They apply the same gateway policy to built-in host tools that don't traverse MCP. Downstream Nix wiring can ignore them.

### 7.14 MCP wire types (from `protocol.rs`)

```rust
struct JsonRpcRequest  { jsonrpc: String, method: String, params: Option<Value>, id: Option<Value> }
struct JsonRpcResponse { jsonrpc: String, result: Option<Value>, error: Option<JsonRpcError>, id: Option<Value> }
struct JsonRpcError    { code: i32, message: String, data: Option<Value> }
struct ToolInfo        { name: String, description: Option<String>, input_schema: Value /* camelCase → inputSchema */ }
struct ToolCallParams  { name: String, arguments: Value }
struct ToolResultContent { type: String /* "text" */, text: String }
struct ToolCallResult    { content: Vec<ToolResultContent>, is_error: bool /* camelCase → isError */ }
```

---

## 8. CLI commands

### 8.1 `statewright-gateway` (MCP proxy)

Source: `crates/mcp-gateway/src/main.rs`.

```
statewright-gateway [OPTIONS]

  --config <PATH>            Gateway configuration file (JSON). Required for stdio/hook mode.
  --hook-server              Start the hook HTTP server for agent CLI plugins
  --hook-only                Run hook server only (no MCP stdio transport)
  --remote                   Run as remote MCP transport (HTTP+SSE). Cloud mode.
  --remote-addr <ADDR>       Listen address for remote transport (default: 0.0.0.0:3001)
  --pb-url <URL>             PocketBase URL for workflow loading in remote mode (default: http://localhost:8090)
  --hook-port-file <PATH>    Port file for the hook server (default: /tmp/statewright-hook-port)
```

`--config` file shape (`GatewayConfig`, from `config.rs`):

```json
{
  "default": "bugfix",
  "workflows": {
    "bugfix": { /* MachineDefinition */ },
    "etl":    { /* MachineDefinition */ }
  },
  "upstream_servers": [
    { "name": "filesystem",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"],
      "env": { "NODE_ENV": "production" } }
  ],
  "workdir": "/project",
  "api_key": "sw_…",                           /* optional, cloud mode */
  "cloud_url": "https://mcp.statewright.ai"    /* optional */
}
```

Environment variables read by the gateway:

- `DATABASE_URL` — remote-mode database (from `main.rs`).
- `RUST_LOG` — `tracing_subscriber::EnvFilter` (log level).

### 8.2 `sw-agent` (constrained agent)

Source: `crates/cli/src/main.rs`.

```
sw-agent [OPTIONS]

  -t, --task <STR>              Task description (default: buggy-calc demo prompt)
  -w, --workdir <PATH>          Working directory (default: crates/cli/fixtures/buggy-calc)
      --ollama-url <URL>        Ollama API URL (default: http://localhost:11434/v1)
      --model <NAME>            Model name (default: qwen2.5-coder:32b)
      --max-retries <N>         Max retries for state machine generation (default: 3)
      --max-steps <N>           Max total steps (default: 20)
      --use-hardcoded-machine   Skip state machine generation
      --hardcoded-machine <V>   Variant: legacy|v1|structured|v2 (default: legacy)
      --tool-mode <MODE>        native|raw|auto (default: auto)
      --tdd                     Run in TDD greenfield mode
      --tdd-greenfield          Use greenfield state machine
      --tdd-chain               Debug machine chaining
      --model-size <GB>         Model size for capability gating (default: 20.0)
      --max-cycles <N>          TDD cycles (default: 10)
      --control                 No guardrails
      --blind                   No run_test tool, work from issue text only
      --no-restore              Skip file restoration on exit
      --log                     Tee stdout to /tmp/statewright-<timestamp>.log
      --json-events             Output JSONL events to stdout (for gateway integration)
      --config <PATH>           Run-config JSON (model routing, guardrails, workflow)
      --state <NAME>            Execute a single state then exit
      --context-file <PATH>     Context JSON (recon results, previous tool output)
```

Env: `SW_HARDCODED_MACHINE` overrides `--hardcoded-machine`.

`--config` run-config shape (`RunConfig`):

```json
{
  "task": "…",
  "workdir": "/path",
  "workflow": { /* MachineDefinition */ },
  "model_routing": {
    "planning":     { "model": "…", "ollama_url": "…",
                      "num_ctx": 8192, "temperature": 0.3, "num_predict": 4096,
                      "skip": false, "programmatic": false }
  },
  "guardrails": {
    "max_diff_lines": 5,
    "max_steps": 20,
    "enable_localizer": true,
    "enable_minimizer": true,
    "enable_auto_test": true
  }
}
```

### 8.3 `statewright` (TUI)

Source: `crates/tui/src/main.rs`.

```
statewright [OPTIONS]

  -t, --task <STR>              Task description (default: "Fix the failing test")
  -w, --workdir <PATH>          Working directory (default: crates/cli/fixtures/buggy-calc)
      --ollama-url <URL>        Ollama URL (default: http://localhost:11434/v1)
      --model <NAME>            Model name (default: gemma4:31b)
      --tool-mode <MODE>        raw|native|auto (default: raw)
      --max-steps <N>           default: 25
      --control                 No guardrails
      --plain                   Plain text output (no TUI)
      --demo <MS>               Slow down for presentation
      --demo-menu               Interactive fixture chooser
```

Locates `sw-agent` next to itself, or falls back to `sw-agent` on `PATH`.

### 8.4 Missing / not-present in the source ⚠️

The task brief asked for `validate`, `approve`, `list instances`, `tail events`, `replay` sub-commands. **None of these exist as first-class CLI subcommands on `statewright-gateway`, `sw-agent`, or `statewright`.** Equivalent behaviour is:

| Requested | Actual mechanism |
|---|---|
| `validate` | Programmatic: `statewright_engine::validate_definition(&def)` — no CLI wrapper. `⚠️ UNVERIFIED` whether `sw-agent --use-hardcoded-machine` or a script exposes it. Author your own thin wrapper. |
| `approve` | MCP tool: send `statewright_transition` with the awaiting event to a session in `pending_approval`. No standalone CLI. |
| `list instances` | MCP tool: `statewright_list_workflows` / `statewright_get_status`. |
| `tail events` | `sw-agent --json-events` streams JSONL events on stdout (see §9). Also `--log` writes `/tmp/statewright-<ts>.log`. |
| `replay` | **No replay command found in-source.** `⚠️ UNVERIFIED`. |

Downstream tasks should not assume `statewright validate ...` etc. exist — call the engine or MCP tools directly, or write a shim in the Nix module.

---

## 9. Event-stream schema (`events.jsonl`)

Source: `crates/cli/src/events.rs :: TuiEvent`. Serialisation: `#[serde(tag = "event", rename_all = "snake_case")]` — each JSONL line has an `"event"` discriminator field.

`sw-agent --json-events` emits these lines to stdout. The TUI (`statewright`) parses them from its subprocess.

| `event` | Fields |
|---|---|
| `setup` | `files_snapshotted: u32` |
| `machine_loaded` | `states: [ { name, tools[], transitions[[event,target]], max_iterations, is_final } ]` |
| `step_started` | `step, state, iteration, max_iterations, tools[], is_checkpoint` |
| `localized` | `files[], test_failures, excerpt_lines` |
| `tool_call` | `name, args_preview` |
| `tool_result` | `name, result_preview` |
| `guard_blocked` | `tool, state` |
| `transition` | `from, to, trigger?, rationale?` |
| `auto_test` | `passed: bool, fail_count` |
| `diff_stats` | `file, changed, total` |
| `minimizer_rejected` | `file, changed, max` |
| `edit_gate_blocked` | *(no fields)* |
| `parse_fail` | `preview` |
| `llm_response` | `preview` |
| `nav_action` | `action` |
| `approval_gate` | `message` |
| `snapshot` | *(no fields)* |
| `completed` | `steps: u32, success: bool` |
| `agent_failed` | `error: string?` |
| `aborted` | `max_steps: u32` |

⚠️ **There is no explicit sequence-number or ISO-timestamp field on `TuiEvent`.** Sequencing is stdout line order. Timestamps: `⚠️ UNVERIFIED` — none in the enum; if needed, the consumer must clock lines on arrival.

`StateInfo` (nested under `machine_loaded`):

```rust
pub struct StateInfo {
    pub name: String,
    pub tools: Vec<String>,
    pub transitions: Vec<(String, String)>,   // (event, target)
    pub max_iterations: Option<u32>,
    pub is_final: bool,
}
```

---

## 10. Packaging & source-build

### 10.1 Upstream release artifacts

`gh release list statewright/statewright` at the time of writing:

| Tag | Assets |
|---|---|
| `gateway-v1.1.3` | `statewright-gateway_{darwin,linux}_{amd64,arm64}.zip` |
| `v1.1.0` | `statewright-gateway_{darwin,linux}_{amd64,arm64}.zip` |
| `v1` | `statewright-gateway_{darwin,linux}_{amd64,arm64}.zip` |
| `codex-v0.3.2` / `codex-v0.3.1` / `codex-v0.3.0-r1` | `statewright-codex-*.zip` (Codex plugin, JS) |
| `claude-v0.3.1` / `claude-v0.3.0-r1` | `statewright-claude-code-*.zip` (Claude Code plugin, JS) |

**Yes — upstream ships Linux x86_64 (`_linux_amd64.zip`) and arm64 gateway binaries.** No prebuilt `sw-agent` or `statewright` (TUI) artifacts — the release bundles are gateway-only. Building `sw-agent` / TUI requires cargo from source.

### 10.2 Source build

```bash
git clone https://github.com/statewright/statewright
cd statewright
cargo build --release --workspace
# binaries land in ./target/release/{statewright-gateway,sw-agent,statewright}
```

- Workspace `edition = "2024"` ⇒ needs **rustc ≥ 1.85** (`⚠️ UNVERIFIED` exact minimum — no `rust-toolchain.toml` pinned in-repo).
- Non-trivial deps: `axum 0.8` (gateway), `ratatui 0.30` + `crossterm 0.28` (TUI), `clap 4`, `tokio 1`.
- `crates/mcp-gateway/Cargo.toml` links `libc` on Unix (via stdout-tee in `sw-agent` — `crates/cli` uses `libc::pipe`). Any Nix `buildRustPackage` will need `pkgs.libcxx` on macOS, nothing extra on Linux.

### 10.3 `llm-agents.nix` status

Checked `github:numtide/llm-agents.nix/packages/` on 2026-09-11:

- **No `statewright` package.** Nearest neighbours: `codex`, `claude-code`, `swamp`, `cc-switch-cli`.
- The Nix packaging task in this OpenSpec change **cannot** just `inputs.llm-agents.packages.<system>.statewright` — it must build from source (nixpkgs `rustPlatform.buildRustPackage` against the workspace, or fetch the prebuilt gateway zip and repack).

### 10.4 Recommended packaging shape (guidance for task 2)

- **Gateway** → fetch release zip `statewright-gateway_linux_amd64.zip`, `unzip`, `install -Dm755 statewright-gateway $out/bin/`. Fast, matches upstream release cadence.
- **`sw-agent` + `statewright` TUI** → `rustPlatform.buildRustPackage` from source; `cargoLock.lockFile = ./Cargo.lock` (present in-repo). Set `buildAndTestSubdir` per crate or use `--workspace`. Native deps: `openssl` (via `axum`/`reqwest` transitively — `⚠️ UNVERIFIED`, confirm during build).

---

## 11. Bash-guardrail semantics (reference, from README)

Even when `Bash` is in `allowed_tools`, the gateway blocks:

- `echo … > file` and other write-via-redirect
- `rm -rf`, `sed -i`
- Scripting interpreters (`python`, `node`) invoked in a state that doesn't allow `Write`/`Edit`

`allowed_commands` is prefix-matched (README example uses `pytest`, `cargo test`, `npm test`; bugfix template uses the glob `"*test*"`). ⚠️ **Prefix vs glob semantics** are `⚠️ UNVERIFIED` from source alone — `bash_classifier.rs` (`crates/mcp-gateway/src/`) contains the actual matcher and should be inspected before any downstream author writes `allowed_commands` in production.

---

## 12. Convention crib-sheet (event / state names in-source)

Seen in `templates/*/config.json` and README examples — treat as convention, not schema:

- **Events**: `DONE`, `FAIL`, `READY`, `PLAN_READY`, `LOCALIZED`, `DIAGNOSED`, `ROOT_CAUSE_FOUND`, `FIX_PROPOSED`, `APPROVED`, `REJECTED`, `FIX_APPLIED`, `VERIFIED`, `VERIFICATION_FAILED`, `TESTS_PASS`, `TESTS_FAIL`, `FORK`, `BRANCH_DONE:<name>`, `$return` (interrupt resume).
- **State names**: `localizing`, `planning`, `implementing`, `testing`, `completed`, `failed`, `diagnose`, `investigate`, `propose_fix`, `approve_fix`, `execute_fix`, `verify`, `review`, `branch-done` (kebab OK).
- **Tool names** (upstream MCP catalog seen in templates): `Read`, `Grep`, `Glob`, `LS`, `Edit`, `Write`, `Bash`.

---

## 13. Confidence notes / open items for downstream tasks

- ✅ **Verified from source**: all `StateDef` / `TransitionDef` / `MachineMeta` / `GuardDef` / `InterruptDef` field lists, all MCP tool schemas, event stream discriminator names, gateway config shape, `sw-agent` CLI surface, release artifact list.
- ⚠️ `on_enter` / `on_exit` hooks: **not present** in `StateDef` — do not spec them.
- ⚠️ `schema_version` top-level key: **not present** — put in `meta.extra` if needed.
- ⚠️ Guard `guards: [...]` combinator semantics (AND vs OR) — inferred AND from code that concatenates both lists; confirm before authoring the JSON Schema.
- ⚠️ `model_ladder` inner element shape — declared `Vec<serde_json::Value>` in engine; check `direct_execution` handling in `crates/agent/` before writing docs.
- ⚠️ `allowed_commands` matcher — prefix vs glob; `crates/mcp-gateway/src/bash_classifier.rs` is authoritative.
- ⚠️ `validate` / `approve` / `list instances` / `tail events` / `replay` sub-commands — **do not exist as first-class CLI**; use MCP tools + `--json-events` streaming or wrap `statewright_engine::validate_definition` in a script.
- ⚠️ Minimum rustc — no `rust-toolchain` file; `edition = "2024"` requires ≥ 1.85 but upstream may test on newer.
- ⚠️ `llm-agents.nix` — **does not** ship a `statewright` package as of 2026-09-11; task 2 must package from source or repack the release zip.
- ⚠️ Event stream lacks a sequence number / timestamp field; ordering is stdout line order only.
- ⚠️ README `meta.approval_mode` and `meta.debug` are documented behavioural knobs but **not typed fields** on `MachineMeta`; they ride in `#[serde(flatten)] extra`.
