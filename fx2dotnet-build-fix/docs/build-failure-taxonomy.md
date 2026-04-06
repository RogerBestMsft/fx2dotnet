# Build Failure Taxonomy

Classification of build errors encountered during .NET Framework → modern .NET migration, with recommended fix strategies.

## Error Group Types

### missing-using

**Error codes**: CS0246, CS0234  
**Symptom**: Type or namespace not found.  
**Cause**: New TFM removed a namespace import that was auto-included in .NET Framework, or a `using` directive was dropped.  
**Fix**: Add the correct `using System.{Namespace}` directive to the affected file.  
**Domain policy**: If the missing type is from `System.Web`, apply the System.Web Adapters policy before adding any `using`.

### ambiguous-reference

**Error code**: CS0104  
**Symptom**: Ambiguous between two namespaces.  
**Cause**: Two packages expose the same type name into scope.  
**Fix**: Use a fully-qualified type name or add a `using Alias = Specific.Namespace.Type` alias.

### missing-package

**Error code**: CS0246 (with package context)  
**Symptom**: Type from a NuGet package not found after conversion.  
**Cause**: Package not yet added or not restored.  
**Fix**: Ask the user before adding any new NuGet package. Do not add packages silently.

### api-not-found

**Error codes**: CS1061, CS0103, CS1501  
**Symptom**: Member or method does not exist on the type.  
**Cause**: API was removed or renamed in the target framework.  
**Fix**: Find the replacement API via search, or wrap with `#if NET48 / #else / #endif` if needed for multitarget compatibility.

### type-mismatch

**Error codes**: CS0029, CS0266  
**Symptom**: Cannot implicitly convert types.  
**Cause**: Covariance changes, nullable reference changes, or changed return types.  
**Fix**: Add explicit cast at the specific call site. Do not change the underlying type unless necessary.

### nullable-warning (promoted to error)

**Error codes**: CS8600–CS8622 range  
**Symptom**: Nullable reference warning promoted to error.  
**Cause**: Nullable reference types enabled (default in modern .NET).  
**Fix**: Add null check at the specific site or use null-forgiving operator `!` only when the null state is proven safe.

### ef6-related

**Symptom**: Error involves `System.Data.Entity` types.  
**Policy**: Apply EF6 policy. Do not touch EF6 code unless it is the direct cause of a compile error from a different missing dependency. Do not replace with EF Core.

### systemweb-related

**Symptom**: Error involves `System.Web` types (HttpContext, HttpRequest, etc.).  
**Policy**: Apply System.Web Adapters policy. Add `Microsoft.AspNetCore.SystemWebAdapters` package (with user approval). Do NOT rewrite to native ASP.NET Core types.

### service-related

**Symptom**: Error involves `System.ServiceProcess` types (ServiceBase, ServiceController).  
**Policy**: Apply Windows Service policy. Migrate to `BackgroundService` + `Microsoft.Extensions.Hosting.WindowsServices`.

### other

All remaining errors that do not fit the above categories. Report the full error details and ask the user how to proceed.

## Escalation Rules

1. Apply up to `config.build_fix.max_retries_per_group` attempts per error group.
2. If a group is not resolved within the retry limit, mark it `blocked-max-retries` and surface a blocker summary.
3. Never attempt to fix the same error more than the configured limit without user input.
4. Never add a NuGet package dependency without explicit user approval — regardless of retry count.
