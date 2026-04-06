# System.Web Adapters Usage

**Applies to**: `fx2dotnet-web-migration`, referenced by `fx2dotnet-multitarget`  
**Trigger phrases**: "System.Web", "HttpContext", "HttpRequest", "HttpResponse", "IHttpModule", "IHttpHandler", "HttpApplication", "SystemWebAdapters"

## Policy

When migration requires preserving `System.Web` APIs during the transition to ASP.NET Core, use `Microsoft.AspNetCore.SystemWebAdapters` to preserve behavior. Do not rewrite directly to native ASP.NET Core types during the multitarget phase.

## Rules

1. Replace `System.Web.dll` references with `Microsoft.AspNetCore.SystemWebAdapters` packages when required.
2. Preserve endpoint behavior and route semantics first; idiomatic ASP.NET Core rewrites are a later optimization.
3. Use side-by-side migration in the new ASP.NET Core host; keep the legacy host intact until parity is validated.
