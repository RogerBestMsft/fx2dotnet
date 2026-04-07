# UnicodeEncodeError on Windows legacy console when listing extensions

## Description

`specify extension list` crashes with a `UnicodeEncodeError` when running on a Windows terminal that uses a non-UTF-8 code page (e.g., cp1252). The error occurs because the status icons `✓` (U+2713) and `✗` (U+2717) cannot be encoded by the legacy Windows console renderer in Rich.

## Steps to Reproduce

1. Open a standard Windows PowerShell or cmd terminal (not Windows Terminal with UTF-8 enabled)
2. Deploy any valid extension (e.g., `specify extension deploy ...`)
3. Run `specify extension list`

## Expected Behavior

The command lists installed extensions with their status icons and metadata.

## Actual Behavior

The command crashes with the following traceback:

```
UnicodeEncodeError: 'charmap' codec can't encode character '\u2713' in position 0: character maps to <undefined>
```

The error originates at `__init__.py:2784` inside `extension_list`:

```python
console.print(f"  [{status_color}]{status_icon}[/{status_color}] [bold]{ext[...")
```

Rich's `LegacyWindowsTerm` renderer calls `write_styled` → `write_text` → `write`, which goes through `cp1252.py:encode` and fails on the Unicode checkmark character.

**Full traceback path:**

```
__init__.py:2784 in extension_list
  → rich/console.py:1697 in print
  → rich/_win32_console.py:441 in write_styled
  → rich/_win32_console.py:402 in write_text
  → encodings/cp1252.py:19 in encode
```

## Root Cause

Lines 2781–2782 in `__init__.py` use Unicode symbols that are outside the cp1252 character set:

```python
status_icon = "✓" if ext["enabled"] else "✗"
```

When Rich detects a legacy Windows console (non-VT100), it uses `LegacyWindowsTerm` which writes through the system code page encoder, causing the crash.

## Proposed Fix

Replace the Unicode status icons with ASCII-safe alternatives when the platform or encoding doesn't support them. Two options:

### Option A: Use ASCII-safe characters unconditionally

```python
status_icon = "+" if ext["enabled"] else "x"
```

### Option B: Detect encoding and fall back gracefully

```python
import sys

def _safe_icon(enabled: bool) -> str:
    try:
        check = "✓" if enabled else "✗"
        check.encode(sys.stdout.encoding or "utf-8")
        return check
    except (UnicodeEncodeError, LookupError):
        return "+" if enabled else "x"

status_icon = _safe_icon(ext["enabled"])
```

### Option C: Use Rich markup instead of literal Unicode

Rich can render markup safely across backends. Instead of embedding literal Unicode characters, use Rich's built-in emoji or markup support:

```python
status_icon = ":heavy_check_mark:" if ext["enabled"] else ":cross_mark:"
```

## Workaround

Users can work around this by forcing UTF-8 output encoding before running the CLI:

```powershell
$env:PYTHONUTF8 = "1"
specify extension list
```

Or set it permanently:

```powershell
[Environment]::SetEnvironmentVariable("PYTHONUTF8", "1", "User")
```

## Environment

- **OS**: Windows 10/11
- **Terminal**: PowerShell 5.1 / cmd.exe (legacy console host)
- **Python**: 3.14.3 (via uv)
- **Console encoding**: cp1252
- **specify-cli version**: installed via `uv tool`
