---
description: "Inventory HTTP modules and request-pipeline behaviors from a legacy ASP.NET web host"
---

# Inventory Modules

Inventory HTTP modules and other request pipeline behaviors that may affect endpoint behavior in a legacy ASP.NET web application.

## Constraints

- Delegate all discovery to the `Explore` subagent.
- Focus only on modules and filters that materially affect request behavior.

## User Input

$ARGUMENTS

Required: legacy web project path or folder.

## Steps

### Step 1: Find Module Registrations

Delegate to `Explore` to locate:
- `web.config` module registrations
- `IHttpModule` implementations
- Custom request pipeline filters

### Step 2: Extract Behaviors

For each module/filter, capture:
- Name
- Registration path/location
- Purpose (auth, logging, rewriting, headers, etc.)
- Request stages affected

### Step 3: Return Inventory

Produce:

```markdown
## Module Inventory

### AuthModule
- Type: IHttpModule
- Registered In: web.config
- Purpose: Adds custom auth header validation
- Pipeline Stage: BeginRequest
```
