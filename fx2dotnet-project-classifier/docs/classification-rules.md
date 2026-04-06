# Classification Rules

This document defines the rules used by the fx2dotnet Project Classifier to classify .NET projects.

## Classification Priority Order

Signals are evaluated in this priority order. The first match wins.

1. **Web Host** — strongest signal set required
2. **Windows Service** — explicit service framework signals
3. **Web Library** — web package refs without host artifacts
4. **Console** — Exe output type without web or service signals
5. **Library** — default when no other category matches

## Web Host Detection

A project is classified as a **web host** when it owns the web application entry point. It must have **at least one strong indicator**:

| Strong Indicators | Description |
|---|---|
| `Sdk="Microsoft.NET.Sdk.Web"` | SDK-style web host |
| `Microsoft.WebApplication.targets` import | Legacy ASP.NET web application |
| `OutputType=Exe` + OWIN `IAppBuilder` usage | Self-hosted OWIN app |

**Supporting indicators** (not sufficient alone):
- `Global.asax` file in project folder
- `web.config` file in project folder
- `RouteConfig`, `WebApiConfig`, `FilterConfig` classes
- `Startup.cs` with Web/OWIN bootstrapping

**Web Library** (shares web signals but is NOT a host):
- References `System.Web`, `Microsoft.AspNet.WebApi`, `Microsoft.AspNet.Mvc`, or OWIN packages
- OutputType is `Library`
- No strong host indicators detected

Web-library projects are SDK-conversion candidates (like any library). They are NOT classified as web hosts.

## Windows Service Detection

| Signal | Description |
|---|---|
| Subclass of `System.ServiceProcess.ServiceBase` | Native Windows Service |
| `ServiceInstaller` class present | Native Windows Service |
| `Topshelf.ServiceConfiguratorExtensions` or `TopShelf` package ref | TopShelf Windows Service |

A Windows Service project may also require SDK conversion. Both actions can coexist.

## SDK-Style Conversion Eligibility

| Project Type | Eligible? |
|---|---|
| Library, console, web-library | Yes — eligible for `convert_project_to_sdk_style` |
| Windows Service | Yes — eligible for conversion; service hosting is updated during multitarget phase |
| Web Host (ASP.NET Framework) | No — handled by web-migration phase, not SDK conversion |
| Already SDK-style | Not applicable |

## Uncertainty Handling

When signals conflict or are absent, classify as `uncertain` and:
1. List all detected signals.
2. List the conflicting interpretation.
3. Emit an `<!-- uncertainty: type -->` marker.
4. Do not assign `needs-sdk-conversion` to uncertain projects without user confirmation.
