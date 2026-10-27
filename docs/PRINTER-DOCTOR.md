# Printer Doctor

Printer Doctor is a native PowerShell tool for the Atlas PC Support panel. It replaces the Streamlit prototype idea with a dependency-free Windows diagnostic flow that runs inside the existing launcher.

## Purpose

Use it when a customer reports printer problems and you need a quick, safe triage before promising a driver reinstall or Windows repair.

It checks:

- Installed printers and default printer.
- Printer ports, host/IP, protocol and drivers.
- Print Spooler service state.
- Current print jobs / stuck queue.
- Network ping to printer IP or hostname.
- Recent PrintService / Print Spooler warnings and errors.
- HTML/TXT report export for customer handoff.

## Safety model

Printer Doctor is read-only by default.

Repair actions are separated under **Repair actions** and require explicit confirmation:

- Restart Print Spooler.
- Clear jobs in one explicitly named queue.
- Open Windows printer settings.
- Print a test page.

Clearing queues and restarting Spooler can interrupt printing, so the tool asks the technician to type confirmation before making changes.

Query failures are reported as not evaluated, separately from successful empty
inventories. Event reads are capped per query; the report is not an exhaustive
history. Restarting Spooler can affect all printing, even though clearing jobs is
restricted to the selected queue.

## Integration

- Tool file: `src/tools/Invoke-PrinterDoctor.ps1`
- Manifest id: `printer-doctor`
- Category: `diagnostico`
- External dependencies: none
- Admin: not required for read-only checks, but some repair actions may require elevation.

## Validation

After changes, rebuild and validate:

```powershell
pwsh -NoLogo -NoProfile -File build.ps1
pwsh -NoLogo -NoProfile -File tests/Test-ToolSources.ps1
```

Also parse changed PowerShell files with:

```powershell
$tokens = $null
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile("src/tools/Invoke-PrinterDoctor.ps1", [ref]$tokens, [ref]$errors)
$errors
```
