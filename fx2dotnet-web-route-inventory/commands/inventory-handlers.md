---
description: "Inventory HTTP handlers and ASMX endpoints from a legacy ASP.NET web host"
---

# Inventory Handlers

Inventory legacy HTTP handlers, ASMX services, and thin ASPX endpoints that behave like HTTP endpoints.

## Constraints

- Delegate all searching and discovery to the `Explore` subagent.
- Include only pages that function as routes or thin handlers, not full UI pages.

## User Input

$ARGUMENTS

Required: legacy web project path or folder.

## Steps

### Step 1: Find Handlers and Services

Delegate to `Explore` to find:
- `.ashx` handlers
- `.asmx` files and their code-behind files
- `.aspx` pages that may function as HTTP endpoints

### Step 2: Extract ASMX Operations

For each `.asmx` service, extract:
- `[WebService]` class
- `[WebMethod]` operations
- Parameters
- Return types
- Any `[SoapHeader]` or auth requirements

### Step 3: Evaluate ASPX Pages

Include an `.aspx` page only if it acts like an endpoint or thin handler. Indicators:
- `IsPostBack` checks that dispatch to logic
- `Response.Write` / `Response.End` as primary output
- Few or no server controls
- Explicit route mapping in `Global.asax`

### Step 4: Return Inventory

Produce:

```markdown
## Handler Inventory

### /services/OrderService.asmx
- Methods:
  - GetOrder(int id) -> OrderDto
- Auth: SoapHeader(UserToken)

### /api/ping.aspx
- Methods: GET
- Parameters: none
- Output: plain text
```
