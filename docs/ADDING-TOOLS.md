# Añadir una nueva herramienta

Esta guía describe el registro y publicación; la aceptación requiere pruebas de
comportamiento y compatibilidad proporcionales al riesgo de la herramienta.

## 1. Crear el archivo de la herramienta

En `src/tools/`, crea un archivo llamado `Invoke-MiTool.ps1` (prefijo `Invoke-` obligatorio):

```powershell
# ============================================================
# Invoke-MiTool
# Descripción breve de qué hace
# Atlas PC Support — v1.0
# ============================================================

function Invoke-MiTool {
    [CmdletBinding()]
    param()

    # Tu lógica aquí. Puedes usar cualquier cmdlet PowerShell.
    # El Host.UI.RawUI ya tiene título asignado por el launcher.

    Clear-Host
    Write-Host "=== Mi Tool ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Hola desde mi herramienta"
    Write-Host ""
    Read-Host "Presiona Enter para cerrar"
}
```

### Reglas importantes

- ✅ **Nombre del archivo** debe empezar con `Invoke-`.
- ✅ **Nombre de la función** debe coincidir con el archivo.
- ✅ **Todo el código** dentro de la función.
- ❌ **NO incluir auto-elevación** (el launcher lo maneja vía `requiresAdmin` en `tools.json`).
- ❌ **NO usar `exit 0`** — usa `return` (o deja que la función termine naturalmente).
- ❌ **NO usar `#Requires`** — está en el launcher principal.

## 2. Registrar la herramienta en el manifiesto

Edita `config/tools.json` y añade una entrada:

```json
{
  "id": "mi-tool",
  "name": "Mi Tool",
  "description": "Descripción corta que aparece en la tarjeta (máximo ~150 caracteres).",
  "nameEs": "Mi herramienta",
  "descriptionEs": "Descripción en español con alcance y limitaciones.",
  "category": "mantenimiento",
  "function": "Invoke-MiTool",
  "source": "Invoke-MiTool.ps1",
  "requiresAdmin": false,
  "runsInNewWindow": true,
  "runtime": {"engine":"windows-powershell","minimumVersion":"5.1","architecture":"x64","libraries":["ToolKit","Dependencies","PS7","Release","Reports"]},
  "availability": {"minimumBuild":19044,"commands":[]},
  "dependencies": []
}
```

### Campos

| Campo | Valores | Descripción |
|---|---|---|
| `id` | kebab-case | ID único (sin espacios, en minúsculas). |
| `name` | string | Nombre visible en la tarjeta. |
| `description` | string | Descripción corta (1-2 líneas). |
| `nameEs` / `descriptionEs` | string | Tarjeta en español; búsqueda admite ambos idiomas. |
| `category` | `diagnostico`, `mantenimiento`, `copia`, `redes`, `seguridad`, `software`, `entrega` | Determina pestaña e ícono. |
| `function` | string | Nombre exacto de la función PowerShell a invocar. |
| `source` | string | Archivo obligatorio; su nombre debe coincidir con `function`. |
| `requiresAdmin` | bool | Si `true`, el launcher eleva al ejecutar. |
| `runsInNewWindow` | bool | Debe ser true: proceso hijo verificado. Ejecución inline no admitida. |
| `runtime` | objeto | Motor, versión mínima, arquitectura y bibliotecas; no hay fallback silencioso a otro motor. |
| `availability` | objeto | Build mínimo, comandos y `disabledReason` cuando no está disponible. Se vuelve a comprobar en el hijo. |
| `dependencies` | array | Lista de dependencias externas (`"FastCopy"`, `"winget"`, etc.). |

### Añadir una nueva categoría

Edita `branding.example.json` y `src/lib/Branding.ps1`:

```json
"categories": [
  { "id": "diagnostico", "label": "Diagnóstico", "icon": "🔍", "order": 1 },
  { "id": "nueva-cat",   "label": "Nueva",       "icon": "⭐", "order": 8 }
]
```

## 3. Compilar el launcher

```powershell
pwsh -NoProfile -File build.ps1
pwsh -NoProfile -File tests/Update-ToolDocumentation.ps1
```

