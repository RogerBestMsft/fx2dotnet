---
description: "Invoke an MCP tool with timeout, retry, and continuity-mode fallback handling"
tools:
  - "microsoft.githubcopilot.appmodernization.mcp/*"
  - "Swick.Mcp.Fx2dotnet/*"
---

# Invoke MCP Wrapper

Provide a consistent, resilient wrapper for MCP tool invocations used throughout the fx2dotnet extension suite. Handles timeouts, retry logic, and continuity mode selection based on the extension configuration.

## User Input

$ARGUMENTS

Required: `tool` (MCP tool name), `params` (tool parameters as structured input).  
Optional: `timeout_override` (seconds), `continuity_mode_override`.

## Configuration

Load from `.specify/extensions/fx2dotnet-support-core/fx2dotnet-support-core-config.yml`:

```yaml
mcp:
  timeout_seconds: 30       # Per-tool timeout
  retry_count: 2            # Retries before escalating to fallback
continuity:
  mode: normal              # normal | fallback-a | fallback-b | fallback-c | fallback-d
```

## Steps

### Step 1: Resolve Continuity Mode

Read the config file and determine the active continuity mode:

- `normal` — invoke external MCP tool directly.
- `fallback-a` — invoke internal-mirror equivalent of the same tool.
- `fallback-b` — invoke compatibility-fork replacement tool.
- `fallback-c` — invoke extension-native script/analyzer in place of the MCP tool.
- `fallback-d` — emit a manual continuation prompt and stop for user input.

If `continuity.emit_risk_banner: true` and mode is not `normal`, emit:

```
⚠ MCP CONTINUITY MODE: {mode}
  External MCP tool '{tool}' is being served by fallback source.
  Results may differ from primary source. Review outputs carefully.
```

### Step 2: Invoke Tool

For `normal` mode:
- Invoke the requested MCP tool with the provided parameters.
- Apply the configured timeout. If the tool does not respond within `timeout_seconds`, treat as a transient failure.

### Step 3: Retry on Failure

If the invocation fails (timeout, connection error, or non-fatal tool error):
1. Wait 2 seconds and retry.
2. Repeat up to `retry_count` times.
3. If all retries are exhausted, escalate to fallback mode (promote one level from `normal` → `fallback-a`).
4. Record the failure and current continuity mode in the calling command's log section.

### Step 4: Return Result

Return the tool's response to the calling command. If running in a fallback mode, annotate the response:

```
[CONTINUITY:{mode}] Response from {tool-or-fallback}:
{response}
```

### Step 5: On Fallback-D (Manual Mode)

If continuity mode is `fallback-d`:
1. Present the tool parameters to the user.
2. Ask the user to provide the expected output manually or confirm to skip this tool invocation.
3. Record the manual response in the calling command's state section.
