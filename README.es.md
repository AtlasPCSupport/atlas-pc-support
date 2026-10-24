# Atlas PC Support

> Panel unificado de herramientas de soporte técnico para Windows, estilo WinUtil.

**🌐 Idioma: [English](README.md) | Español**

![License](https://img.shields.io/badge/license-MIT-green)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6)
[![Buy me a coffee](https://img.shields.io/badge/PayPal-Buy%20me%20a%20coffee-ffdd00?logo=paypal&logoColor=white)](https://www.paypal.me/atlaspcsupport)

Atlas PC Support es un launcher WPF (tema Fluent / Windows 11) que agrupa herramientas de diagnóstico, mantenimiento, redes, seguridad y entrega para técnicos que dan soporte a equipos Windows. Inspirado en [WinUtil de Chris Titus](https://github.com/ChrisTitusTech/winutil).

---

## 🚀 Instalación rápida (una sola línea)

Abre **Windows PowerShell 5.1** y pega. Eleva permisos cuando la operación lo requiera:

```powershell
irm https://toolspanel.atlaspcsupport.com | iex
```

El bootstrap HTTPS descarga y verifica un release completo aprobado antes de iniciar el launcher con `-File`. Cloudflare fija su commit inmutable y el digest del manifiesto. Defender/AMSI permanecen activos; no se añaden exclusiones ni cambios permanentes de política.

Reabrir el comando selecciona la última **publicación aprobada**. Una sesión abierta conserva sus herramientas verificadas. Consulta [publicación, uso offline y rollback](docs/RELEASES.md).

---

## 🖼 Captura

![Panel Atlas PC Support](docs/img/panel-screenshot.png)

Sobre la rejilla de herramientas hay un dashboard en vivo (CPU / RAM / Disco + alertas) y un panel lateral con los datos del equipo (hostname, usuario, build de Windows, modelo de CPU, RAM total, uptime, IP local) siempre visible.

---

## 📦 Inventario vigente

El manifiesto conserva **27 entradas**. El deduplicador está marcado como no disponible; algunas acciones de reparación quedan restringidas con un motivo visible.

Consulta el [inventario generado por herramienta y dependencia](docs/INVENTARIO.md), la [matriz y restricciones](docs/SUPPORT-MATRIX.md) y el [cierre del plan con QA pendiente](docs/audits/CIERRE-PLAN-2026-10-24.md). CI comprueba que el inventario coincida con el manifiesto.

El monitor y la información del sistema se consultan bajo demanda en un proceso de PowerShell en segundo plano dentro de la aplicación. Los informes compartidos aplican redacción de datos sensibles reconocibles y trazabilidad. Revisa el texto libre antes de compartirlo; los respaldos explícitos de recuperación BitLocker contienen secretos y deben guardarse aparte.

---

## 🌍 Idiomas

La interfaz del panel incluye cadenas para estos idiomas; las herramientas tienen cobertura variable. Las tarjetas están en español e inglés y la búsqueda admite ambos idiomas sin distinguir acentos:

**Inglés (default), Español, Portugués, Francés, Alemán, Italiano, Rumano.**

Puedes elegir el idioma desde el desplegable y reiniciar el panel para aplicarlo. Para forzar uno específico, edita `branding.json`:

```json
{ "language": "es" }
```

Valores válidos: `"auto"`, `"en"`, `"es"`, `"pt"`, `"fr"`, `"de"`, `"it"`, `"ro"`. Detalles y cómo añadir más en [docs/LANGUAGES.md](docs/LANGUAGES.md).

---

## 🎨 Personalizar la marca (branding)

El panel acepta **un archivo `branding.json`** con tu propia marca: nombre, logo, colores, tagline, copyright, etc. Ideal si revendes o configuras el panel para un cliente específico.

Copia `branding.example.json` a `branding.json` y edítalo:

```json
{
  "brand": {
    "name": "TU EMPRESA DE SOPORTE",
    "tagline": "Soporte técnico para pymes",
    "companyUrl": "https://miempresa.com",
    "copyright": "© 2026 Mi Empresa"
  },
  "theme": {
    "accentColor": "#0078D4",
    "darkMode": false,
    "cornerRadius": 4
  },
  "window": {
    "title": "Panel Mi Empresa v1.0"
  }
}
```

Rutas donde el launcher busca `branding.json` (en orden):

1. `branding.json` junto al `launcher.ps1` (repo local).
2. `%LOCALAPPDATA%\AtlasPC\branding.json` (perfil del usuario).
3. `%APPDATA%\AtlasPC\branding.json`.

Si no existe, se usa el branding Atlas por defecto.

📘 Detalles completos en [docs/BRANDING.md](docs/BRANDING.md).

### Dominio corto propio

Si tienes tu propio dominio, puedes servir el launcher como `tools.tudominio.com` con Cloudflare Workers (gratis, ~10 min de setup). Instrucciones paso a paso en [docs/CLOUDFLARE-DOMAIN.md](docs/CLOUDFLARE-DOMAIN.md).

---

## 🧑‍💻 Desarrollo local

```powershell
git clone https://github.com/AtlasPCSupport/atlas-pc-support
cd atlas-pc-support

# Modo desarrollo (usa src/, sin compilar):
pwsh -NoProfile -ExecutionPolicy RemoteSigned -File src\Launcher.ps1

# O compilar el launcher distribuible:
pwsh -NoProfile -File build.ps1
# Esto regenera launcher.ps1 (raíz del repo) con todo embebido,
# además de get.ps1, launcher.ps1.sha256, config/tool-hashes.json y release-manifest.json.
```

### Estructura del repo

```
atlas-pc-support/
├── launcher.ps1              ← Entrada compilada, adquirida dentro del release verificado.
├── launcher.ps1.sha256       ← Sidecar SHA-256 usado por get.ps1.
├── build.ps1                 ← Regenera launcher.ps1 desde src/.
├── branding.example.json     ← Plantilla de branding personalizado.
├── README.md / README.es.md  ← Docs en inglés / español.
├── LICENSE / .gitignore
├── config/
│   ├── tools.json            ← Manifiesto de herramientas (ver "Añadir tool").
│   └── tool-hashes.json      ← SHA-256 esperado para cada Invoke-*.ps1.
├── docs/                     ← Guías + capturas.
├── src/
│   ├── Launcher.ps1          ← Entry point de desarrollo.
│   ├── lib/                  ← Helpers (Branding, Admin, Logging, Dependencies, ToolRunner, PS7).
│   ├── gui/                  ← XAML + código de la GUI WPF.
│   └── tools/                ← Una herramienta por archivo (`Invoke-XXX.ps1`).
└── .github/workflows/        ← CI que rebuildea launcher.ps1 en cada push.
```

### Añadir una nueva herramienta

1. Crea `src/tools/Invoke-MiTool.ps1`:
   ```powershell
   function Invoke-MiTool {
       [CmdletBinding()] param()
       Write-Host "Hola desde MiTool"
       Read-Host "Presiona ENTER para salir"
   }
   ```
2. Regístrala en `config/tools.json`:
   ```json
   {
     "id": "mi-tool",
     "name": "Mi Tool",
     "description": "Descripción corta (máx. ~150 caracteres).",
     "category": "mantenimiento",
      "function": "Invoke-MiTool",
      "source": "Invoke-MiTool.ps1",
      "requiresAdmin": false,
     "runsInNewWindow": true,
     "runtime": {"engine":"windows-powershell","minimumVersion":"5.1","architecture":"x64","libraries":["ToolKit","Dependencies","PS7","Release"]},
     "dependencies": []
   }
   ```
3. Ejecuta `pwsh -File build.ps1` y `pwsh -File tests/Update-ToolDocumentation.ps1`.
4. Commitear todos los generados y hacer push. CI rechaza releases desactualizados o incompletos. Tras pasar los checks, promover el commit probado con [el procedimiento de publicación](docs/RELEASES.md).

Ver [docs/ADDING-TOOLS.md](docs/ADDING-TOOLS.md) para la referencia completa.

---

## 📋 Logs y dependencias

- **Logs**: `%LOCALAPPDATA%\AtlasPC\logs\atlas-YYYY-MM-DD.log`.
- **Binarios externos** (FastCopy.exe, etc.): se descargan bajo demanda a `%LOCALAPPDATA%\AtlasPC\bin\`.
- **Releases versionados**: `%LOCALAPPDATA%\AtlasPC\releases\<commit>\`; `current.json` y `previous.json` seleccionan conjuntos verificados.
- **Datos de clientes / reportes**: se guardan en `%USERPROFILE%\Documents\AtlasPC\` y NUNCA se suben al repo.

---

## 🛡 Requisitos

- Cliente Windows x64 build 19044+; objetivos Windows 10 22H2 Home/Pro y LTSC 2021. QA de esas VMs sigue pendiente.
- Windows PowerShell 5.1 es el runtime predeterminado por herramienta. PowerShell 7 no implica homologación universal.
- Administrador solo para operaciones que lo requieren. Store y App Installer dependen del usuario y las políticas.

---

## 📄 Licencia

[MIT](LICENSE). Puedes usarlo, modificarlo y redistribuirlo libremente, incluso comercialmente. Solo mantén el aviso de copyright. Esta licencia no cubre binarios de terceros; revisa derechos laborales y de redistribución de FastCopy, HWiNFO y cada proveedor.

---

## 🙋 Soporte

Si eres técnico profesional y quieres:

- **Versión personalizada con tu marca** (logo, colores, herramientas específicas de tu empresa).
- **Soporte premium por email**.
- **Bundle pre-configurado** para empresas de 10+ PCs.

Visita [atlaspcsupport.com](https://atlaspcsupport.com) o abre un issue.

---

## 🙏 Agradecimientos

- [Chris Titus Tech · WinUtil](https://github.com/ChrisTitusTech/winutil) — inspiración y arquitectura.
- [ModernWpfUI](https://github.com/Kinnara/ModernWpf) — referencia de estilos Fluent.
- La comunidad de PowerShell.