Esto regenera bootstrap, launcher, sidecar, hashes y manifiesto del release.

## 4. Probar localmente

### Modo desarrollo (sin compilar)

```powershell
pwsh -NoProfile -ExecutionPolicy RemoteSigned -File src\Launcher.ps1
```

Ventaja: puedes modificar el código y re-ejecutar sin recompilar.

### Modo producción (usa `launcher.ps1` compilado)

```powershell
irm https://toolspanel.atlaspcsupport.com | iex
```

## 5. Commit y push

```bash
git add src/tools/Invoke-MiTool.ps1 config/tools.json config/tool-hashes.json get.ps1 launcher.ps1 launcher.ps1.sha256 release-manifest.json docs/INVENTARIO.md
git commit -m "feat: añadir herramienta MiTool"
git push
```

CI rechaza artefactos desactualizados y publica el conjunto como artefacto de pruebas;
no escribe un commit automático. Promover el SHA probado según [RELEASES.md](RELEASES.md).

## Gestionar dependencias externas

Si tu tool usa un binario externo (p. ej. `CrystalDiskInfo.exe`):

1. Registra la dependencia en `config/dependencies.json`, con versión o canal,
   arquitectura, política de firma/hash, licencia y rutas. Ejemplo de campos:
   ```json
   "CrystalDiskInfo": {
     "DisplayName": "CrystalDiskInfo",
     "ExecutableName": "DiskInfo64.exe",
     "WingetId": "CrystalDewWorld.CrystalDiskInfo",
     "Architecture": "x64",
     "VersionSource": "winget/source-managed",
     "SignaturePolicy": "package-manager",
     "License": "Revisar términos del proveedor antes de redistribuir",
     "SearchPaths": ["C:\\Program Files\\CrystalDiskInfo\\DiskInfo64.exe"]
   }
   ```

2. Declara la dependencia en `config/tools.json`:
   ```json
   "dependencies": ["CrystalDiskInfo"]
   ```

3. Dentro de tu tool, resuelve la ruta:
   ```powershell
   $exe = Resolve-AtlasDependency -Name 'CrystalDiskInfo' -InstallIfMissing
   if (-not $exe) {
       Write-Host "No se encontró CrystalDiskInfo." -ForegroundColor Red
       return
   }
   # Resolver no ejecuta la herramienta. Contrastar CLI con versión y proveedor.
   # CrystalDiskInfo necesita CdiResource; no hay aquí un contrato universal /Json.
   Write-Host "Ejecutable observado: $exe"
   ```

Los candidatos locales/offline adicionales se pasan mediante
`-AdditionalSearchPaths`; los nombres alternativos de PATH, mediante
`-CommandNames`. Usar el mismo resolver para todos ellos, sin aceptar archivos
por otra ruta después de un fallo de instalación. Resolver una ruta no certifica
licencia, compatibilidad ni la versión instalada. Ejecutar aplicaciones con
recursos desde su directorio; no copiar solamente su EXE.

## Convenciones de código

- **Encoding de fuentes**: UTF-8/LF. El build añade BOM al launcher de archivo y al wrapper 5.1; no modifica los scripts verificados.
- **Comentarios**: en español, breves.
- **Funciones helper**: ponlas DENTRO de la función `Invoke-XXX`, no en el scope global, para no contaminar el launcher.
- **Variables globales**: evítalas. Si necesitas state compartido, usa `$script:`.
- **Errores**: captúralos con `try/catch` y escribe a log con `Write-AtlasLog`.
- **Informes compartidos**: usar `Write-AtlasShareableReport`; no redactar backups que deben restaurar estado. Revisión humana del texto libre antes de compartir.
- **No uses** `exit`, `$Host.SetShouldExit()`, ni mates procesos del host.
- **Procesos verbosos**: el ejecutor conserva colas de 64 Ki caracteres por canal.
  Revisa StdoutTruncated/StderrTruncated y usa OutputLogPath nuevo para salida
  completa explícita. Ese log puede contener datos sensibles. No interpretar una
  cola truncada como documento JSON/CSV completo. Estado nativo y timeout se conservan.
