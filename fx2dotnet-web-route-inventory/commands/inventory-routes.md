---
description: "Extract controller and convention routes from a legacy ASP.NET web host project"
---

# Inventory Routes

Extract route and endpoint inventory from a legacy ASP.NET web project by scanning controllers, routing configuration, and request/response contracts.

## Constraints

- Delegate all codebase searching and discovery to the `Explore` subagent. Do not perform searches directly.
- Build the inventory from code, not naming assumptions.

## User Input

$ARGUMENTS

Required: legacy web project path or containing folder.

## Steps

### Step 1: Locate Routing Files

Delegate to `Explore` (quick thoroughness) to locate:
- `WebApiConfig`
- `RouteConfig`
- `Global.asax`
- `Startup`
- Controller files within the provided project path

### Step 2: Determine Routing Style

From the `Explore` results, determine whether the host uses:
- Attribute routing
- Convention routing
- Both

### Step 3: Enumerate Controller Actions

Delegate to `Explore` (medium thoroughness) to enumerate:
- Controllers
- Action methods
- HTTP verb attributes
- Controller-level and action-level route attributes
- Auth attributes (`Authorize`, `AllowAnonymous`)
- Obvious request/response contract types

### Step 4: Combine Route Data

Combine controller-level and action-level route information into a route inventory.

### Step 5: Return Inventory

Return a structured inventory:

```markdown
## Route Inventory

### Controller: OrdersController
- Route Prefix: /api/orders
- Auth: [Authorize]

#### GET /api/orders/{id}
- Action: Get(int id)
- Response: OrderDto
```

Record unresolved route details explicitly instead of guessing.
