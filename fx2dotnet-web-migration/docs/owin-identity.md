# OWIN Identity Migration Policy

**Applies to**: `fx2dotnet-web-migration`  
**Trigger phrases**: "OWIN", "Katana", "Microsoft.Owin", "IAppBuilder", "Microsoft.AspNet.Identity"

## Policy

OWIN and ASP.NET Identity dependencies require an explicit user decision during web migration planning. Do not automatically replace them with ASP.NET Core Identity.

## Rules

1. Detect OWIN/Katana packages and startup patterns during route and host inventory.
2. Flag them as open migration decisions in `## Web Migration`.
3. Do not silently substitute ASP.NET Core Identity, cookie auth, or JwtBearer equivalents.
