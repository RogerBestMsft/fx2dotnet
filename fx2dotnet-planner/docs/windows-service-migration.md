# Windows Service Migration Policy

**Applies to**: `fx2dotnet-project-classifier`, `fx2dotnet-planner`, `fx2dotnet-multitarget`  
**Trigger phrases**: "Windows Service", "ServiceBase", "ServiceController", "ServiceInstaller", "TopShelf", "windows-service"

## Policy: Migrate to BackgroundService

Windows Service projects must migrate from `System.ServiceProcess.ServiceBase` to `BackgroundService` from `Microsoft.Extensions.Hosting`, with Windows service hosting provided by `Microsoft.Extensions.Hosting.WindowsServices`.

Both packages support .NET Framework 4.6.2+, making this migration safe during the multitarget phase.

## Rules

1. **Classify Windows Service projects with both actions**: `needs-sdk-conversion` (if legacy format) AND `windows-service`.
2. **Do not change service logic during SDK conversion** — SDK conversion only normalizes the project file format.
3. **Apply the `BackgroundService` migration during the multitarget phase**, not during SDK conversion.
4. **Do not add `Microsoft.Extensions.Hosting.Systemd`** or any Linux-specific hosting package. Cross-platform adaptation is a post-migration activity.
5. **Do not remove `-windows` TFM suffixes** from `TargetFrameworks` when multitargeting Windows Service projects.

## Migration Pattern

Replace:

```csharp
// Before: System.ServiceProcess.ServiceBase
public class MyService : ServiceBase
{
    protected override void OnStart(string[] args) { /* ... */ }
    protected override void OnStop() { /* ... */ }
}
```

With:

```csharp
// After: Microsoft.Extensions.Hosting.BackgroundService
public class MyService : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            // service work
            await Task.Delay(1000, stoppingToken);
        }
    }
}
```

And update `Program.cs` to use:

```csharp
IHost host = Host.CreateDefaultBuilder(args)
    .UseWindowsService()  // from Microsoft.Extensions.Hosting.WindowsServices
    .ConfigureServices(services => services.AddHostedService<MyService>())
    .Build();

await host.RunAsync();
```

## Required Packages

| Package | Version | Notes |
|---|---|---|
| `Microsoft.Extensions.Hosting` | ≥ 6.0.0 | Supports .NET Framework 4.6.2+ |
| `Microsoft.Extensions.Hosting.WindowsServices` | ≥ 6.0.0 | Supports .NET Framework 4.6.2+ |
