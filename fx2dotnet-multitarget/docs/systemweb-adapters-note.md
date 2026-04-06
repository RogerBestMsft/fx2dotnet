# System.Web Adapters Note

Summary note for multitarget phase. Full policy lives with `fx2dotnet-web-migration`.

When `System.Web` types are encountered during multitarget:
- Use `Microsoft.AspNetCore.SystemWebAdapters`
- Do not rewrite to native ASP.NET Core types in this phase
- Preserve behavior first; rewrite later in explicit web migration work
