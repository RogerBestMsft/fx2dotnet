# Route Inventory Output

Expected output format for the fx2dotnet Web Route Inventory extension.

## Route Inventory

```markdown
## Route Inventory

### Controller: OrdersController
- Route Prefix: /api/orders
- Auth: [Authorize]

#### GET /api/orders/{id}
- Action: Get(int id)
- Response: OrderDto
```

## Handler Inventory

```markdown
## Handler Inventory

### /services/OrderService.asmx
- Methods:
  - GetOrder(int id) -> OrderDto
- Auth: SoapHeader(UserToken)
```

## Module Inventory

```markdown
## Module Inventory

### AuthModule
- Type: IHttpModule
- Registered In: web.config
- Purpose: Adds custom auth header validation
- Pipeline Stage: BeginRequest
```
