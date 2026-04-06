# Windows Service Migration Policy

Consumer copy of the canonical Windows Service migration policy.

- Replace `ServiceBase` with `BackgroundService`.
- Use `Microsoft.Extensions.Hosting.WindowsServices`.
- Do not add Linux hosting packages during this workflow.
