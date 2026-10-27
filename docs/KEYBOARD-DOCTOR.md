# Keyboard Doctor

Keyboard Doctor is a native PowerShell tool for the Atlas PC Support panel. It adapts the standalone ghost-typing diagnostic into a safer panel workflow with no external dependencies.

## Purpose

Use it when a customer reports:

- Ghost typing / keys pressing themselves.
- Repeated characters.
- Keyboard works intermittently.
- Suspected touchpad or swollen-battery pressure causing phantom input.

The goal is a practical technician verdict: **APTO**, **OBSERVATION**, or **KEYBOARD/HARDWARE RISK** before promising that maintenance, cleaning, driver work, or Windows reinstall will fix the issue.

## Checks

Read-only quick diagnosis checks:

- Keyboard devices visible to Windows.
- Touchpad / HID pointing devices.
- Filter Keys, Sticky Keys and Toggle Keys registry flags.
- Battery presence, charge and wear when Windows exposes battery WMI data.
- Recent System events related to keyboard, HID, PnP, I2C, touchpad and driver frameworks.

Guided manual checks:

- BIOS/UEFI observation.
- External keyboard isolation.
- Touchpad / palm rejection isolation.

Optional monitor:

- Foreground-only hands-off key monitor.
- Requires explicit `CONSENT`.
- Stores only an aggregate event count, focused-window scope and timestamp; no key names, codes or text content.
- Warns the technician not to type passwords.

## Safety model

Keyboard Doctor is read-only by default.

Repair actions are separated under **Repair actions** and require explicit confirmation:

- Open keyboard accessibility settings for review of the intended user's preferences; Atlas does not overwrite their flags with fixed values.
- Open Device Manager.
- Open Windows keyboard accessibility settings.

The tool does **not** disable Defender, does **not** run a background keylogger, and does **not** disable keyboard/touchpad devices automatically.

## Offline USB

`Build Offline USB` installs the complete verified release. Preparing or updating
an offline USB includes Keyboard Doctor and its shared libraries.

To refresh an existing USB:

1. Open the panel from a PC with internet.
2. Run **Build Offline USB**.
3. Select the same USB.
4. Choose update/overwrite when prompted.

## Integration

- Tool file: `src/tools/Invoke-KeyboardDoctor.ps1`
- Manifest id: `keyboard-doctor`
- Category: `diagnostico`
- External dependencies: none
- Admin: not required for read-only checks. Some event/device details may be richer when the panel is elevated.

## Validation

After changes, rebuild and validate:

```powershell
pwsh -NoLogo -NoProfile -File build.ps1
pwsh -NoLogo -NoProfile -File tests/Test-ToolSources.ps1
```

Also parse the changed tool directly:

```powershell
$tokens = $null
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile("src/tools/Invoke-KeyboardDoctor.ps1", [ref]$tokens, [ref]$errors)
$errors
```
