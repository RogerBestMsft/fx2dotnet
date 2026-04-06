# Windows Service Migration Policy

Consumer copy of the canonical Windows Service migration policy.

- Detect `ServiceBase`, `ServiceInstaller`, and `TopShelf` signals.
- Classify projects with `windows-service` action.
- The actual hosting migration occurs during multitarget work.
